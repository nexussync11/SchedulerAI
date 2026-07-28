# Harley Salesforce Scheduler

This repository is a retrieval-only snapshot of the appointment scheduling metadata from the Salesforce Partial Copy sandbox authenticated locally as `harley-partial`.

No metadata was changed or deployed during retrieval. No Salesforce records were retrieved.

## Source layout

- `force-app/main/default` — Salesforce DX source
- `manifest/package.xml` — targeted retrieval manifest
- `docs/ARCHITECTURE.md` — application structure and workflows
- `docs/METADATA_INVENTORY.md` — retrieved component inventory
- `docs/RETRIEVAL_REPORT.md` — retrieval and security review record

## Deep analysis

- [Product functional design](docs/PRODUCT_FUNCTIONAL_DESIGN.md)
- [Technical design](docs/TECHNICAL_DESIGN.md)
- [End-to-end flows](docs/END_TO_END_FLOWS.md)
- [Object model](docs/OBJECT_MODEL.md)
- [Security review](docs/SECURITY_REVIEW.md)
- [Code quality review](docs/CODE_QUALITY_REVIEW.md)
- [Enhancement backlog](docs/ENHANCEMENT_BACKLOG.md)
- [Component dependency matrix](docs/COMPONENT_DEPENDENCY_MATRIX.md)

## Primary entry points

- `CreateReferralCMP` — appointment/referral booking Aura component
- `Weekly_Availability_Manager` — custom tab exposing `availabilityManager`
- `AppointmentTracking` — `ServiceAppointment__c` after-update trigger
- `AppointmentReschedule` — Event after-update trigger
- `Booking_Screen_Flow_Popup` — active screen flow

The source is preserved as retrieved. It has not been refactored, modernized, or functionally changed.
