# Contact consent: per contact method, with history

Agreed in design review, October 2026. This file records the decision; the code lands with it on
`feat/contact-method-consent`.

## The split

Consent is split across three layers, each doing one job:

- **Comms (MJ core) enforces** it at send time. It owns the send pipeline and the channels (the
  Email, Phone and SMS message types already exist in core). It stores no consent, because it does not
  own people or their contact details. The Comms redesign adds a consent hook: before each send,
  Comms asks a registered consent provider whether the recipient may be contacted on that channel,
  skips those who may not, and logs why.
- **BizApps Common stores** it where the contact details already live. Contact methods are 1:M per
  person or organization, so consent is recorded per email or phone, never per person. Every app on
  Common gets it.
- **An app that already has its own opt-in flags** keeps them until Common's part lands, then moves
  them onto its people's contact methods (see "Apps with existing flags" below).

The layers depend downward. Comms never needs to know Common's tables, because Common plugs into
Comms' hook, not the other way round.

## What Common adds

| Change | What it is |
|---|---|
| `ConsentPurpose` | What a consent is for, ordered by `Sequence`. Common seeds only the generic purposes, Marketing and Transactional; an app built on Common seeds its own (a fundraising app adds Fundraising, MJ Forms could add Surveys). A lookup like ContactType, so purposes are added without DDL |
| `ContactMethodConsent` | One row per contact method, optional purpose and optional requesting organization, holding the current status: `Not Specified`, `Opted In` or `Opted Out`. No purpose means the general answer for the address; no requesting organization means the answer for anyone on the installation. A contact method has many of these, the way a person has many contact methods |
| `ContactMethodConsentHistory` | One row per change on a consent: the new status, when it took effect in the real world (`ConsentStatusAt`), where it came from (`ConsentSource`: Web Form, Unsubscribe Link, Import, Staff or Other, default Staff), the specifics (`ConsentDetails`, such as which system an import came from) and who recorded it |
| `ContactType.CommunicationBaseMessageTypeID` | Links each type to Comms' message types, so each is known to be Email, Phone or SMS and code never matches on names |
| `ContactMethodConsentEntity` | The consent entity subclass. Holds the history rules, and its `Save` adds a history row when the status was changed directly, recording the acting user on either tier |
| `ContactPreferenceEngine` | `CanContact`, `SetConsent`, `OptOutByValue`, each taking an optional purpose and an optional requesting organization. Setting consent writes the history row and the current status together. This is what Comms' hook calls |

Why two scope dimensions: consent in the GDPR and CAN-SPAM sense is per sender and per purpose,
not per address. A person can be opted in to receipts and out of newsletters, and a person who deals
with two organizations on one installation can say yes to one and no to the other.

`RequestingOrganizationID` is the organization that asked, not the owner of the address (that is
`ContactMethod.PersonID` or `ContactMethod.OrganizationID`). It is a scope, not a visibility rule:
an app that hosts several organizations on one installation adds its own row-level security over
these tables, following the contact method's owner.

Rules:

- `ContactMethodConsent.ConsentStatus` always equals `NewConsentStatus` on the history row with the
  latest `ConsentStatusAt`.
- `SetConsent` and `OptOutByValue` add the history row and update `ConsentStatus` in one unit of
  work. The history is a related-record collection on the consent, so the two save together on
  either tier; `ContactMethodConsentEntity.Save` adds a history row with the default source when the
  status was changed directly, so the rule holds for a form edit too.
- An import that arrives late with an older date is added to history but does not change the
  current status.
- `CanContact` uses the most specific consent a method has, in this order: this purpose asked by this
  organization; this purpose from anyone; any purpose asked by this organization; the general row;
  then nothing recorded. A question with no purpose starts at the third rung. General never means
  default: a general opt-in loses to a Marketing opt-out for a Marketing send. Across a person's
  methods on the channel, an opt-in anywhere wins; nothing recorded allows contact unless the caller
  requires an explicit opt-in.
- A purpose name the installation does not have is refused (`Unknown Purpose`), never answered from
  the general row, so a misspelt purpose cannot read a general opt-in as permission.
- Deleting a contact method deletes its consents and their history (`ON DELETE CASCADE`).
- MemberJunction's record change tracking stays on as the system audit (who changed a row in MJ,
  and when). The history table holds the real-world history.

## What users see

Consent shows on each contact method in the existing contact method list: one badge per consent the
method has (purpose and status), or a single Not Specified badge when it has none, for every type
that maps to a channel. Hovering the badges shows the method's history across its consents, newest
first, with the source and details of each change. The edit row offers a General dropdown and one
per active purpose, for the installation-wide answers; consents asked by a specific organization are
managed on the Contact Method Consents records themselves. Inside a Person form, an edit shows on
the badges straight away, before the form is saved.

## Channel mapping

`Email` maps to the Email message type; `Mobile Phone`, `Work Phone` and `Home Phone` map to Phone.
`Fax`, `LinkedIn`, `Twitter / X` and `Website` map to nothing, so they carry no badge and `CanContact`
ignores them. No contact type maps to SMS yet, so `CanContact` for SMS answers No Contact Method for
everyone (see "Still to settle").

## Apps with existing flags, after this ships

An app that carries per-person opt-in booleans (email, phone, postal) moves them like this:

| Flag today | Moves to |
|---|---|
| email opt-in | a general `ContactMethodConsent` (no purpose) on the person's primary email, because the flag never had one |
| phone opt-in | a general `ContactMethodConsent` on the person's primary phone |
| postal opt-in | Stays on the app's table until postal consent has a home in Common |

`true` becomes `Opted In`, `false` becomes `Opted Out`, `NULL` becomes `Not Specified`. Each moved
flag gets one history row with source `Import` and the app's name in `ConsentDetails`; where the
app's source systems hold consent dates, those become history rows with their real dates. Then the
app's columns are dropped.

## For the PostgreSQL migration

`UQ_ContactMethodConsent_Method_Purpose_Organization` relies on SQL Server treating NULLs as equal
in a unique constraint, which is what allows only one general, installation-wide row per contact
method. PostgreSQL treats NULLs as distinct by default, so the PostgreSQL counterpart needs
`UNIQUE NULLS NOT DISTINCT` (PostgreSQL 15+) or equivalent partial unique indexes to keep that rule.

## Still to settle

1. **The hook's contract.** What Comms asks (recipient, channel, maybe purpose) and what it gets back.
   `ContactPreferenceEngine.CanContact` returns `{ Allowed, Status, Reason }` for a person or
   organization and a channel. It allows the channel when any one address is opted in, but does not
   say which address; a sender that then picks the primary address could reach an opted-out one.
   The hook may need to return the permitted addresses rather than a yes or no.
2. **SMS.** Whether SMS needs its own contact type, or a second channel link on `ContactType`, so a
   mobile number can answer for SMS as well as Phone.
3. **Contact center's do-not-call list.** `DoNotCallEntry` in bizapps-contact-center overlaps with
   phone opt-outs. Whether contact center reads Common's consent, feeds into it, or both.
