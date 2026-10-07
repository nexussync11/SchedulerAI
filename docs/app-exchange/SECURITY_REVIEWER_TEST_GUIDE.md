# LadminAI Appointment Scheduler Security Reviewer Test Guide

## Product and artifact

| Item | Value |
|---|---|
| Product | LadminAI Appointment Scheduler |
| Managed 2GP package | `0HoOS00000003Nh0AI` |
| Namespace | `LadminAI` |
| Validated beta | `1.0.0.6` |
| Validated beta version ID | `04tOS00000MJ0ndYAD` |
| Package relationships | Independent; no Data Search or Lead Balancer dependency or ancestry |

The version submitted for review must be confirmed at submission time. Do not promote, release, or submit the beta named above solely because it is listed in this guide.

## Reviewer org and credentials status

No dedicated security-review org or reusable reviewer credentials are documented in this repository. The files under `config/users` are scratch-org user templates with `example.test` addresses, not reviewer accounts, and contain no usable credentials. No reviewer username, password, API key, or installation key is stored in source.

Before submission, the publisher must create or designate a dedicated non-Harley reviewer org and provide credentials through Salesforce's approved security-review channel. That action requires owner approval and is outside this documentation pass.

## Required reviewer access

Prepare at least these personas:

1. **Scheduler reviewer administrator**: a non-production administrator able to install the package, assign permission sets, edit a Lead layout, configure Named/External Credentials, inspect records, and schedule jobs. Assign all six packaged Scheduler permission sets for end-to-end feature testing.
2. **Authorized booking user**: a non-admin user assigned **LadminAI Smart Appointment Booker** and only the additional Scheduler capabilities needed for the scenario.
3. **Unauthorized user**: a non-admin user without Scheduler permission sets, used to confirm denied operations.
4. **Optional analytics user**: a non-admin user assigned **LadminAI Analytics Viewer**. For AI testing, also grant the subscriber-configured External Credential principal through a subscriber-managed permission set.

Six packaged permission sets:

- LadminAI Appointment Configurator
- LadminAI Location Administrator
- LadminAI Resource Administrator
- LadminAI Availability Manager
- LadminAI Smart Appointment Booker
- LadminAI Analytics Viewer

Do not place API keys or other secrets in this guide or in sample records.

## Minimum sample data

Create only synthetic data in the dedicated reviewer org:

- One Lead: `Security Review Patient`, with a non-sensitive test email address if email behavior will be tested.
- One active Location: `Security Review Clinic`, Scheduler managed, with the selected business timezone.
- One active doctor/service resource: `Security Review Resource`.
- One active Location-resource assignment.
- One active service: `Security Review Consultation`, duration 30 minutes, zero or small buffers.
- Weekly availability on at least one future weekday, for example 09:00–17:00 with a 12:00–13:00 break.
- One future holiday/special-date override and one custom-hours override on another future date.
- At least one future appointment and, when dashboard history is needed, a small number of synthetic past appointments with varied statuses.

The default edition limit is one active Location and one active resource. Reuse those records throughout the review; inactive/historical records can remain.

## Test sequence

### 1. Installation and identity

1. Install the submitted Scheduler version in the dedicated non-Harley org using the securely supplied installation key.
2. Confirm **LadminAI Appointment Scheduler** is independently installed with namespace `LadminAI`.
3. Confirm no Data Search, Lead Balancer, Harley, Calendly, or legacy appointment package is required.
4. Assign all six permission sets to the reviewer administrator.
5. Open **LadminAI Smart Appointment** from the App Launcher.

Expected: installation and launch succeed; LadminAI branding appears; no external credential is required for core navigation.

### 2. Settings and readiness

1. Open **Settings**.
2. Select and save the business timezone.
3. Leave AI insights disabled and leave the OpenAI secret unconfigured.
4. Review the five readiness checks.

Expected: timezone saves; the incomplete setup steps are clearly identified; no AI-related error prevents normal use.

### 3. Location and edition guardrail

1. Open **Locations** and create/activate two Locations, including `Security Review Clinic`.
2. Create an additional inactive Location if desired.
3. Attempt to activate the third Location.

Expected: the first two Locations work; inactive/history records are not unnecessarily blocked; a third active Location is rejected with exactly `Additional active locations are not available in this edition.`

### 4. Resource and edition guardrail

1. Open **Doctors / Resources** and create/activate five resources, including `Security Review Resource`.
2. Attempt to activate a sixth resource.
3. Assign an active resource to `Security Review Clinic`.

Expected: the first five resources and assignments work; inactive/history records are not unnecessarily blocked; a sixth active resource is rejected with exactly `Additional active service resources are not available in this edition.`

### 5. Service catalog

1. Open **Services** and create `Security Review Consultation` with a 30-minute duration.
2. Optionally restrict eligibility to the active Location and resource.
3. Edit the record and confirm the change.

Expected: the service appears as active and can be selected during booking. CSV import/export can be tested with synthetic rows only; exported columns must not be renamed or reordered before re-import.

