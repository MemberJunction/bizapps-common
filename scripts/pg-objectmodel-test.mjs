// Comprehensive functional test of the BizApps Common object model on PostgreSQL.
//
// Exercises the WRITE path (CodeGen-generated CRUD functions), the READ path (FK-join base
// views), the polymorphic links (Person/Organization), relationships, the distinctive model
// features (Person.DisplayName STORED generated column, the Organization root-parent recursive
// TVF, the Person.LinkedUserID unique constraint), and full CRUD round-trips. Self-cleaning.
//
// Run (PG stack up on postgres-claude:5433/BizApps_PG_Test):
//   node scripts/pg-objectmodel-test.mjs
import { Pool } from 'pg';

const S = '__mj_bizappscommon';
const ENT_PERSON = '7a94ada9-7880-4fae-97d8-db0e934c3f5f';
const ENT_ORG = 'c70448f9-9792-41d7-a82c-784b66429d54';
const pool = new Pool({ host: 'localhost', port: 5433, user: 'mj_admin', password: 'Claude2Pg99', database: 'BizApps_PG_Test' });
const q = (sql, p) => pool.query(sql, p);

let pass = 0, fail = 0;
const ok = (n) => { pass++; console.log(`  ✓ ${n}`); };
const bad = (n, d) => { fail++; console.log(`  ✗ ${n} — ${d}`); };
const check = (n, cond, d) => (cond ? ok(n) : bad(n, d));
const created = []; // {table, id} in reverse-dependency order for cleanup

async function createRow(table, fn, args) {
  const id = (await q(`SELECT "ID" FROM ${S}."${fn}"(${Object.keys(args).map((_, i) => `${pgKey(args, i)} := $${i + 1}`).join(', ')})`, Object.values(args))).rows[0].ID;
  created.unshift({ table, id });
  return id;
}
const pgKey = (args, i) => Object.keys(args)[i];

