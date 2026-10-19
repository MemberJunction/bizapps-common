/**
 * The consent migration's shape is a contract with the code: the three status values the CHECKs
 * allow (CodeGen turns them into the `ConsentStatus` union), the purpose lookup, one consent per
 * method, purpose and organization, the cascades that let a contact method take its consents and
 * their history with it, the channel link on ContactType, and the index the latest-row read uses.
 * Read from the file so a rename or a dropped constraint fails here before a host runs it.
 */
import { readdirSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { CONTACT_CONSENT_STATUSES } from '../contact-consent.js';

const MIGRATIONS_DIR = fileURLToPath(new URL('../../../../migrations/', import.meta.url));
const file = readdirSync(MIGRATIONS_DIR).filter((f) => /__Contact_Method_Consent\.sql$/.test(f)).sort().pop();
if (!file) throw new Error('No Contact_Method_Consent migration found');
const sql = readFileSync(MIGRATIONS_DIR + file, 'utf8');
// Only the hand-written part is under test; the appended CodeGen block is MJ's output, not ours.
const handWritten = sql.split('CODEGEN OUTPUT')[0];
const flat = handWritten.replace(/\s+/g, ' ');

const statusList = CONTACT_CONSENT_STATUSES.map((s) => `N'${s}'`).join(', ');

describe('the contact consent migration', () => {
    it('creates ConsentPurpose as a lookup with a unique name, like ContactType', () => {
        expect(flat).toContain('CREATE TABLE [${flyway:defaultSchema}].[ConsentPurpose]');
        expect(flat).toContain('CONSTRAINT UQ_ConsentPurpose_Name UNIQUE (Name)');
        expect(flat).toContain('IsActive BIT NOT NULL DEFAULT 1');
    });

    it('creates ContactConsent with one row per method, purpose and organization, and the CHECK the code mirrors', () => {
        expect(flat).toContain('CREATE TABLE [${flyway:defaultSchema}].[ContactConsent]');
        expect(flat).toContain("ConsentStatus NVARCHAR(20) NOT NULL DEFAULT N'NotSpecified'");
        expect(flat).toContain(`CONSTRAINT CK_ContactConsent_ConsentStatus CHECK (ConsentStatus IN (${statusList}))`);
        expect(flat).toContain('UNIQUE (ContactMethodID, ConsentPurposeID, OrganizationID)');
        expect(flat).toContain('OrganizationID UNIQUEIDENTIFIER NULL');
        expect(flat).toMatch(
            /FK_ContactConsent_ContactMethod FOREIGN KEY \(ContactMethodID\) REFERENCES \[\$\{flyway:defaultSchema\}\]\.\[ContactMethod\]\(ID\) ON DELETE CASCADE/,
        );
    });

    it('does not put a consent status on ContactMethod itself: consents are rows, not a column', () => {
        expect(flat).not.toMatch(/\[ContactMethod\]\s+ADD ConsentStatus/);
    });

    it('creates ContactConsentHistory with the same status list and a cascade from its consent', () => {
        expect(flat).toContain('CREATE TABLE [${flyway:defaultSchema}].[ContactConsentHistory]');
        expect(flat).toContain(`CHECK (NewConsentStatus IN (${statusList}))`);
        expect(flat).toMatch(
            /FK_ContactConsentHistory_ContactConsent FOREIGN KEY \(ContactConsentID\) REFERENCES \[\$\{flyway:defaultSchema\}\]\.\[ContactConsent\]\(ID\) ON DELETE CASCADE/,
        );
        expect(flat).toContain('ConsentStatusAt DATETIMEOFFSET NOT NULL');
        expect(flat).toContain('ConsentSource NVARCHAR(200) NOT NULL');
        expect(flat).toContain('RecordedByUserID UNIQUEIDENTIFIER NULL');
    });

    it('records who entered a change against the MJ core User table, through the core-schema placeholder', () => {
        expect(flat).toContain('FK_ContactConsentHistory_RecordedByUser FOREIGN KEY (RecordedByUserID) REFERENCES [${mjSchema}].[User](ID)');
    });

    it('links ContactType to the core Communication Base Message Type, so channel is a key and not a name match', () => {
        expect(flat).toContain('ADD CommunicationBaseMessageTypeID UNIQUEIDENTIFIER NULL');
        expect(flat).toContain('REFERENCES [${mjSchema}].[CommunicationBaseMessageType](ID)');
    });

    it('indexes the latest-change read: consent, then ConsentStatusAt descending', () => {
        expect(flat).toContain('ON [${flyway:defaultSchema}].[ContactConsentHistory] (ContactConsentID, ConsentStatusAt DESC)');
    });

    it('is idempotent: every DDL statement is guarded and no __mj_ audit columns are hand-written', () => {
        expect(flat).toContain("IF OBJECT_ID(N'[${flyway:defaultSchema}].[ConsentPurpose]', N'U') IS NULL");
        expect(flat).toContain("IF OBJECT_ID(N'[${flyway:defaultSchema}].[ContactConsent]', N'U') IS NULL");
        expect(flat).toContain("IF OBJECT_ID(N'[${flyway:defaultSchema}].[ContactConsentHistory]', N'U') IS NULL");
        expect(flat).not.toMatch(/__mj_(Created|Updated)At\]? DATETIMEOFFSET/);
    });
});
