/**
 * The consent migration's shape is a contract with the code: the three status values the CHECKs
 * allow (CodeGen turns them into the `ConsentStatus` union), the cascade that lets a contact method
 * take its history with it, the channel link on ContactType, and the index the latest-row read
 * uses. Read from the file so a rename or a dropped constraint fails here before a host runs it.
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

describe('the contact method consent migration', () => {
    it('adds ConsentStatus to ContactMethod, defaulting to NotSpecified, with the CHECK the code mirrors', () => {
        expect(flat).toContain("ADD ConsentStatus NVARCHAR(20) NOT NULL DEFAULT N'NotSpecified'");
        expect(flat).toContain(`CONSTRAINT CK_ContactMethod_ConsentStatus CHECK (ConsentStatus IN (${statusList}))`);
    });

    it('creates ContactConsentHistory with the same status list and a cascade from its contact method', () => {
        expect(flat).toContain('CREATE TABLE [${flyway:defaultSchema}].[ContactConsentHistory]');
        expect(flat).toContain(`CHECK (NewConsentStatus IN (${statusList}))`);
        expect(flat).toMatch(
            /FK_ContactConsentHistory_ContactMethod FOREIGN KEY \(ContactMethodID\) REFERENCES \[\$\{flyway:defaultSchema\}\]\.\[ContactMethod\]\(ID\) ON DELETE CASCADE/,
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

    it('indexes the latest-change read: contact method, then ConsentStatusAt descending', () => {
        expect(flat).toContain('ON [${flyway:defaultSchema}].[ContactConsentHistory] (ContactMethodID, ConsentStatusAt DESC)');
    });

    it('is idempotent: every DDL statement is guarded and no __mj_ audit columns are hand-written', () => {
        expect(flat).toContain("IF COL_LENGTH(N'[${flyway:defaultSchema}].[ContactMethod]', N'ConsentStatus') IS NULL");
        expect(flat).toContain("IF OBJECT_ID(N'[${flyway:defaultSchema}].[ContactConsentHistory]', N'U') IS NULL");
        expect(flat).not.toMatch(/__mj_(Created|Updated)At\]? DATETIMEOFFSET/);
    });
});
