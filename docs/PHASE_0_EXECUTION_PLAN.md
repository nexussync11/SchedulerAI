# LadminAI Appointment — Phase 0 Execution Plan

## Purpose

Phase 0 stabilizes and productizes the existing scheduler without deploying to a Harley org, deleting legacy metadata, changing existing object API names, adding AI, or releasing a managed package.

This plan is based on the source at `initial-harley-scheduler-source` and the technical analysis at `deep-app-analysis`. Gate 0 changes documentation only.

## Verified baseline

| Area | Inventory |
|---|---|
| Apex | 4 production classes, 4 test classes |
| Triggers | 2 |
| Aura | 4 component bundles and 1 component event bundle |
| LWC | 0 |
| Flows | 9: 4 Active, 1 Draft, 1 InvalidDraft, 3 Obsolete |
| Custom objects in scope | 8 business/configuration objects plus `Component_Config__mdt` |
| Standard-object extensions | Event and Lead |
| Permission sets | `BookingAppointment` |
| Custom metadata records | `Component_Config.appointmentBookingAura` |
| Entry points | `CreateReferralCMP`, `Weekly_Availability_Manager`, `Booking_Screen_Flow_Popup`, 2 triggers |

Detailed baseline evidence remains in [METADATA_INVENTORY.md](METADATA_INVENTORY.md), [ARCHITECTURE.md](ARCHITECTURE.md), and the reference branch documentation.

## Gate sequence

### Gate 1 — foundation and branding

Create a package-safe product shell without changing booking behavior.

Planned metadata:

- Lightning app `LadminAI_Appointment`
- tabs or LWC navigation surfaces for Book Appointment, Appointments, Availability, and Service Resources
- custom metadata types `LadminAI_Appointment_Settings__mdt` and `LadminAI_Status_Mapping__mdt`
- six custom permissions specified in the gate brief
- scratch definition under `config/project-scratch-def.json`
- initial package directory and product documentation

Migration effect: additive only. Existing Aura, Apex, objects, tabs, and flows remain.

### Gate 2 — transactional booking service

Planned Apex:

- `LadminAIAppointmentBookingService`
- `LadminAIAppointmentBookingRequest`
- `LadminAIAppointmentBookingResult`
- `LadminAIAppointmentConflict`
- `LadminAIAppointmentException`
- `LadminAIAppointmentAuthorization`
- `LadminAIAppointmentParentAdapter`
- `LadminAIAppointmentLeadAdapter`
- `LadminAIAppointmentBookingServiceTest`
- shared `LadminAIAppointmentTestDataFactory`

Planned behavior:

1. validate and authorize one typed request;
2. resolve configuration and canonical status;
3. apply the optional parent adapter;
4. create `ServiceAppointment__c`, Event, and `Assigned_Resource__c` in one transaction;
5. persist the Event relationship and idempotency record/key;
6. return a safe typed result.

Migration effect: the new service is additive. `CreateReferralCMP` continues to use its legacy controller until Gate 5. The separate `updateBookedBy` transaction is not used by the new path.

### Gate 3 — collision control and slot engine

Planned Apex:

- `LadminAIAppointmentSlotService`
- `LadminAIAppointmentSlotRequest`
- `LadminAIAppointmentSlot`
- `LadminAIAppointmentLockService`
- `LadminAIAppointmentSlotServiceTest`
- concurrency and overlap cases in booking tests

Planned metadata:

- `LadminAI_Booking_Lock__c`
- `Resource_Date_Key__c` unique external-ID text field
- `Service_Resource__c`, `Service_Date__c`, and lock/audit fields
- optional configuration fields `Slot_Interval_Minutes__c` and `Conflict_Retry_Count__c`

Migration effect: lock rows are created lazily for new booking dates. Existing appointments remain authoritative blockers and are queried after the lock is acquired.

### Gate 4 — lifecycle and rescheduling

Planned Apex:

- `LadminAIAppointmentLifecycleService`
- `LadminAIAppointmentStatusService`
- `LadminAIAppointmentEventLinkService`
- lifecycle/status tests
- bulk-safe revisions to `AppointmentRescheduleHandler` and `AppointmentTrackingHandler`

