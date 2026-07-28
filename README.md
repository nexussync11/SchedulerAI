# Harley Salesforce Scheduler

This repository is a retrieval-only snapshot of the appointment scheduling metadata from the Salesforce Partial Copy sandbox authenticated locally as `harley-partial`.

No metadata was changed or deployed during retrieval. No Salesforce records were retrieved.

## Source layout

- `force-app/main/default` — Salesforce DX source
- `manifest/package.xml` — targeted retrieval manifest
- `docs/ARCHITECTURE.md` — application structure and workflows
- `docs/METADATA_INVENTORY.md` — retrieved component inventory
- `docs/RETRIEVAL_REPORT.md` — retrieval and security review record

## Primary entry points

- `CreateReferralCMP` — appointment/referral booking Aura component
- `Weekly_Availability_Manager` — custom tab exposing `availabilityManager`
- `AppointmentTracking` — `ServiceAppointment__c` after-update trigger
- `AppointmentReschedule` — Event after-update trigger
- `Booking_Screen_Flow_Popup` — active screen flow

The source is preserved as retrieved. It has not been refactored, modernized, or functionally changed.