async function main() {
  const sysUser = (await q(`SELECT "ID" FROM __mj."User" LIMIT 1`)).rows[0].ID;

  console.log('\n[1] Type lookups (seeded reference data)');
  for (const [t, min] of [['AddressType', 6], ['ContactType', 8], ['OrganizationType', 8], ['RelationshipType', 14]]) {
    const n = +(await q(`SELECT count(*) c FROM ${S}."${t}"`)).rows[0].c;
    check(`${t} seeded (>=${min})`, n >= min, `got ${n}`);
  }

  console.log('\n[2] Organization (hierarchy + root-parent TVF)');
  const orgType = (await q(`SELECT "ID" FROM ${S}."OrganizationType" LIMIT 1`)).rows[0].ID;
  const parent = await createRow('Organization', 'spCreateOrganization', { p_name: 'TEST Holdings', p_legalname: 'TEST Holdings LLC', p_organizationtypeid: orgType });
  const child = await createRow('Organization', 'spCreateOrganization', { p_name: 'TEST West', p_parentid: parent });
  ok('spCreateOrganization (parent + child w/ ParentID FK + OrganizationType FK)');
  const orgRows = (await q(`SELECT "ID","RootParentID","Parent","OrganizationType","LegalName" FROM ${S}."vwOrganizations" WHERE "ID" IN ($1,$2)`, [parent, child])).rows;
  const childRow = orgRows.find(o => o.ID === child);
  check('vwOrganizations FK-join (Parent/OrganizationType)', !!childRow.Parent, JSON.stringify(childRow));
  check('Organization root-parent recursive TVF (child.RootParentID = parent)', childRow.RootParentID === parent, `got ${childRow.RootParentID}`);
  check('Organization.LegalName persisted', orgRows.find(o => o.ID === parent).LegalName === 'TEST Holdings LLC');

  console.log('\n[3] Person (DisplayName generated column)');
  const p1 = await createRow('Person', 'spCreatePerson', { p_firstname: 'Jane', p_lastname: 'Doe', p_middlename: 'Q' });
  const p2 = await createRow('Person', 'spCreatePerson', { p_firstname: 'John', p_lastname: 'Smith' });
  const jane = (await q(`SELECT "DisplayName","MiddleName" FROM ${S}."vwPeople" WHERE "ID"=$1`, [p1])).rows[0];
  check('Person.DisplayName STORED generated column', jane.DisplayName === 'Jane Doe', `got "${jane.DisplayName}"`);
  check('Person.MiddleName persisted', jane.MiddleName === 'Q');

  console.log('\n[4] Address + polymorphic AddressLink (Person AND Organization)');
  const addr = await createRow('Address', 'spCreateAddress', { p_line1: '1 Test St', p_city: 'Example', p_stateprovince: 'XX', p_postalcode: '00000' });
  const addrType = (await q(`SELECT "ID" FROM ${S}."AddressType" LIMIT 1`)).rows[0].ID;
  const linkP = await createRow('AddressLink', 'spCreateAddressLink', { p_addressid: addr, p_entityid: ENT_PERSON, p_recordid: p1, p_addresstypeid: addrType, p_isprimary: true });
  const linkO = await createRow('AddressLink', 'spCreateAddressLink', { p_addressid: addr, p_entityid: ENT_ORG, p_recordid: parent, p_addresstypeid: addrType, p_isprimary: false });
  const links = (await q(`SELECT "ID","Address","Entity","AddressType" FROM ${S}."vwAddressLinks" WHERE "ID" IN ($1,$2)`, [linkP, linkO])).rows;
  check('AddressLink polymorphic (Person + Organization) + vwAddressLinks FK-joins', links.length === 2 && links.every(l => l.Address && l.Entity && l.AddressType), JSON.stringify(links));

  console.log('\n[5] ContactMethod (polymorphic Person AND Organization)');
  const ct = (await q(`SELECT "ID" FROM ${S}."ContactType" LIMIT 1`)).rows[0].ID;
  const cmP = await createRow('ContactMethod', 'spCreateContactMethod', { p_personid: p1, p_contacttypeid: ct, p_value: 'jane@example.com' });
  const cmO = await createRow('ContactMethod', 'spCreateContactMethod', { p_organizationid: parent, p_contacttypeid: ct, p_value: 'info@example.com' });
  const cms = (await q(`SELECT "ID","Person","Organization","ContactType" FROM ${S}."vwContactMethods" WHERE "ID" IN ($1,$2)`, [cmP, cmO])).rows;
  check('ContactMethod polymorphic (Person row has Person, Org row has Organization)',
    cms.find(c => c.ID === cmP)?.Person && cms.find(c => c.ID === cmO)?.Organization, JSON.stringify(cms));

  console.log('\n[6] Relationship (directional, typed From/To)');
  const relType = (await q(`SELECT "ID" FROM ${S}."RelationshipType" LIMIT 1`)).rows[0].ID;
  const relPP = await createRow('Relationship', 'spCreateRelationship', { p_relationshiptypeid: relType, p_frompersonid: p1, p_topersonid: p2 });
  const relPO = await createRow('Relationship', 'spCreateRelationship', { p_relationshiptypeid: relType, p_frompersonid: p1, p_toorganizationid: parent });
  const rels = (await q(`SELECT "ID","RelationshipType","FromPerson","ToPerson","ToOrganization" FROM ${S}."vwRelationships" WHERE "ID" IN ($1,$2)`, [relPP, relPO])).rows;
  check('Relationship Person->Person + Person->Org + vwRelationships FK-joins',
    rels.find(r => r.ID === relPP)?.ToPerson && rels.find(r => r.ID === relPO)?.ToOrganization && rels.every(r => r.RelationshipType), JSON.stringify(rels));

  console.log('\n[7] Person.LinkedUserID unique constraint (1:1 Person<->User)');
  await q(`UPDATE ${S}."Person" SET "LinkedUserID"=$1 WHERE "ID"=$2`, [sysUser, p1]);
  ok('link Person 1 -> User');
  try {
    await q(`UPDATE ${S}."Person" SET "LinkedUserID"=$1 WHERE "ID"=$2`, [sysUser, p2]);
    bad('UQ_Person_LinkedUserID rejects a 2nd Person linked to the same User', 'second link was allowed');
  } catch (e) {
    check('UQ_Person_LinkedUserID rejects a 2nd Person linked to the same User', /unique|duplicate/i.test(e.message), e.message);
  }
  await q(`UPDATE ${S}."Person" SET "LinkedUserID"=NULL WHERE "ID"=$1`, [p1]); // release for cleanup

  console.log('\n[8] UPDATE / DELETE round-trips');
  await q(`SELECT ${S}."spUpdatePerson"(p_id := $1, p_firstname := $2, p_lastname := $3)`, [p1, 'Janet', 'Doe']);
  const upd = (await q(`SELECT "DisplayName" FROM ${S}."vwPeople" WHERE "ID"=$1`, [p1])).rows[0];
  check('spUpdatePerson recomputes generated DisplayName', upd.DisplayName === 'Janet Doe', `got "${upd.DisplayName}"`);
  // delete the second relationship and confirm it's gone (delete-path smoke)
  await q(`SELECT ${S}."spDeleteRelationship"(p_id := $1)`, [relPO]);
  const gone = +(await q(`SELECT count(*) c FROM ${S}."Relationship" WHERE "ID"=$1`, [relPO])).rows[0].c;
  check('spDeleteRelationship removes the row', gone === 0);
  created.splice(created.findIndex(c => c.id === relPO), 1); // already deleted
}

main()
  .catch((e) => { fail++; console.log(`  ✗ EXCEPTION — ${e.message}`); })
  .finally(async () => {
    for (const { table, id } of created) await q(`DELETE FROM ${S}."${table}" WHERE "ID"=$1`, [id]).catch(() => {});
    console.log(`\nRESULT: ${pass} passed, ${fail} failed.  (test rows cleaned up: ${created.length})`);
    await pool.end();
    process.exit(fail ? 1 : 0);
  });
