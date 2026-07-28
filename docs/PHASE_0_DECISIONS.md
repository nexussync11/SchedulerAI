# LadminAI Appointment — Phase 0 Decisions

## Decision record

| ID | Decision | Status |
|---|---|---|
| D-01 | Use resource/date ledger locking plus an overlap query after `FOR UPDATE` | Recommended; approval requested |
| D-02 | Use a client-generated idempotency key persisted as a unique external ID | Recommended; approval requested |
| D-03 | Link `ServiceAppointment__c` durably to Event; prefer a bidirectional relationship if package validation allows it | Recommended with fallback; approval requested |
| D-04 | Adopt eight canonical lifecycle statuses while preserving legacy values through custom metadata mapping | Recommended; approval requested |
| D-05 | Keep Aura as compatibility only; new UI calls new domain services | Decided by gate brief |
| D-06 | Use one managed 2GP with logical modules and a separate package directory | Recommended; approval requested |
| D-07 | Keep Lead updates behind an optional compatibility adapter | Recommended; approval requested |
| D-08 | Exclude Harley-specific flows, links, communication dependencies, and generic credential storage from reusable core | Recommended; approval requested |

## D-01 — collision locking

### Decision

Create `LadminAI_Booking_Lock__c` with a unique `Resource_Date_Key__c`. Lock the relevant resource/date ledger row(s) `FOR UPDATE`, then re-query overlaps and create the appointment before the transaction ends.

### Why

- A pre-query alone has a race window.
- A unique start-time field cannot detect arbitrary overlapping ranges.
- Locking the resource record would serialize unrelated dates and may conflict with resource administration.
- A ledger has a narrow lock scope and supports date-based reconciliation.

### Edge policy

- Adjacent end/start times do not conflict.
- Conflict predicate: existing start `<` requested end and existing end `>` requested start.
- Cancelled and configured non-blocking statuses are excluded.
- Cross-midnight requests lock both local dates in lexical key order.
- Lock timeout returns a retryable safe error; the UI refreshes slots.

## D-02 — idempotency

### Decision

Require a UUID-like `idempotencyKey` generated once per intended booking submission. Store it in `ServiceAppointment__c.Idempotency_Key__c`, marked unique and external ID.

### Behavior

- Same key and same material request returns the original successful result.
- Same key with different material request returns `IDEMPOTENCY_KEY_REUSED`.
- A failed transaction does not consume the key because all writes roll back.
- Keys contain no user or patient information.

The UI disables duplicate submission, but server idempotency remains authoritative.

## D-03 — Event relationship

### Decision

Add `ServiceAppointment__c.Event__c`. Also add `Event.LadminAI_Service_Appointment__c` if scratch-org/package validation confirms support and upgrade safety. Set both in the booking transaction.

### Fallback

If a custom Event lookup is not supportable, retain `ServiceAppointment__c.Event__c`, add `Event.LadminAI_Managed__c`, and resolve from the appointment side. Do not use subject, owner, start time, or `WhoId` as the relationship.

## D-04 — canonical lifecycle

Canonical values:

1. Draft
2. Booked
3. Confirmed
4. Arrived
5. Completed
6. Cancelled
7. No Show
8. Rescheduled

`LadminAI_Status_Mapping__mdt` maps legacy values such as `Open`, `Scheduled`, `Cancel`, and `DNA` to canonical values without deleting subscriber picklist values. The lifecycle service validates transitions and owns side effects.

Recommended transition set:

- Draft → Booked, Cancelled
- Booked → Confirmed, Rescheduled, Cancelled, No Show
- Confirmed → Arrived, Rescheduled, Cancelled, No Show
- Arrived → Completed, Cancelled
- Rescheduled → Booked, Confirmed, Cancelled
- Completed, Cancelled, No Show → terminal by default

Administrators may add mappings, not arbitrary transitions, in Phase 0.

## D-05 — legacy adapters

Define a narrow parent adapter interface. The core service can book against a supported parent without knowing Harley fields. `LadminAIAppointmentLeadAdapter` optionally updates `Referral_Subject__c`, `Referral_Details__c`, and `Booked_By__c` when `Enable_Lead_Adapter__c` is true and access checks pass.

`CreateReferralCMP` is retained during migration. Gate 5 may make it a wrapper or deprecated entry point, but it is not deleted.

## D-06 — LWC composition

Use a stateful booking orchestrator and small presentation/input children. Server calls are centralized in the parent or a shared JavaScript service module. The architecture prevents children from independently creating records or producing multiple transactions.

## D-07 — permission model

Use custom permissions for capabilities and four persona permission sets:

- User: view/select resources, view slots, create own permitted bookings.
- Manager: manage appointments and availability within sharing.
- Admin: configure product metadata and resource setup.
- Integration: API-only minimum access for approved integration operations.

Normal users receive neither Modify All nor View All. Permission sets are never auto-assigned.

## D-08 — package boundary

The commercial core excludes:

- hard-coded Calendly/clinic flow;
- obsolete Twilio/email flows and missing dependencies;
- `RequestResource__c` unless a subscriber compatibility requirement is proven;
- Harley-specific Lead adapter metadata from mandatory core;
- incomplete `customLookup` until dependencies are supplied or it is replaced.

## Approval required before Gate 1

1. Approve resource/date ledger locking and the new lock object.
2. Approve storing idempotency on `ServiceAppointment__c`.
3. Approve preferred bidirectional Event linkage with the documented fallback.
4. Approve the canonical statuses and transition policy.
5. Approve excluding Harley-specific integrations/flows from reusable core.
6. Approve a single 2GP package directory while retaining `force-app` as reference during migration.
7. Confirm whether the Lead adapter belongs in the initial managed package or a compatibility extension.
