// Functional smoke test of the BizApps Common object model on PostgreSQL.
// Exercises the WRITE path (CodeGen-generated CRUD functions), the READ path (FK-join base views),
// and the distinctive model features: Person.DisplayName STORED generated column + the
// Organization root-parent recursive table-valued function. Self-cleaning (deletes its test rows).
//
// Run:  DB on postgres-claude:5433/BizApps_PG_Test  →  node scripts/pg-objectmodel-smoke.mjs
import { Pool } from 'pg';
const S = '__mj_bizappscommon';
const pool = new Pool({ host: 'localhost', port: 5433, user: 'mj_admin', password: 'Claude2Pg99', database: 'BizApps_PG_Test' });
const q = (sql, p) => pool.query(sql, p);
const ids = {};
let pass = 0, fail = 0;
const check = (name, cond, detail) => { (cond ? (pass++, console.log(`  ✓ ${name}`)) : (fail++, console.log(`  ✗ ${name} — ${detail}`))); };

try {
  // entity id for the People entity (AddressLink.EntityID is a polymorphic ref into __mj.Entity)
  const peopleEntity = (await q(`SELECT "ID" FROM __mj."Entity" WHERE "SchemaName"=$1 AND "BaseTable"=$2`, [S, 'Person'])).rows[0]?.ID;

  console.log('\n[WRITE] CodeGen CRUD functions');
  ids.parent = (await q(`SELECT "ID" FROM ${S}."spCreateOrganization"(p_name := $1)`, ['SMOKE Acme Holdings'])).rows[0].ID;
  check('spCreateOrganization (parent)', !!ids.parent);
  ids.child = (await q(`SELECT "ID" FROM ${S}."spCreateOrganization"(p_name := $1, p_parentid := $2)`, ['SMOKE Acme West', ids.parent])).rows[0].ID;
  check('spCreateOrganization (child w/ ParentID FK)', !!ids.child);
  ids.person = (await q(`SELECT "ID" FROM ${S}."spCreatePerson"(p_firstname := $1, p_lastname := $2)`, ['Jane', 'Doe'])).rows[0].ID;
  check('spCreatePerson', !!ids.person);
  ids.addr = (await q(`SELECT "ID" FROM ${S}."spCreateAddress"(p_line1 := $1, p_city := $2)`, ['1 Test St', 'Example'])).rows[0].ID;
  check('spCreateAddress', !!ids.addr);
  const addrType = (await q(`SELECT "ID" FROM ${S}."AddressType" LIMIT 1`)).rows[0].ID;
  ids.link = (await q(`SELECT "ID" FROM ${S}."spCreateAddressLink"(p_addressid := $1, p_entityid := $2, p_recordid := $3, p_addresstypeid := $4, p_isprimary := $5)`,
    [ids.addr, peopleEntity, ids.person, addrType, true])).rows[0].ID;
  check('spCreateAddressLink (polymorphic FK Person→Address)', !!ids.link);
  const ctType = (await q(`SELECT "ID" FROM ${S}."ContactType" LIMIT 1`)).rows[0].ID;
  ids.cm = (await q(`SELECT "ID" FROM ${S}."spCreateContactMethod"(p_personid := $1, p_contacttypeid := $2, p_value := $3)`,
    [ids.person, ctType, 'jane@example.com'])).rows[0].ID;
  check('spCreateContactMethod', !!ids.cm);

  console.log('\n[READ] FK-join base views + model features');
  const person = (await q(`SELECT * FROM ${S}."vwPeople" WHERE "ID"=$1`, [ids.person])).rows[0];
  check('Person.DisplayName STORED generated column', person?.DisplayName === 'Jane Doe', `got "${person?.DisplayName}"`);
  const orgs = (await q(`SELECT "ID","RootParentID","Parent" FROM ${S}."vwOrganizations" WHERE "ID" IN ($1,$2)`, [ids.parent, ids.child])).rows;
  const child = orgs.find(o => o.ID === ids.child);
  check('vwOrganizations.Parent FK-join column', !!child?.Parent, `got "${child?.Parent}"`);
  check('Organization root-parent TVF (child.RootParentID = parent)', child?.RootParentID === ids.parent, `got "${child?.RootParentID}" expected "${ids.parent}"`);
  const link = (await q(`SELECT "Address","Entity","AddressType" FROM ${S}."vwAddressLinks" WHERE "ID"=$1`, [ids.link])).rows[0];
  check('vwAddressLinks FK-join columns (Address/Entity/AddressType)', !!link?.Address && !!link?.Entity && !!link?.AddressType, JSON.stringify(link));
  const cm = (await q(`SELECT "Person","ContactType" FROM ${S}."vwContactMethods" WHERE "ID"=$1`, [ids.cm])).rows[0];
  check('vwContactMethods FK-join columns (Person/ContactType)', !!cm?.Person && !!cm?.ContactType, JSON.stringify(cm));

  console.log('\n[UPDATE/DELETE] round-trip');
  await q(`SELECT ${S}."spUpdatePerson"(p_id := $1, p_firstname := $2, p_lastname := $3)`, [ids.person, 'Janet', 'Doe']);
  const upd = (await q(`SELECT "DisplayName" FROM ${S}."vwPeople" WHERE "ID"=$1`, [ids.person])).rows[0];
  check('spUpdatePerson recomputes generated DisplayName', upd?.DisplayName === 'Janet Doe', `got "${upd?.DisplayName}"`);
} catch (e) {
  fail++; console.log(`  ✗ EXCEPTION — ${e.message}`);
} finally {
  // cleanup (children first)
  for (const [t, id] of [['ContactMethod', ids.cm], ['AddressLink', ids.link], ['Address', ids.addr], ['Person', ids.person], ['Organization', ids.child], ['Organization', ids.parent]]) {
    if (id) await q(`DELETE FROM ${S}."${t}" WHERE "ID"=$1`, [id]).catch(() => {});
  }
  console.log(`\nRESULT: ${pass} passed, ${fail} failed. (test rows cleaned up)`);
  await pool.end();
  process.exit(fail ? 1 : 0);
}
