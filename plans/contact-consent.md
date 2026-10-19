# Contact consent: per contact method, with history

Agreed with Paul, October 2026. This file records the decision; the code lands with it on
`feat/contact-method-consent`.

## The split

Consent is split across three layers, each doing one job:

- **Comms (MJ core) enforces** it at send time. It owns the send pipeline and the channels (the
  Email, Phone and SMS message types already exist in core). It stores no consent, because it does not
  own people or their contact details. Paul's Comms redesign adds a consent hook: before each send,
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
| `ConsentPurpose` | What a consent is for: Marketing, Transactional, Fundraising, Surveys to start. A lookup like ContactType, seeded by metadata, so an installation adds purposes without DDL |
| `ContactConsent` | One row per contact method, purpose and (optional) organization, holding the current status: `NotSpecified`, `OptedIn` or `OptedOut`. A contact method has many of these, the way a person has many contact methods |
| `ContactConsentHistory` | One row per change on a ContactConsent: the new status, when it took effect in the real world (`ConsentStatusAt`), where it came from (`ConsentSource`), who recorded it, and evidence (`Notes`) |
| `ContactType.CommunicationBaseMessageTypeID` | Links each type to Comms' message types, so each is known to be Email, Phone or SMS and code never matches on names |
| `ContactPreferenceEngine` | `CanContact`, `SetConsent`, `OptOutByValue`, each taking a purpose and an optional organization. Setting consent writes the history row and the current status together. This is what Comms' hook calls |

Why two scope dimensions: consent in the GDPR and CAN-SPAM sense is per sender and per purpose,
not per address. A person can be opted in to receipts and out of newsletters, and a person who deals
with two organizations on one installation can say yes to one and no to the other. `OrganizationID`
null means the answer for the whole installation, which is what a single-organization customer uses.

Rules:

- `ContactConsent.ConsentStatus` always equals `NewConsentStatus` on the history row with the latest
  `ConsentStatusAt`.
- `SetConsent` and `OptOutByValue` add the history row and update `ConsentStatus` in one unit of
  work. The history is a related-record collection on the consent, so the two save together on
  either tier; `ContactConsentEntity.Save` adds a `Staff` row when the status was changed directly,
  so the rule holds for a form edit too.
- An import that arrives late with an older date is added to history but does not change the
  current status.
- `CanContact` for a channel, purpose and organization uses the most specific consent a method has:
  that organization's row, else the installation-wide row, else nothing recorded. Across a person's
  methods on the channel, an opt-in anywhere wins; nothing recorded allows contact unless the caller
  requires an explicit opt-in.
- Deleting a contact method deletes its consents and their history (`ON DELETE CASCADE`).
- MemberJunction's record change tracking stays on as the system audit (who changed a row in MJ,
  and when). The history table holds the real-world history.

## What users see

Consent shows on each contact method in the existing contact method list: one badge per consent the
method has (purpose and status), or a single Not specified badge when it has none, for every type
that maps to a channel. Hovering the badges shows the method's history across its consents, newest
first, with the source of each change. The edit row offers a Consent dropdown per active purpose for
the installation-wide answer; per-organization consents are managed on the Contact Consents records
themselves.

## Channel mapping

`Email` maps to the Email message type; `Mobile Phone`, `Work Phone` and `Home Phone` map to Phone.
`Fax`, `LinkedIn`, `Twitter / X` and `Website` map to nothing, so they carry no badge and `CanContact`
ignores them. SMS has no contact type of its own yet; a mobile number's consent answers for Phone.
Whether SMS needs its own type or a second link on `ContactType` is open.

## Apps with existing flags, after this ships

An app that carries per-person opt-in booleans (email, phone, postal) moves them like this:

| Flag today | Moves to |
|---|---|
| email opt-in | a `ContactConsent` on the person's primary email, for the purpose the flag meant (usually Marketing) |
| phone opt-in | a `ContactConsent` on the person's primary phone, for that purpose |
| postal opt-in | Stays on the app's table until postal consent has a home in Common |

`true` becomes `OptedIn`, `false` becomes `OptedOut`, `NULL` becomes `NotSpecified`. Each moved flag
gets one history row with a source naming the app it came from (`Import: <app>`); where the app's
source systems hold consent dates, those become history rows with their real dates. Then the app's
columns are dropped.

## Still to settle

1. **The hook's contract.** What Comms asks (recipient, channel, maybe purpose) and what it gets back.
   `ContactPreferenceEngine.CanContact` returns `{ Allowed, Status, Reason }` for a person or
   organization and a channel; adjust it to the hook when the hook exists.
2. **Default purpose for callers that do not name one.** `CanContact` requires a purpose. Whether
   Comms always knows the purpose of a send, or needs a default, is part of the hook contract.
3. **Contact center's do-not-call list.** `DoNotCallEntry` in bizapps-contact-center overlaps with
   phone opt-outs. Whether contact center reads Common's consent, feeds into it, or both.
