# LadminAI Appointment Configuration Guide

## Gate 1 scope

Gate 1 establishes configuration metadata only. No class reads this configuration yet, and no booking, status transition, Event synchronization, slot reservation, or adapter behavior is activated.

## Appointment settings

`LadminAI_Appointment_Settings__mdt` centralizes the small set of values that are hard-coded in the legacy scheduler.

| Field | Default | Purpose |
|---|---:|---|
| `LadminAI_Default_Slot_Minutes__c` | 30 | Future default appointment duration |
| `LadminAI_Default_Time_Zone__c` | UTC | Future product-neutral time-zone basis for slots |
| `LadminAI_Booking_Horizon_Days__c` | 90 | Future maximum advance booking window |
| `LadminAI_Minimum_Lead_Time_Minutes__c` | 0 | Future minimum time before a booking |
| `LadminAI_Create_Salesforce_Event__c` | true | Future control for the Event calendar projection |
| `LadminAI_Default_Booking_Status__c` | Booked | Future default canonical status |
| `LadminAI_Enable_Parent_Adapter__c` | false | Future opt-in for an approved parent adapter |
| `LadminAI_Enable_Compatibility_Aura__c` | true | Records the intended compatibility posture |

The packaged `Default` record contains product-neutral defaults. Editing it has no runtime effect in Gate 1.

## Status mapping

`LadminAI_Status_Mapping__mdt` reserves a direct mapping from a source object/status to one of the approved canonical values:

Draft, Reserved, Booked, Confirmed, Checked In, In Progress, Arrived, Completed, Cancelled, No Show, and Rescheduled.

Gate 1 creates no mapping records and enforces no transitions. That work belongs to the lifecycle gate.

## Lightweight extension points

- `LadminAIAppointmentIBookingParentAdapter` is an empty marker interface.
- `LadminAIAppointmentLeadParentAdapter` is an empty Lead-specific marker implementation.
- `LadminAI_Service_Type__mdt` and `LadminAI_Appointment_Type__mdt` remain architecture reservations only and are not created in Gate 1.

This keeps the approved extension points visible without introducing a framework or speculative product behavior.

## Security

Six custom permissions define capability names but grant no access by themselves. Persona permission sets, object/field access, Apex access, and enforcement are added in the security gate. No permission is assigned automatically.
