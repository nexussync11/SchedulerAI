# Product Functional Design

## Purpose and scope

SchedulerAI is a Salesforce-native appointment/referral scheduling solution with two overlapping booking approaches:

1. A custom Aura/Apex booking experience (`CreateReferralCMP`) that books a selected Salesforce service resource.
2. An active screen flow (`Booking_Screen_Flow_Popup`) that presents four external Calendly links.

It also includes weekly availability administration, appointment-to-Lead synchronization, reschedule/no-show counters, and legacy communication automation.

This document describes only behavior evidenced by the retrieved metadata. “Implemented” means executable metadata is present, not that production operation was tested.

## Users and roles

| Role | Evidenced activity | Access assumptions |
|---|---|---|
| Booking agent / SDR | Launches booking UI from a Lead, chooses resource/date/slot, records `Booked By` | Needs Lead, Event, scheduling-object access and Apex/Aura access; the retrieved permission set does not cover Lead/Event or Apex classes |
| Availability administrator | Uses `Weekly_Availability_Manager` to edit resource hours/breaks | `BookingAppointment` grants broad scheduling-object access |
| Doctor / service resource | May be linked through `Service_Resource__c.RelatedRecordId__c` | Controller can auto-select the current user’s resource |
| Operations / sales | Reviews Appointment list views and Lead status fields | Access is not fully represented by the single retrieved permission set |
| Patient / prospect | No native authenticated patient UI is evidenced | External Calendly links provide partial self-booking |

## Capability status

### Appointment and referral booking — implemented with material defects

- Entry: `CreateReferralCMP`, usable on app pages, record pages, communities, and Lightning quick actions.
- Context: assumes `recordId` is a Lead.
- Input: Lead context, appointment subject/date, resource, one 30-minute slot, booking source, booking status, and booked-by user.
- Reads: Lead, active `Service_Resource__c`, related User, `Resource_Availability__c`, and same-day `ServiceAppointment__c`.
- Writes: Lead referral fields and `Booked_By__c`; creates `ServiceAppointment__c`, Event, and `Assigned_Resource__c`.
- Output: navigates back to the Lead.
- Validation: date/resource present, exactly one displayed slot selected, and `Booked By` selected.
- Failure conditions: invalid/missing Lead, missing resource/User, invalid time parsing, required/invalid appointment status, missing component dependencies, DML/validation failure.
- Defects: the JavaScript omits Apex parameter `leadName`; `bookingstatus` is initialized blank and has no enabled input; navigation occurs before the booking callback completes; errors are logged but not surfaced; appointment collision data is queried but never used.

### Referral creation — partially implemented

The booking process updates an existing Lead’s `Referral_Subject__c` and `Referral_Details__c`. It does not create a new Lead, Contact, Account, Opportunity, or a separate Referral object.

### Patient/contact selection — referenced but not part of the main working path

- The component reads the current Lead’s email.
- `fetchContactEmail` exists, and the component contains state for a selected lookup record.
- The visible booking path selects a service resource, not a patient/contact.
- `customLookup` depends on missing `customLookUpController1` and `customLookupResult`.

### Location selection — external/partial

No Location lookup participates in the custom Aura/Apex booking logic. The screen flow exposes hard-coded external booking links for Manchester, London Mayfair, London Harley Street, and a virtual consultation. No retrieved location object or location-resource relationship supports native multi-location scheduling.

### Doctor/service-resource management — implemented at schema level

`Service_Resource__c` represents a schedulable person and links to User. Active resources can be selected. No dedicated resource-management UI, credential/skill model, specialty model, or location assignment is retrieved.

### Weekly availability — implemented

`availabilityManager` displays Monday–Sunday start/end and break times. `AvailabilityManagerController.saveAvailabilityV2` creates one schedule per resource and upserts one row per day using `Resource_Day_Key__c`.

Validation is minimal: a resource is required, but start-before-end, break boundaries, overlapping rows, duplicate schedules, and mandatory hours are not enforced.

### Slot generation/search — partially implemented

`availableStartTimeSlot` creates fixed 30-minute intervals within active hours and removes intervals overlapping one break. It does not:

- remove existing appointments;
- lock or reserve a chosen slot;
- apply location, appointment type, capacity, travel, holiday, or leave rules;
- search across resources;
- handle variable duration;
- explicitly normalize time zones.

### Anonymous doctor allocation — not implemented

`Anonymous_Booking__c` exists, but no algorithm uses it. A specific resource must be selected and is assigned to the booking.

### Rescheduling and tracking — implemented as counters, not a full workflow

- Event start changes invoke `AppointmentRescheduleHandler`.
- `ServiceAppointment__c.Scheduled_Start__c` changes invoke `AppointmentTrackingHandler`.
- Both increment Lead `Reschedule_Count__c`; changing status to `DNA` increments `DNA_Count__c`.
- There is no atomic synchronization between Event and `ServiceAppointment__c`, no customer confirmation, and no collision recheck.

