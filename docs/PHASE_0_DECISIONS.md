# LadminAI Appointment — Phase 0 Decisions

## Decision record

| ID | Decision | Status |
|---|---|---|
| D-01 | Use resource/date ledger locking plus an overlap query after `FOR UPDATE` | Approved |
| D-02 | Use a client-generated idempotency key persisted as a unique external ID | Approved |
| D-03 | `Appointment__c`/`ServiceAppointment__c` are authoritative; Event is a synchronized projection | Approved |
| D-04 | Adopt eleven canonical lifecycle statuses while preserving legacy values through custom metadata mapping | Approved |
| D-05 | Keep Aura as compatibility only; new UI calls new domain services | Decided by gate brief |
| D-06 | Use one managed 2GP with logical modules and a separate package directory | Approved |
| D-07 | Use generic `IBookingParentAdapter`; Lead is one implementation | Approved |
| D-08 | Exclude Harley-specific flows, links, communication dependencies, and generic credential storage from reusable core | Approved |
| D-09 | Reserve metadata-driven Service Type and Appointment Type architecture | Approved; implementation deferred |
| D-10 | Apply LadminAI naming to every newly created asset | Approved |

## D-01 — collision locking

### Decision

Create `LadminAI_Booking_Lock__c` with a unique `LadminAI_Resource_Date_Key__c`. Lock the relevant resource/date ledger row(s) `FOR UPDATE`, then re-query overlaps and create the appointment before the transaction ends.

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

Require a UUID-like `idempotencyKey` generated once per intended booking submission. Store it in `ServiceAppointment__c.LadminAI_Idempotency_Key__c`, marked unique and external ID.

### Behavior

- Same key and same material request returns the original successful result.
- Same key with different material request returns `IDEMPOTENCY_KEY_REUSED`.
- A failed transaction does not consume the key because all writes roll back.
- Keys contain no user or patient information.

The UI disables duplicate submission, but server idempotency remains authoritative.

## D-03 — Event relationship

### Decision

`Appointment__c` and `ServiceAppointment__c` are the appointment systems of record for their established paths. The native LadminAI path uses `ServiceAppointment__c` as its transactional master. Event is only a synchronized calendar projection. Add `ServiceAppointment__c.LadminAI_Event__c`; also add `Event.LadminAI_Service_Appointment__c` if scratch-org/package validation confirms support and upgrade safety. Set links in the booking transaction.

### Fallback

If a custom Event lookup is not supportable, retain `ServiceAppointment__c.LadminAI_Event__c`, add `Event.LadminAI_Managed__c`, and resolve from the appointment side. Do not use subject, owner, start time, or `WhoId` as the relationship. Event changes never silently override authoritative appointment state.

## D-04 — canonical lifecycle

Canonical values:

1. Draft
2. Reserved
3. Booked
4. Confirmed
5. Checked In
6. In Progress
7. Arrived
8. Completed
9. Cancelled
10. No Show
11. Rescheduled

`LadminAI_Status_Mapping__mdt` maps legacy values such as `Open`, `Scheduled`, `Cancel`, and `DNA` to canonical values without deleting subscriber picklist values. The lifecycle service validates transitions and owns side effects.

Recommended transition set:

- Draft → Reserved, Booked, Cancelled
- Reserved → Booked, Cancelled
- Booked → Confirmed, Checked In, Arrived, Rescheduled, Cancelled, No Show
- Confirmed → Checked In, Arrived, Rescheduled, Cancelled, No Show
- Checked In → In Progress, Arrived, Cancelled
- Arrived → In Progress, Completed, Cancelled
- In Progress → Completed, Cancelled
- Rescheduled → Reserved, Booked, Confirmed, Cancelled
- Completed, Cancelled, No Show → terminal by default

Administrators may add mappings, not arbitrary transitions, in Phase 0.

## D-05 — legacy adapters

Define the generic `IBookingParentAdapter` contract. To satisfy the mandatory product prefix in Apex, create it as `LadminAIAppointmentIBookingParentAdapter`. The core service can book against a supported parent without knowing Harley fields. `LadminAIAppointmentLeadParentAdapter` is one implementation and optionally updates `Referral_Subject__c`, `Referral_Details__c`, and `Booked_By__c` when its configuration flag is enabled and access checks pass.

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
- Harley-specific Lead parent-adapter metadata from mandatory core;
- incomplete `customLookup` until dependencies are supplied or it is replaced.

## D-09 — Service and appointment type catalogue

Reserve `LadminAI_Service_Type__mdt` and `LadminAI_Appointment_Type__mdt` as future product-owned configuration. The model will support active state, default duration, slot interval, eligibility/configuration keys, and service-to-appointment-type mapping. Phase 0 code must use an abstraction that can adopt this catalogue later; no catalogue UI or full implementation is added without a future gate decision.

## D-10 — naming convention

Every new Apex class/interface, LWC bundle, object, field, custom metadata type/record, custom permission, application, tab, label, permission set, and configuration asset uses an appropriate `LadminAI` prefix. Existing API names remain unchanged. `IBookingParentAdapter` is the logical contract name; the actual Apex interface is `LadminAIAppointmentIBookingParentAdapter`.

## Approved items and remaining placement decision

The locking, idempotency, Event projection, expanded lifecycle, reusable-core exclusions, single-2GP strategy, generic parent adapter, future type catalogue, and LadminAI naming convention are approved.

One packaging placement remains to be finalized during package-boundary work: whether `LadminAIAppointmentLeadParentAdapter` ships in the initial managed package as optional compatibility metadata or in a later compatibility extension.
