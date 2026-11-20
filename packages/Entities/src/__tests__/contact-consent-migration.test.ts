/**
 * The consent migration's shape is a contract with the code: the three readable status values the
 * CHECKs allow (CodeGen turns them into the `ConsentStatus` union), the constrained source list
 * and its Staff default, the purpose lookup ordered by Sequence, one consent per contact method,
 * purpose and requesting organization, the cascades that let a contact method take its consents and
 * their history with it, the channel link on ContactType, and the index the latest-row read uses.
 * Read from the file so a rename or a dropped constraint fails here before a host runs it.
 */
import { readdirSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { ContactMethodConsentEntity } from '../contact-method-consent-entity.js';

const MIGRATIONS_DIR = fileURLToPath(new URL('../../../../migrations/', import.meta.url));
const file = readdirSync(MIGRATIONS_DIR).filter((f) => /__Contact_Method_Consent\.sql$/.test(f)).sort().pop();
if (!file) throw new Error('No Contact_Method_Consent migration found');
const sql = readFileSync(MIGRATIONS_DIR + file, 'utf8');
// Only the hand-written part is under test; the appended CodeGen block is MJ's output, not ours.
const handWritten = sql.split('CODEGEN OUTPUT')[0];
const flat = handWritten.replace(/\s+/g, ' ');

const statusList = ContactMethodConsentEntity.Statuses.map((s) => `N'${s}'`).join(', ');

describe('the contact method consent migration', () => {
    it('creates ConsentPurpose as a lookup with a unique name, ordered by Sequence like MJ lookups', () => {
        expect(flat).toContain('CREATE TABLE [${flyway:defaultSchema}].[ConsentPurpose]');
        expect(flat).toContain('CONSTRAINT UQ_ConsentPurpose_Name UNIQUE (Name)');
        expect(flat).toContain('Sequence INT NOT NULL DEFAULT 0');
        expect(flat).not.toContain('DisplayRank');
        expect(flat).toContain('IsActive BIT NOT NULL DEFAULT 1');
    });

    it('creates ContactMethodConsent: one row per method, optional purpose and optional requesting organization', () => {
        expect(flat).toContain('CREATE TABLE [${flyway:defaultSchema}].[ContactMethodConsent]');
        expect(flat).toContain("ConsentStatus NVARCHAR(20) NOT NULL DEFAULT N'Not Specified'");
        expect(flat).toContain(`CONSTRAINT CK_ContactMethodConsent_ConsentStatus CHECK (ConsentStatus IN (${statusList}))`);
        expect(flat).toContain('UNIQUE (ContactMethodID, ConsentPurposeID, RequestingOrganizationID)');
        expect(flat).toContain('ConsentPurposeID UNIQUEIDENTIFIER NULL');
        expect(flat).toContain('RequestingOrganizationID UNIQUEIDENTIFIER NULL');
        expect(flat).toMatch(
            /FK_ContactMethodConsent_ContactMethod FOREIGN KEY \(ContactMethodID\) REFERENCES \[\$\{flyway:defaultSchema\}\]\.\[ContactMethod\]\(ID\) ON DELETE CASCADE/,
        );
    });

    it('describes RequestingOrganizationID as the organization asking, not the owner of the address', () => {
        expect(flat).toContain("@level2name = N'RequestingOrganizationID'");
        expect(flat).toContain('This is not the owner of the contact method');
    });

    it('does not put a consent status on ContactMethod itself: consents are rows, not a column', () => {
        expect(flat).not.toMatch(/\[ContactMethod\]\s+ADD ConsentStatus/);
    });

    it('creates ContactMethodConsentHistory with the same status list and a cascade from its consent', () => {
        expect(flat).toContain('CREATE TABLE [${flyway:defaultSchema}].[ContactMethodConsentHistory]');
        expect(flat).toContain(`CHECK (NewConsentStatus IN (${statusList}))`);
        expect(flat).toMatch(
            /FK_ContactMethodConsentHistory_ContactMethodConsent FOREIGN KEY \(ContactMethodConsentID\) REFERENCES \[\$\{flyway:defaultSchema\}\]\.\[ContactMethodConsent\]\(ID\) ON DELETE CASCADE/,
        );
        expect(flat).toContain('ConsentStatusAt DATETIMEOFFSET NOT NULL');
        expect(flat).toContain('RecordedByUserID UNIQUEIDENTIFIER NULL');
    });

    it('constrains the source to a short list with Staff as the default, and keeps specifics in ConsentDetails', () => {
        expect(flat).toContain("ConsentSource NVARCHAR(50) NOT NULL DEFAULT N'Staff'");
        expect(flat).toContain("CHECK (ConsentSource IN (N'Web Form', N'Unsubscribe Link', N'Import', N'Staff', N'Other'))");
        expect(flat).toContain('ConsentDetails NVARCHAR(MAX) NULL');
        expect(flat).not.toMatch(/\bNotes NVARCHAR/);
    });

    it('records who entered a change against the MJ core User table, through the core-schema placeholder', () => {
        expect(flat).toContain(
            'FK_ContactMethodConsentHistory_RecordedByUser FOREIGN KEY (RecordedByUserID) REFERENCES [${mjSchema}].[User](ID)',
        );
    });

    it('links ContactType to the core Communication Base Message Type, so channel is a key and not a name match', () => {
        expect(flat).toContain('ADD CommunicationBaseMessageTypeID UNIQUEIDENTIFIER NULL');
        expect(flat).toContain('REFERENCES [${mjSchema}].[CommunicationBaseMessageType](ID)');
    });

    it('indexes the latest-change read: consent, then ConsentStatusAt descending', () => {
        expect(flat).toContain('ON [${flyway:defaultSchema}].[ContactMethodConsentHistory] (ContactMethodConsentID, ConsentStatusAt DESC)');
    });

    it('is plain DDL: Skyway runs it once, so no existence guards, and no __mj_ audit columns are hand-written', () => {
        expect(flat).not.toMatch(/\bIF (OBJECT_ID|COL_LENGTH)\(/);
        expect(flat).not.toMatch(/\bIF NOT EXISTS\b/);
        expect(flat).not.toMatch(/__mj_(Created|Updated)At\]? DATETIMEOFFSET/);
    });
});