### Cancellation — modeled but not orchestrated

`ServiceAppointment__c.Status__c` includes `Cancel`, and `Cancellation_Reason__c` exists. No retrieved Apex, active Flow, trigger, or Aura action implements cancellation, releases a slot, updates the paired Event, or sends cancellation communications.

### Appointment status — implemented in multiple, inconsistent models

- `ServiceAppointment__c.Status__c`: Arrived, Cancel, No Show, Open, DNA.
- `Appointment__c.Appointment_Status__c`: Booked, Attended, No Show, Cancelled.
- Event `Status__c` is assigned during booking, but its field metadata was not present in the source.
- The booking controller first sets `Scheduled`, then overwrites it with the potentially blank `bookingstatus`.
- `Did_Lead_Attend_Appointment` updates `Appointment__c` based on Lead stage/status conditions.

### Calendar — basic Event creation only

Bookings create Salesforce Events owned by the selected resource’s User. There is no retrieved calendar UI, external calendar synchronization, conflict query, recurrence, or bidirectional update process.

### Notifications — legacy/referenced

Three obsolete flows reference:

- Twilio action `InvokeApi`;
- mappings “Appointment Booked SMS” and “Appointment Reminder SMS”;
- Event email alerts `Appointment_Booked` and `Appointment_Reminder`;
- timing bands under 24 hours, 24–72 hours, and over 72 hours.

Those actions, mappings, email alerts/templates, and current active notification orchestration are not in the repository. Notification delivery cannot be confirmed.

## Business rules

| Rule | Evidence | Status |
|---|---|---|
| Appointment slots are 30 minutes | Hard-coded in slot generator and booking method | Implemented, not configurable |
| Active availability only | `Is_Active__c = true` query | Implemented |
| Active resource and active related User | booking query | Implemented during booking |
| One selected slot | Aura client validation | Client-only |
| `Booked By` mandatory | Aura check and required `ServiceAppointment__c.Booked_By__c` | Implemented |
| Confirmed appointment requires confirming SDR | `Appointment__c.Confirmed_by_Rule` | Implemented |
| One availability row per schedule/day | external-ID upsert key | Intended; field is external ID but not unique |
| Component access expires | `Component_Config.appointmentBookingAura` | Implemented, fail-open |
| Latest Appointment updates Lead | active `Appointment_Data_to_map_to_lead` | Implemented |
| Lead stage indicates attendance | active `Did_Lead_Attend_Appointment` | Implemented, criteria-specific |

## Product capability matrix

| Capability | Available now | How it works | Components | Limitations | Recommended enhancement |
|---|---|---|---|---|---|
| Multi-location scheduling | Partial | External Calendly links name locations | Booking screen flow | No native location model in scheduling path | Add Location and resource-location availability |
| Doctor availability | Yes | Weekly day rows and breaks | availability Aura/Apex, availability objects | No exceptions/leave/time zone/validation | Calendar-based availability service |
| Appointment booking | Partial | Aura creates custom appointment, Event, assignment | CreateReferralCMP/controller | High-risk defects and no collision enforcement | Atomic booking service with locking |
| Rescheduling | Partial | Counters react to date changes | 2 triggers/handlers | No synchronized workflow | Guided reschedule with conflict check |
| Cancellation | Partial | Status/reason fields only | ServiceAppointment__c | No process or communications | Cancellation service and policy |
| Status tracking | Yes, inconsistent | Picklists, Lead counters, active flows | objects, trigger, flows | Multiple vocabularies | Canonical lifecycle/state machine |
| Calendar view | Basic | Salesforce Event created | Event | No bespoke view or sync | Scheduler calendar UI |
| Notifications | Legacy | Obsolete Twilio/email flows | 3 obsolete flows | Missing dependencies; inactive | Event-driven notification service |
| Patient self-booking | Partial | Hard-coded Calendly links | screen flow | External, fragmented | Secure Experience Cloud/LWR portal |
| Mobile support | Partial | Aura interfaces and responsive SLDS | Aura | Dense weekly table; legacy controls | LWC mobile-first UI |
| Analytics | Minimal | list views and Lead counters | Appointment list views, Lead fields | No dashboards/data model | Operational dashboards |
| Waitlist | No | — | — | — | Waitlist object and matching |
| No-show prediction | No | DNA counter only | tracking handler | No model | Phase 3 prediction |
| AI scheduling | No | — | — | — | Constraint-based ranking assistant |
| External calendar sync | No | Salesforce Event only | Event | No Microsoft/Google sync | Calendar integration with conflict reconciliation |
| Calendly replacement | Partial | Some native booking plus external links | Aura + flow | Native flow is unsafe/incomplete | Consolidated booking platform |