### 6. Availability, breaks, and special dates

1. Open **Resource Availability**.
2. Select the Location and resource.
3. Configure weekly hours and a break, then save.
4. Add a future `Unavailable / Holiday` date range.
5. Add a separate future `Custom Hours` override.
6. Check available slots for ordinary, break, holiday, and custom-hours dates.

Expected: ordinary slots are returned inside working hours; break times, holidays, and past times are absent; custom hours replace normal hours for that date. Missing Location/resource selection produces guidance instead of a silent failure.

### 7. Lead action and booking

1. In **Setup > Object Manager > Lead > Page Layouts**, add the packaged **Book Appointment** action to the reviewer's Lead layout under **Salesforce Mobile and Lightning Experience Actions**.
2. Open `Security Review Patient` and launch the action.
3. Choose the Location, service/resource, future date, and available time; book the appointment.
4. Inspect the created records.

Expected: booking succeeds and creates one `ServiceAppointment__c`, one related `Assigned_Resource__c`, and—when Event creation remains enabled—one linked Salesforce Event. The Lead action is packaged but the subscriber's full Lead layout is not replaced.

### 8. Conflict and authorization controls

1. Attempt to book the same resource for the same time again.
2. As the unauthorized user, attempt the secured booking operation.

Expected: overlapping booking is rejected; the unauthorized user cannot book or access secured administration operations. Granting no Scheduler permission must not expose protected data or allow DML.

### 9. Appointment management and Event synchronization

1. Open **Appointment Schedule**.
2. Find the new appointment, open it, and reschedule to a different available future slot.
3. Change status through a permitted lifecycle value.
4. Cancel an appointment with a configured reason.
5. Inspect the linked Event after each applicable change.

Expected: appointment and Event times remain synchronized; status/cancellation changes persist; unavailable or overlapping slots cannot be selected. Event sync status/error/attempt fields record reconciliation state without exposing secrets.

### 10. Calendar, reporting, and drilldowns

1. Open **Salesforce Calendar** and confirm the appointment Event is visible.
2. Open **Reports & Dashboard**.
3. Apply preset and custom date filters.
4. Select a KPI, status, Location, resource, service, booking user, or source result.
5. Review the appointment list at the end of the page and its pagination; export selected report data if needed.

Expected: totals match the synthetic appointments and the drilldown contains the actual matching records. Date, permission, and sharing filters are honored.

### 11. Notifications, reminders, and reconciliation

1. Keep customer and internal emails disabled and confirm booking still works.
2. If notification testing is in review scope, use only the synthetic Lead email, enable the relevant setting, and exercise booking/reschedule/cancel.
3. Run `LadminAIAppointmentReminderScheduler` in a controlled test window or invoke its covered test path.
4. Modify/delete a synthetic linked Event and run `LadminAIEventReconciliationService` in the test org.

Expected: notification features are opt-in; reminder/reconciliation code processes only eligible synthetic records; missing or changed Events are repaired or record a bounded failure status. Normal scheduling does not depend on these jobs.

### 12. Optional AI callout

Core review can be completed with AI disabled. If the reviewer elects to test AI:

1. In **Setup > Named Credentials > External Credentials**, configure **LadminAI OpenAI Authentication** and its **LadminAI OpenAI Principal** with a reviewer-owned test key in Salesforce credential storage.
2. Grant principal access through a subscriber-managed permission set and assign **LadminAI Analytics Viewer**.
3. Enable AI in **Settings** and refresh **AI Smart Insights**.

Expected: insights are read-only and based on aggregated appointment metrics. With no or invalid credential, the UI reports that insights are unavailable while core scheduling remains unaffected. Remove the reviewer-owned secret after testing.

### 13. Permission and uninstall checks

1. Re-test selected pages with the intended individual persona permission set instead of all six.
2. Confirm an unpermissioned user is denied.
3. Remove test data as required, then uninstall the package from the dedicated review org.

Expected: persona access is capability-based; uninstall completes without an unexpected unmanaged dependency.

## Evidence to capture

- Installed package details showing product, namespace, and submitted version.
- Permission-set assignments for each test persona.
- Readiness screen and synthetic setup records.
- Booking result and related appointment/resource/Event records.
- Conflict and unauthorized-access outcomes.
- Reschedule/status/cancellation and Event synchronization outcomes.
- Dashboard totals and matching drilldowns.
- Optional AI fallback or successful callout without revealing the key.
- Apex test result and coverage supplied with the security-review evidence set.
- Uninstall result from an isolated org.

## Publisher actions still required

- Confirm the exact promoted version ID submitted for review.
- Obtain approval to create/designate the dedicated reviewer org and reviewer personas.
- Generate reviewer credentials and transfer them only through Salesforce's approved submission fields; do not commit them.
- Provide the installation key through the approved private submission channel.
- Confirm whether optional AI callout testing will be enabled and, if so, who owns the temporary reviewer key.
- Confirm support contacts and the reviewer escalation contact.
