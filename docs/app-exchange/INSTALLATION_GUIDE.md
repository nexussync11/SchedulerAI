# LadminAI Appointment Scheduler Installation Guide

This guide applies to the independently packaged **LadminAI Appointment Scheduler** managed 2GP product (`0HoOS00000003Nh0AI`, namespace `LadminAI`). It does not apply to LadminAI Data Search or LadminAI Lead Balancer.

## Before installation

Confirm the following before installing:

- A Salesforce org using Lightning Experience. The validated test configuration used an Enterprise Edition scratch org; compatibility with other editions must be confirmed before the public listing is finalized.
- A Salesforce administrator who can install packages, assign permission sets, edit Lead page layouts, and configure Named and External Credentials.
- The Lead object is enabled for users who will launch booking from a Lead.
- The release installation URL and installation key are supplied through an approved secure channel. The validated artifact at the time this guide was prepared is beta `1.0.0.6` (`04tOS00000MJ0ndYAD`); do not use that beta as a production release unless it is formally promoted and approved.
- An OpenAI API key is needed only if the optional AI Smart Insights feature will be enabled. Core scheduling works without OpenAI.

No Harley metadata, Data Search package, Lead Balancer package, Calendly configuration, or customer secret is required.

## Install the package

1. Sign in to the intended subscriber org as an administrator.
2. Open the installation URL supplied for the approved release.
3. Enter the installation key when prompted.
4. Review the requested access and install for the intended administrators or according to the organization's package-installation policy.
5. Wait for Salesforce to report that installation completed.
6. In **Setup > Installed Packages**, confirm **LadminAI Appointment Scheduler** is present with namespace `LadminAI`.

## Assign the six packaged permission sets

Assign only the capabilities each user needs. In **Setup > Permission Sets**, open a permission set, select **Manage Assignments**, and add the relevant users.

| Permission set label | API name | Intended use |
|---|---|---|
| LadminAI Appointment Configurator | `LadminAI_Appointment_Configurator` | Configure business/user timezones and application settings; intended for the Scheduler administrator. |
| LadminAI Location Administrator | `LadminAI_Location_Administrator` | Create, edit, activate, deactivate, and assign Scheduler-managed Salesforce Locations. |
| LadminAI Resource Administrator | `LadminAI_Resource_Administrator` | Manage doctors/service resources and the service catalog. |
| LadminAI Availability Manager | `LadminAI_Availability_Manager` | Configure recurring availability, breaks, holidays, and special-date overrides. |
| LadminAI Smart Appointment Booker | `LadminAI_Appointment_Booker` | View slots, book from the app or Lead action, and manage permitted appointment operations. |
| LadminAI Analytics Viewer | `LadminAI_Analytics_Viewer` | View appointment dashboards, drilldowns, operational analytics, and optional AI insights. |

For initial administrator setup and verification, one test administrator can temporarily receive all six permission sets. Production users should receive the minimum set required for their role. The package does not assign permission sets automatically.

## Configure the Scheduler

1. From the App Launcher, open **LadminAI Smart Appointment**.
2. Open **Settings** and choose the **Business timezone**. Save it. Appointment DateTimes remain stored in UTC; scheduling calculations use the selected business timezone.
3. Optionally choose the current user's Salesforce display timezone.
4. Open **Locations** and create or activate a Scheduler-managed Location.
5. Open **Doctors / Resources** and create or activate a doctor/service resource.
6. Assign the resource to the active Location.
7. Optionally open **Services** and create active appointment services, durations, buffers, and resource/location eligibility.
8. Open **Resource Availability**, select the Location and resource, add weekly working hours, and add any break. Use **Special dates** for holidays or custom hours.
9. Return to **Home** or **Settings** and confirm all five readiness checks are complete: business timezone, active location, active resource, active assignment, and availability.
10. Use **Appointment Booking** to confirm that future slots are displayed.

The default free edition permits one active Location and one active doctor/service resource. Inactive and historical records remain available. Additional active records are rejected with the product's edition-limit message.

