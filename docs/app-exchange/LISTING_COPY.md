# LadminAI Appointment Scheduler — AppExchange Listing Draft

Status: content draft for a separate **FREE** AppExchange listing. This document is not an approval to publish. Items marked **CONFIRM** must be supplied or approved before submission.

## Product identity

- Listing product: **LadminAI Appointment Scheduler**
- Salesforce app label: **LadminAI Smart Appointment**
- Package: independent managed 2GP package `0HoOS00000003Nh0AI`
- Namespace: `LadminAI`
- Validated beta: `1.0.0.6` (`04tOS00000MJ0ndYAD`)
- Price model for this listing: **Free**
- Other LadminAI products: not bundled, not dependencies, and not part of this listing

## Short description

Schedule and manage Salesforce appointments with configurable locations, service resources, availability, calendar synchronization, and operational analytics.

## Detailed description

LadminAI Appointment Scheduler provides an appointment-management workspace inside Salesforce. Administrators configure a business timezone, a location, a doctor or service resource, services, recurring availability, breaks, and special-date overrides. Authorized users can book appointments from Lead records, review schedules, reschedule or cancel appointments, update lifecycle statuses, and view appointment analytics with record-level drilldowns.

Appointments are stored in packaged Salesforce objects and can create linked Salesforce Events for calendar visibility. Permission sets separate booking, configuration, availability, location, resource, and analytics responsibilities. Core scheduling continues to operate when the optional OpenAI integration is not configured.

The default free edition supports a maximum of one active location and one active doctor/service resource. Inactive and historical records remain available. The underlying package retains multi-location and multi-resource architecture, but additional active records are not available in this edition.

## Key features

- Salesforce-native appointment booking from an authorized Lead action
- Location, doctor/service-resource, and service administration
- Recurring resource availability, breaks, holidays, and special-date overrides
- Conflict-aware slot selection and duplicate/overlap protection
- Appointment schedule with search, filters, rescheduling, cancellation, status updates, and safe bulk status updates
- Linked Salesforce Event creation and synchronization/reconciliation support
- Operational dashboard with date filtering, trend metrics, and record-level drilldowns
- Booking-user, service, source, location, resource, and status analytics
- Role-focused access through six packaged permission sets
- Optional read-only AI operational insights using subscriber-provided OpenAI credentials
- Product-neutral package with no Harley, Calendly, Data Search, or Lead Balancer dependency

## Edition limits

The free edition permits:

- 1 active Location
- 1 active Doctor / Service Resource

The package does not delete or unnecessarily block inactive or historical records. Do not add pricing, upgrade, sales, or contact-us messages inside the Salesforce application.

## Prerequisites

- A supported Salesforce org that can install managed 2GP packages and use Lightning Experience
- Lead access for users who launch booking from a Lead
- Salesforce Event access for users whose workflow creates or synchronizes calendar events
- An administrator who can install the package, assign permission sets, and add a quick action to the selected Lead page layout
- Optional AI only: an OpenAI account/API key and permission to configure Salesforce Named Credentials and External Credentials
- Minimum Salesforce edition, contractual support matrix, browser matrix, and any required Salesforce feature licenses: **CONFIRM before listing submission**

## Installation summary

1. Install the released LadminAI Appointment Scheduler package in the target org.
2. Assign only the required packaged permission sets: LadminAI Smart Appointment Booker, Appointment Configurator, Availability Manager, Location Administrator, Resource Administrator, and/or Analytics Viewer.
3. Add the packaged **LadminAI Book Appointment** action to the chosen Lead Lightning/Mobile action section.
4. Open **LadminAI Smart Appointment**, configure the business timezone, then create the active location and active service resource.
5. Assign the resource to the location; create services and configure availability, breaks, holidays, and special-date overrides.
6. Confirm a permitted user can book from a Lead and that the appointment and linked Event are created.
7. Optional: configure the packaged OpenAI External Credential principal and subscriber-owned secret, grant principal access, and enable AI Smart Insights. Never store the key in source or documentation.

See `INSTALLATION_GUIDE.md` for the complete procedure and validation checklist.

## Support details

- Publisher/legal entity: **CONFIRM**
- Support email: **CONFIRM — do not publish a guessed address**
- Support URL: **CONFIRM**
- Documentation URL: **CONFIRM**
- Support hours, timezone, languages, response targets, and escalation process: **CONFIRM**
- End-user license terms URL: **CONFIRM**

## Privacy and security disclosure draft

- Core scheduling stores and processes appointment data in the subscriber's Salesforce org.
- The package enforces user-facing data access through Salesforce sharing plus CRUD/FLS-aware and user-mode operations. Detailed security evidence is maintained separately for review.
- The package contains a Named Credential and External Credential definition for optional OpenAI callouts, but contains no API key, token, or customer secret.
- AI Smart Insights is disabled by default. When an administrator enables and configures it, the package sends aggregated metrics—appointments in the selected period, cancellation rate, and location-level counts—to OpenAI to generate read-only operational suggestions. The inspected implementation does not send appointment subjects, Lead/customer identity, email, or individual appointment rows in this callout.
- Normal booking, availability, appointment management, reporting, reminders, and Event synchronization continue without an OpenAI secret.
- Customer data-processing terms, privacy policy URL, retention statement, subprocessor disclosure, data residency statement, and security contact: **CONFIRM with the publisher before listing submission**.
- Do not claim compliance certifications, encryption guarantees, audits, or regulatory suitability unless the publisher supplies current evidence.

## Suggested listing search terms

Appointment scheduling; Salesforce calendar; service resource scheduling; doctor scheduling; availability; Lead appointment booking; appointment analytics.

These are draft discovery terms, not performance or ranking claims.

## Screenshot plan

No final listing screenshots are evidenced in this repository. Capture current `1.0.0.6` behavior in a clean, non-Harley demonstration org using synthetic data only.

| Order | Screenshot | Required content | Privacy/quality checks |
|---:|---|---|---|
| 1 | App home | LadminAI branding, navigation, readiness summary | No Salesforce org/user/customer identifiers |
| 2 | Appointment booking | Location, resource, service, date, and available-time workflow | Synthetic Lead/customer only; no secrets |
| 3 | Appointment schedule | Filters, compact appointment list, status and actions | Show readable layout without clipped menus |
| 4 | Availability | Weekly hours, break configuration, and special-date/holiday controls | Use synthetic resource and location names |
| 5 | Dashboard | Multicolor metrics/charts and drilldown entry points | Metrics must match displayed synthetic records |
| 6 | Dashboard drilldown | Actual appointment rows, pagination, and export control | No personal/customer production data |
| 7 | Locations/resources | Active location and service-resource administration | Do not imply more than free-edition limits |
| 8 | Optional AI | AI Smart Insights with a safe sample result, only if approved for listing | Never expose API keys or Named Credential secrets |

Before upload, confirm current AppExchange image count, pixel dimensions, file size/type, caption, and accessibility requirements in the Partner Console. Provide descriptive alt text and avoid browser chrome where possible.

## Claims requiring final owner approval

- Product support contact and service levels
- Publisher legal name and country/region
- Privacy policy, terms, and data-processing/subprocessor URLs
- Minimum Salesforce edition and supported browser/device statement
- Final free-edition wording and whether optional OpenAI functionality appears in the initial listing
- Final screenshots, captions, alt text, and demo-video decision
- Any customer quote, adoption number, performance statement, award, or certification
