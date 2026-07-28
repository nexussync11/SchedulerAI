# Architecture

## Overview

The application is an Aura/Apex scheduling implementation backed primarily by custom objects. `CreateReferralCMP` provides appointment booking and calls `Createappointmentreferralcontroller`. `availabilityManager` provides weekly resource availability administration and calls `AvailabilityManagerController`.

```mermaid
flowchart LR
    U[Scheduler user] --> B[CreateReferralCMP]
    B --> BC[Createappointmentreferralcontroller]
    BC --> L[Lead]
    BC --> E[Event]
    BC --> SA[ServiceAppointment__c]
    BC --> AR[Assigned_Resource__c]
    BC --> SR[Service_Resource__c]
    BC --> AV[Resource_Availability__c]
    A[Availability administrator] --> AM[availabilityManager]
    AM --> AMC[AvailabilityManagerController]
    AMC --> SR
    AMC --> AS[Resource_Availability_Schedule__c]
    AMC --> AV
```

## Booking workflow

1. `CreateReferralCMP` receives record context and booking inputs.
2. Lookup helper components select a `Service_Resource__c`.
3. `Createappointmentreferralcontroller` reads weekly availability and existing appointments.
4. The controller creates a `ServiceAppointment__c`, an Event, and an `Assigned_Resource__c`, and updates the related Lead.
5. Active flows synchronize appointment data and ownership to Lead records.

```mermaid
sequenceDiagram
    actor User
    participant Aura as CreateReferralCMP
    participant Apex as Createappointmentreferralcontroller
    participant Availability as Resource_Availability__c
    participant Appointment as ServiceAppointment__c
    participant Event
    participant Lead
    User->>Aura: Select resource and date
    Aura->>Apex: Check availability
    Apex->>Availability: Read weekly hours and breaks
    Apex-->>Aura: Return open time slots
    User->>Aura: Save selected slot
    Aura->>Apex: Create booking
    Apex->>Appointment: Insert appointment
    Apex->>Event: Insert calendar event
    Apex->>Lead: Update referral/booking data
```

## Doctor/resource allocation

Doctors or schedulable staff are represented by `Service_Resource__c`, linked to a Salesforce User through `RelatedRecordId__c`. `Assigned_Resource__c` joins a resource to `ServiceAppointment__c`. Availability is held by `Resource_Availability_Schedule__c` and its daily `Resource_Availability__c` rows.

## Tracking and rescheduling

- `AppointmentTracking` invokes `AppointmentTrackingHandler` after a `ServiceAppointment__c` update. It increments Lead reschedule and DNA counters.
- `AppointmentReschedule` invokes `AppointmentRescheduleHandler` after an Event update. It increments the related Lead reschedule counter when the start time changes.

## Object model

```mermaid
erDiagram
    LEAD ||--o{ APPOINTMENT__C : has
    LEAD ||--o{ SERVICEAPPOINTMENT__C : parent
    SERVICE_RESOURCE__C ||--o{ ASSIGNED_RESOURCE__C : assigned
    SERVICEAPPOINTMENT__C ||--o{ ASSIGNED_RESOURCE__C : receives
    SERVICE_RESOURCE__C ||--o{ RESOURCE_AVAILABILITY_SCHEDULE__C : owns
    RESOURCE_AVAILABILITY_SCHEDULE__C ||--o{ RESOURCE_AVAILABILITY__C : contains
    SERVICE_RESOURCE__C ||--o{ RESOURCE_AVAILABILITY__C : provides
```

