# LadminAI Appointment Product Branding

## Product identity

- Product name: **LadminAI Appointment**
- Lightning application label: **LadminAI Appointment**
- Initial landing tab: **Book Appointment**
- Product purpose: an installable Salesforce AppExchange scheduling application

The product is not positioned as a generic healthcare platform, hosted portal, messaging suite, payment platform, subscription system, or AI product.

## Naming standard

| Asset | Convention | Example |
|---|---|---|
| Apex | `LadminAIAppointment...` | `LadminAIAppointmentIBookingParentAdapter` |
| LWC | `ladminAiAppointment...` | `ladminAiAppointmentHome` |
| objects/types | `LadminAI_...` | `LadminAI_Appointment_Settings__mdt` |
| fields | `LadminAI_...` | `LadminAI_Default_Time_Zone__c` |
| permissions | `LadminAI_...` | `LadminAI_Book_Appointment` |
| app/tab | `LadminAI_...` | `LadminAI_Appointment` |

Existing legacy API names are preserved.

## Gate 1 user experience

The application navigation is:

1. Book Appointment
2. Appointments (`Appointment__c`)
3. Service Appointments (`ServiceAppointment__c`)
4. Availability (`Weekly_Availability_Manager`)
5. Service Resources (`Service_Resource__c`)

The new Book Appointment tab is intentionally a static branded landing page. It does not book, reserve, query, update, or synchronize anything. The modern booking experience is delivered in Gate 5.

## Product design principle

New assets must directly improve scheduling quality, security, upgrade safety, packaging, maintainability, performance, or customer usability. Approved extension points remain small until a current product requirement needs them.
