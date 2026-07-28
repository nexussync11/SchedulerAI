# LadminAI Appointment Booking API Contract

## Entry points

- `LadminAIAppointmentBookingController.bookAppointment(request)`
- `LadminAIAppointmentBookingController.bookAppointments(requests)` — maximum four

Both return DTOs and do not throw internal details to Lightning callers.

## Request

| Property | Type | Required | Notes |
|---|---|---:|---|
| `parentRecordId` | Id | yes | Gate 2 supports accessible Lead context |
| `serviceResourceId` | Id | yes | active resource with active related User |
| `appointmentDate` | Date | yes | must match requested start date |
| `requestedStart` | Datetime | yes | start of booking |
| `requestedEnd` | Datetime | yes | after start; whole-minute duration |
| `bookingSource` | String | yes | active legacy booking-source value |
| `bookingStatus` | String | yes | `Booked`; `Open` compatibility alias accepted |
| `bookedBy` | String | yes | active `Booked_By__c` value |
| `subject` | String | yes | maximum 255 characters |
| `location` | String | no | maximum 255 characters |
| `appointmentType` | String | no | active value when supplied |
| `idempotencyKey` | String | yes | opaque, 8–80 characters; no personal data |

## Result

| Property | Type | Meaning |
|---|---|---|
| `success` | Boolean | booking exists and request succeeded |
| `idempotentReplay` | Boolean | existing same-key booking returned |
| `appointmentId` | Id | authoritative `ServiceAppointment__c` |
| `eventId` | Id | Event projection on initial creation |
| `assignedResourceId` | Id | created/existing assignment |
| `bookingReference` | String | stable `LA-...` reference |
| `userMessage` | String | safe message suitable for UI |
| `errorCode` | String | stable machine-readable code |
| `fieldErrors` | list | validation property/message pairs |
| `conflicts` | list | accessible appointment ID and start/end only |

## Error codes

`VALIDATION_FAILED`, `AUTHORIZATION_REQUIRED`, `OBJECT_ACCESS_REQUIRED`, `FIELD_ACCESS_REQUIRED`, `PARENT_NOT_ACCESSIBLE`, `RESOURCE_UNAVAILABLE`, `SLOT_CONFLICT`, `IDEMPOTENCY_KEY_REUSED`, `APPOINTMENT_CREATE_FAILED`, `EVENT_CREATE_FAILED`, `ASSIGNMENT_CREATE_FAILED`, `RELATED_OPERATION_FAILED`, `BOOKING_FAILED`, `REQUEST_REQUIRED`, and `BATCH_LIMIT_EXCEEDED`.

## Idempotency

The first successful request stores the key on `ServiceAppointment__c.LadminAI_Idempotency_Key__c`, a case-sensitive unique external-ID field. Repeating the same material request returns the existing appointment. Reusing the key with different parent, resource, start, or end returns `IDEMPOTENCY_KEY_REUSED`.

Keys must be random opaque client-generated identifiers and must not contain patient/customer information.
