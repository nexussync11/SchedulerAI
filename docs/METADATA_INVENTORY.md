# Metadata Inventory

## Apex classes (8)

- `AppointmentRescheduleHandler`
- `AppointmentRescheduleHandlerTest`
- `AppointmentTrackingHandler`
- `AppointmentTrackingHandlerTest`
- `AvailabilityManagerController`
- `AvailabilityManagerControllerTest`
- `Createappointmentreferralcontroller`
- `CreateappointmentreferralcontrollerTest`

## Apex triggers (2)

- `AppointmentReschedule` on Event
- `AppointmentTracking` on `ServiceAppointment__c`

## Aura bundles (5)

- `CreateReferralCMP`
- `Referralcomponentevent`
- `availabilityManager`
- `customLookup`
- `lookupreferralcomponent`

No Lightning Web Components were identified as part of this application.

## Flows (9)

- `Appointment_Data_to_map_to_lead` — Active
- `Booking_Screen_Flow_Popup` — Active
- `Changed_appointment` — Draft
- `Did_Lead_Attend_Appointment` — Active
- `SDR_Booking_Screen_Pop_Up_Trigger` — InvalidDraft
- `Send_Appointment_Booked_SMS` — Obsolete
- `Send_Appointment_Booked_SMS_1` — Obsolete
- `Send_Appointment_Reminder_SMS` — Obsolete
- `Update_Lead_Owner_to_Appointment_Owner` — Active

## Objects

Core custom objects:

- `Appointment__c`
- `Assigned_Resource__c`
- `Mapping__c`
- `RequestResource__c`
- `Resource_Availability__c`
- `Resource_Availability_Schedule__c`
- `Service_Resource__c`
- `ServiceAppointment__c`

Supporting metadata and standard-object extensions:

- `Component_Config__mdt`
- selected Event custom fields
- selected Lead custom fields

All fields, list views, validation rules, and other child metadata returned with the targeted custom objects are stored under their object directories.

## User access and navigation

- Permission set: `BookingAppointment`
- Custom tabs: the eight custom-object tabs plus `Weekly_Availability_Manager`
- Custom metadata record: `Component_Config.appointmentBookingAura`

## Not present in the targeted application

- Lightning Web Components
- Visualforce pages/components
- identifiable scheduling Lightning app or FlexiPage
- scheduling-specific Named Credentials, Remote Site Settings, email templates, or static resources
- permission set groups

