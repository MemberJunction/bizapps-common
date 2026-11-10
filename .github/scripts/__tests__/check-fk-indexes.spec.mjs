import { test } from 'node:test';
import assert from 'node:assert/strict';
import { expectedFkIndexName, scanMigrationFkIndexes } from '../check-fk-indexes.mjs';

test('expectedFkIndexName builds IDX_AUTO_MJ_FKEY_{Table}_{Column} and truncates at 128 chars', () => {
    assert.equal(
        expectedFkIndexName('ActivityFile', 'ActivityID'),
        'IDX_AUTO_MJ_FKEY_ActivityFile_ActivityID',
    );
    const longTable = 'A'.repeat(100);
    const longCol = 'B'.repeat(50);
    const name = expectedFkIndexName(longTable, longCol);
    assert.equal(name.length, 128);
    assert.ok(name.startsWith('IDX_AUTO_MJ_FKEY_'));
});

test('scanMigrationFkIndexes detects missing FK indexes in CREATE TABLE and ALTER TABLE', () => {
    const migrations = [
        {
            file: 'V202601010001__tables.sql',
            sql: `
                CREATE TABLE [\${flyway:defaultSchema}].[ActivityFile] (
                    ID UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
                    ActivityID UNIQUEIDENTIFIER NOT NULL,
                    FileID UNIQUEIDENTIFIER NOT NULL,
                    CONSTRAINT FK_ActivityFile_Activity FOREIGN KEY (ActivityID)
                        REFERENCES [\${flyway:defaultSchema}].[Activity](ID),
                    CONSTRAINT FK_ActivityFile_File FOREIGN KEY (FileID)
                        REFERENCES [\${mjSchema}].[File](ID)
                );
                ALTER TABLE [\${flyway:defaultSchema}].[Person]
                    ADD CONSTRAINT FK_Person_SeniorityLevel FOREIGN KEY (SeniorityLevelID)
                        REFERENCES [\${flyway:defaultSchema}].[SeniorityLevel](ID);
                CREATE NONCLUSTERED INDEX IDX_AUTO_MJ_FKEY_ActivityFile_ActivityID
                    ON [\${flyway:defaultSchema}].[ActivityFile] ([ActivityID]);
            `,
        },
    ];

    const { foreignKeys, missing } = scanMigrationFkIndexes(migrations);
    assert.equal(foreignKeys.size, 3);
    assert.deepEqual(
        missing.map((m) => `${m.table}.${m.column} -> ${m.expectedIndex}`),
        [
            'ActivityFile.FileID -> IDX_AUTO_MJ_FKEY_ActivityFile_FileID',
            'Person.SeniorityLevelID -> IDX_AUTO_MJ_FKEY_Person_SeniorityLevelID',
        ],
    );
});

test('scanMigrationFkIndexes passes when a later migration supplies the missing index', () => {
    const migrations = [
        {
            file: 'V202601010001__tables.sql',
            sql: `
                CREATE TABLE [\${flyway:defaultSchema}].[PersonJobFunction] (
                    ID UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
                    PersonID UNIQUEIDENTIFIER NOT NULL,
                    JobFunctionID UNIQUEIDENTIFIER NOT NULL,
                    CONSTRAINT FK_PJF_Person FOREIGN KEY (PersonID) REFERENCES [\${flyway:defaultSchema}].[Person](ID),
                    CONSTRAINT FK_PJF_JF FOREIGN KEY (JobFunctionID) REFERENCES [\${flyway:defaultSchema}].[JobFunction](ID)
                );
            `,
        },
        {
            file: 'V202601010002__fk_indexes.sql',
            sql: `
                CREATE NONCLUSTERED INDEX IDX_AUTO_MJ_FKEY_PersonJobFunction_PersonID
                    ON [\${flyway:defaultSchema}].[PersonJobFunction] ([PersonID]);
                CREATE NONCLUSTERED INDEX IDX_AUTO_MJ_FKEY_PersonJobFunction_JobFunctionID
                    ON [\${flyway:defaultSchema}].[PersonJobFunction] ([JobFunctionID]);
            `,
        },
    ];

    const { missing } = scanMigrationFkIndexes(migrations);
    assert.deepEqual(missing, []);
});

test('scanMigrationFkIndexes ignores FOREIGN KEY text inside comments and string literals', () => {
    const migrations = [
        {
            file: 'V202601010001__comments.sql',
            sql: `
                -- ALTER TABLE [\${flyway:defaultSchema}].[Fake] ADD CONSTRAINT FK_Fake FOREIGN KEY (FakeID) REFERENCES [\${flyway:defaultSchema}].[Other](ID);
                /* CREATE TABLE [\${flyway:defaultSchema}].[Fake2] (
                    FakeID UNIQUEIDENTIFIER,
                    CONSTRAINT FK_Fake2 FOREIGN KEY (FakeID) REFERENCES [\${flyway:defaultSchema}].[Other](ID)
                ); */
                SELECT N'ALTER TABLE [\${flyway:defaultSchema}].[Fake3] ADD CONSTRAINT FK_Fake3 FOREIGN KEY (FakeID) REFERENCES [\${flyway:defaultSchema}].[Other](ID)';
            `,
        },
    ];

    const { foreignKeys, missing } = scanMigrationFkIndexes(migrations);
    assert.equal(foreignKeys.size, 0);
    assert.equal(missing.length, 0);
});