Planned fields:

- `ServiceAppointment__c.Event__c` — lookup to Event
- `Event.LadminAI_Service_Appointment__c` — lookup to `ServiceAppointment__c`, if Salesforce metadata/runtime validation confirms the relationship is supported and package-safe
- `ServiceAppointment__c.Idempotency_Key__c` — unique external ID
- `ServiceAppointment__c.Booking_Reference__c` — unique, user-safe reference
- `ServiceAppointment__c.Booking_Source__c`
- `Event.LadminAI_Managed__c` — marker used to scope trigger behavior

If a bidirectional Event lookup is not supported in the target packaging model, the fallback is a single durable `ServiceAppointment__c.Event__c` lookup plus the managed marker and indexed Event query. This requires approval before implementation.

Migration effect: legacy statuses are retained and mapped. Existing unlinked rows are not changed automatically; a separate administrator-reviewed backfill is documented, not run against Harley.

### Gate 5 — modern booking UI

Planned LWCs:

- `ladminAiAppointmentBooking`
- `ladminAiResourceSelector`
- `ladminAiDateSelector`
- `ladminAiSlotPicker`
- `ladminAiBookingSummary`
- `ladminAiBookingResult`
- `ladminAiErrorPanel`

Planned supporting Apex façade:

- `LadminAIAppointmentBookingController`, containing minimal `@AuraEnabled` orchestration methods over domain services
- `LadminAIAppointmentBookingControllerTest`

Migration effect: new UI becomes the recommended path. `CreateReferralCMP` remains as a compatibility entry point and is not deleted.

### Gate 6 — modern availability UI

Planned LWCs:

- `ladminAiAvailabilityManager`
- `ladminAiAvailabilityDayEditor`

Planned Apex:

- `LadminAIAppointmentAvailabilityService`
- typed availability request/result/error classes
- service and controller tests

Planned metadata constraints:

- make `Resource_Availability__c.Resource_Day_Key__c` unique after subscriber-data compatibility assessment;
- introduce a unique schedule/resource key if the existing schedule object cannot enforce one schedule per resource;
- add validation rules only when they do not block legacy data unexpectedly.

Migration effect: old `availabilityManager` remains temporarily. Any uniqueness change requires a duplicate audit and remediation plan before deployment.

### Gate 7 — least privilege

Planned permission sets:

- `LadminAI_Appointment_User`
- `LadminAI_Appointment_Manager`
- `LadminAI_Appointment_Admin`
- `LadminAI_Appointment_Integration`

They use custom permissions and grant only necessary object, field, class, tab, and application access. No automatic assignment is planned. `BookingAppointment` is retained for compatibility but excluded from the commercial permission model.

`RequestResource__c` is excluded from the core package unless a proven dependency appears. Credential-shaped fields are not copied into new product metadata.

### Gate 8 — packaging and CI

One initial managed 2GP package is planned, with logical module boundaries inside a single package directory. CI will run format/source checks, Jest, lint, Code Analyzer, metadata validation, and authenticated tests when secrets are configured by a repository administrator.

Legacy metadata will be classified as retained, compatibility, replaced, obsolete, missing dependency, or excluded. No package version will be created or released.

### Gate 9 — final validation

Run all available static and runtime validation in a scratch or dedicated non-Harley development org. Produce release, test, limitation, and Phase 1 documents. No Harley deployment is permitted.

## Validation strategy

| Validation | Gate |
|---|---|
| XML/source integrity and dependency scan | every implementation gate |
| Apex unit tests and coverage | Gates 2–4, 6–7, 9 |
| Jest and lint | Gates 5–6, 8–9 |
| Salesforce Code Analyzer | Gates 1–9 as applicable |
| scratch/development org deployment | when a non-Harley org is available |
| concurrency/overlap tests | Gates 3 and 9 |
| accessibility and manual UI QA | Gates 5, 6, 9 |
| package validation without release | Gates 8–9 |

## Exit criteria

The Phase 0 acceptance criteria are those in the controlling gate brief. Static-only results are not represented as runtime proof. Every gate is independently committed and pushed, and execution stops after each gate.
