# CRUD, FLS and Sharing Assessment

## User-facing execution

User-invoked services are declared `with sharing` (or the Lead adapter uses `inherited sharing`). Queries and DML use Salesforce user-mode enforcement (`WITH USER_MODE`, `AccessLevel.USER_MODE`, or user-mode DML). Sensitive dynamic paths perform explicit schema checks, including object accessibility/create/update checks and field accessibility/create/update checks.

Representative controls include:

- Booking validates object and field permissions for Lead, User, Service Resource, Service Appointment, Assigned Resource and Event before mutation.
- Booking, appointment commands, location/resource administration, availability, services, analytics, health and readiness use user-mode queries/DML.
- Dynamic resource administration uses `Database.queryWithBinds(..., AccessLevel.USER_MODE)` rather than concatenating user-provided values into executable SOQL.
- Standard `Location.Description` is optional: it is selected or written only when its field describe grants the necessary access. Core location administration remains functional when a subscriber profile cannot access that field.
- Negative tests prove a user without the booking custom permission cannot create an appointment.

## Intentional system-context services

Four narrowly scoped classes use `without sharing`. Their purpose requires complete organizational visibility; none returns hidden business records to the UI.

| Class | Reason system context is necessary | Boundary |
|---|---|---|
| `LadminAIAppointmentEditionService` | Counts all active managed locations/resources. A sharing-filtered count would let users bypass edition limits by hiding records. | Returns counts/allowance and exact limitation messages; it does not expose the counted records. |
| `LadminAIAppointmentOccupancyService` | Collision detection must see every appointment for a resource, including records not shared to the booking user, or overlapping appointments could be created. | Returns internal occupancy data to scheduling services only; it is not an Aura-enabled record browser. |
| `LadminAIAppointmentReminderScheduler` | A scheduled background job must process all due appointments, independent of the scheduling user's record sharing. | Selects a bounded batch (maximum 200) only when customer notifications are enabled, enqueues notifications, and marks reminders sent. |
| `LadminAIEventReconciliationService` | Background integrity repair must locate appointments/events across owners to restore missing or drifted calendar projections. | Bounded to 1–500 records, processes non-cancelled recent/future appointments, records synchronization status/errors, and is not a general data retrieval endpoint. |

The PMD CRUD suppressions on these classes are intentional and localized. Converting them to caller sharing would break edition enforcement, conflict protection, reminders, or reconciliation correctness.

## Data access model

- Six packaged permission sets separate analytics, booking, configuration, availability, location administration and resource administration.
- Permission sets grant only the objects, fields, Apex classes and app functions needed for the persona.
- OpenAI access is optional. The package does not embed a secret. Principal authorization is a subscriber post-install task rather than packaged broad credential access.
- `LadminAIAppointmentBookingService` checks the `LadminAI_Book_Appointment` custom permission before proceeding with booking work.
- All direct UI errors are normalized to user-safe messages; credential values are not returned.

## Reviewer focus areas

Review the four documented system-context classes against their bounded purposes, verify user-mode enforcement in the remaining services, and execute both the authorized and unauthorized booking tests. Any future new system-context class requires a separate justification and test coverage.
