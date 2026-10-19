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
  Common gets it, not just TRG.
- **TRG keeps interim flags** (`MailOptIn`, `EmailOptIn`, `PhoneOptIn`, nullable booleans on its
  Customer table) until Common's part lands, then moves them onto the customer's contact methods.

The layers depend downward. Comms never needs to know Common's tables, because Common plugs into
Comms' hook, not the other way round.

## What Common adds

| Change | What it is |
|---|---|
| `ContactMethod.ConsentStatus` | The current status: `NotSpecified`, `OptedIn` or `OptedOut`, default `NotSpecified` |
| `ContactConsentHistory` | One row per consent change, many per contact method: the new status, when it took effect in the real world (`ConsentStatusAt`), where it came from (`ConsentSource`), who recorded it, and evidence (`Notes`) |
| `ContactType.CommunicationBaseMessageTypeID` | Links each type to Comms' message types, so each is known to be Email, Phone or SMS and code never matches on type names |
| `ContactPreferenceEngine` | `CanContact`, `SetConsent`, `OptOutByValue`. Setting consent writes the history row and the current status together. This is what Comms' hook calls |

Rules:

- `ContactMethod.ConsentStatus` always equals `NewConsentStatus` on the history row with the latest
  `ConsentStatusAt`.
- `SetConsent` and `OptOutByValue` add the history row and update `ConsentStatus` in one unit of
  work. The history is a related-record collection on the contact method, so the parent and the row
  save together on either tier; `ContactMethodEntity.Save` adds a `Staff` row when the status was
  changed directly, so the rule holds for a form edit too.
- An import that arrives late with an older date is added to history but does not change the
  current status.
- Deleting a contact method deletes its history with it (`ON DELETE CASCADE`).
- MemberJunction's record change tracking stays on as the system audit (who changed a row in MJ,
  and when). The history table holds the real-world history.

## What users see

Consent shows on each contact method in the existing contact method list: a badge per row
(Opted in, Opted out, Not specified) for every type that maps to a channel, and a Consent dropdown
on the edit row. Hovering a badge shows that email or phone's history, newest first, with the source
of each change. A "Can contact" summary per channel on the person header is optional and not in
this change.

## Channel mapping

`Email` maps to the Email message type; `Mobile Phone`, `Work Phone` and `Home Phone` map to Phone.
`Fax`, `LinkedIn`, `Twitter / X` and `Website` map to nothing, so they carry no badge and `CanContact`
ignores them. SMS has no contact type of its own yet; a mobile number's consent answers for Phone.
Whether SMS needs its own type or a second link on `ContactType` is open.

## TRG, after this ships

| TRG flag today | Moves to |
|---|---|
| `EmailOptIn` | `ConsentStatus` on the customer's primary email |
| `PhoneOptIn` | `ConsentStatus` on the customer's primary phone |
| `MailOptIn` | Stays on Customer until postal consent has a home in Common |

`true` becomes `OptedIn`, `false` becomes `OptedOut`, `NULL` becomes `NotSpecified`. Each moved flag
gets one history row with source `Import: TRG`; where ODS or Purple 7 hold consent dates, those
become history rows with their real dates. Then the Customer columns are dropped.

## Still to settle

1. **The hook's contract.** What Comms asks (recipient, channel, maybe purpose) and what it gets back.
   `ContactPreferenceEngine.CanContact` returns `{ Allowed, Status, Reason }` for a person or
   organization and a channel; adjust it to the hook when the hook exists.
2. **Contact center's do-not-call list.** `DoNotCallEntry` in bizapps-contact-center overlaps with
   phone opt-outs. Whether contact center reads Common's consent, feeds into it, or both.