## Add the Lead booking action

The package includes `Lead.LadminAI_Book_Appointment_Action`. It deliberately does not replace a subscriber's Lead page layout.

1. Open **Setup > Object Manager > Lead > Page Layouts**.
2. Edit each Lead layout used by appointment-booking users.
3. In **Salesforce Mobile and Lightning Experience Actions**, add the packaged **Book Appointment** action.
4. Save the layout.
5. Open a Lead as a user assigned **LadminAI Smart Appointment Booker** and confirm **Book Appointment** is visible.

If Dynamic Actions are used on the Lead Lightning record page, expose the packaged action there according to the organization's normal Lightning App Builder policy.

## Optional OpenAI setup

The package includes the Named Credential **LadminAI OpenAI** (`LadminAI_OpenAI`) and External Credential **LadminAI OpenAI Authentication** (`LadminAI_OpenAI_External`). It never includes an API key or customer secret.

Core scheduling must be configured and tested before enabling AI.

1. Open **Setup > Named Credentials > External Credentials**.
2. Open **LadminAI OpenAI Authentication**.
3. Configure its named principal **LadminAI OpenAI Principal**.
4. Add the subscriber-owned `api_key` authentication parameter using the OpenAI key. Store the value only in Salesforce credential storage; never put it in source control, documentation, screenshots, or support messages.
5. Create or choose a subscriber-managed permission set for users allowed to invoke the principal.
6. In that permission set, add **External Credential Principal Access** for **LadminAI OpenAI Principal**.
7. Also assign those users the packaged **LadminAI Analytics Viewer** permission set.
8. In the Scheduler, open **Settings**, enable **AI Smart Insights**, and save.
9. Open **AI Smart Insights** and select **Refresh**.

If the credential is absent, invalid, or disabled, AI insights display an unavailable message; booking, availability, appointment management, reporting, reminders, and Event synchronization remain operational.

## Optional notifications and scheduled jobs

- Internal and customer appointment emails are disabled by default and can be enabled separately in **Settings**.
- Customer reminder processing uses `LadminAIAppointmentReminderScheduler`. If reminders are required, the subscriber administrator must schedule it under an authorized integration/operations user in accordance with the organization's job-monitoring policy.
- Event reconciliation uses `LadminAIEventReconciliationService`. If periodic Event repair is required, schedule it under an appropriately authorized operations user and monitor scheduled jobs and failure fields.

The exact job cadence is an organization decision and is not automatically imposed by this guide.

## Installation verification

As appropriately permissioned users, verify:

1. The app opens and only authorized administration areas are visible.
2. One Location and one resource can be activated and assigned.
3. Weekly availability and a break save successfully; past times are not offered for booking.
4. A Lead appointment can be booked and creates a `ServiceAppointment__c`, an `Assigned_Resource__c`, and—when configured—the linked Salesforce Event.
5. The appointment appears in **Appointment Schedule** and **Salesforce Calendar**.
6. Rescheduling, status changes, and cancellation update the appointment and Event appropriately.
7. Dashboard values and drilldown rows reflect the created record.
8. Core functionality remains usable when AI is not configured.

## Troubleshooting boundaries

- A missing Lead action is normally a page-layout or Dynamic Actions configuration issue; repeat the Lead action steps above.
- Empty slot lists normally indicate a missing active Location/resource assignment, availability, service eligibility, date override, or a date outside configured booking rules.
- AI authorization failures should be resolved in the subscriber's External Credential principal and permission set; never send an API key to application support.
- Use **Operational Health** to review readiness, integrity indicators, and effective app permissions.

## Items requiring confirmation before publication

- Public support contact, support hours, escalation path, and privacy-policy URL.
- Minimum supported Salesforce editions and any license prerequisites beyond the validated Enterprise Edition configuration.
- Released package version, installation URL, and secure distribution procedure for any installation key.
- Recommended production schedules for reminders and Event reconciliation.
