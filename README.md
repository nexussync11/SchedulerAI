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

## LadminAI Appointment Phase 0

The `phase-0-ladminai-appointment` branch transforms the retrieved scheduler into a focused Salesforce AppExchange scheduling product through gated changes. New commercial package source is under `ladminai-appointment/main/default`; the original `force-app` remains a non-default legacy reference directory.

- [Configuration guide](docs/CONFIGURATION_GUIDE.md)
- [2GP packaging guide](docs/2GP_PACKAGING_GUIDE.md)
- [Product branding](docs/PRODUCT_BRANDING.md)
- [Booking service design](docs/BOOKING_SERVICE_DESIGN.md)
- [Booking API contract](docs/BOOKING_API_CONTRACT.md)

