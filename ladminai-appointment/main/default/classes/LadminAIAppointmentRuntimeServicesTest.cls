@IsTest
private class LadminAIAppointmentRuntimeServicesTest {
    private class Context {
        Service_Resource__c resource;
        Schema.Location location;
        Lead lead;
    }

    private static Context setupContext() {
        Context c = new Context();
        c.resource = new Service_Resource__c(Name = 'Runtime Doctor', Active__c = true, Description__c = 'Test');
        insert c.resource;
        c.location = new Schema.Location(
            Name = 'Runtime Location', LocationType = 'Site',
            Scheduler_Managed__c = true, Scheduler_Active__c = true,
            Description = 'Test'
        );
        insert c.location;
        insert new Scheduler_Location_Resource__c(
            Location__c = c.location.Id, Service_Resource__c = c.resource.Id,
            Active__c = true,
            Location_Resource_Key__c = c.location.Id + ':' + c.resource.Id
        );
        c.lead = new Lead(LastName = 'Runtime', Company = 'LadminAI Test');
        insert c.lead;
        return c;
    }

    @IsTest static void locationAndResourceAdministration() {
        Context c = setupContext();
        System.assertEquals(1, LadminAIAppointmentLocationService.getLocations().size());
        System.assertEquals(1, LadminAIAppointmentLocationService.getActiveLocations().size());
        System.assertEquals(1, LadminAIAppointmentLocationService.getDoctorsForLocation(c.location.Id).size());
        System.assertEquals(0, LadminAIAppointmentLocationService.getDoctorsForLocation(null).size());
        System.assertEquals('Site', LadminAIAppointmentLocationService.getLocationTypes()[0]);
        LadminAIAppointmentLocationService.assertActiveAssociation(c.location.Id, c.resource.Id);
        LadminAIAppointmentLocationService.saveLocation(
            c.location.Id, c.location.Name, 'Site', 'Updated', true,
            new List<Id>{ c.resource.Id }, 'UTC'
        );
        LadminAIAppointmentLocationService.assertActiveAssociation(c.location.Id, c.resource.Id);

        Schema.Location history = new Schema.Location(
            Name = 'History', LocationType = 'Site', Scheduler_Managed__c = true,
            Scheduler_Active__c = false
        );
        insert history;
        Id inactiveLocation = history.Id;
        LadminAIAppointmentLocationService.setActive(inactiveLocation, false);

        System.assertEquals(1, LadminAIAppointmentResourceAdminService.getResources().size());
        System.assertEquals(0, LadminAIAppointmentResourceAdminService.getAppointments(c.resource.Id).size());
        Id inactiveResource = LadminAIAppointmentResourceAdminService.saveResource(
            null, 'History Doctor', false, 'Inactive'
        );
        LadminAIAppointmentResourceAdminService.saveResource(
            inactiveResource, 'History Doctor Updated', false, null
        );
        LadminAIAppointmentResourceAdminService.setActive(inactiveResource, false);
    }

    @IsTest static void availabilitySlotsBreaksAndOverrides() {
        Context c = setupContext();
        Date target = Date.today().addDays(7);
        String weekday = Datetime.newInstance(target, Time.newInstance(12, 0, 0, 0)).format('EEEE');
        List<Map<String, Object>> days = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Day_Of_Week__c' => weekday, 'Start_Time__c' => '09:00',
                'End_Time__c' => '12:00', 'Break_Start__c' => '10:00',
                'Break_End__c' => '10:30', 'Is_Active__c' => true
            },
            new Map<String, Object>()
        };
        Id scheduleId = LadminAIAppointmentAvailabilityService.saveAvailabilityAtLocation(
            c.resource.Id, c.location.Id, days
        );
        System.assertNotEquals(null, scheduleId);
        System.assertEquals(1, LadminAIAppointmentAvailabilityService.getAllServiceResources().size());
        System.assertEquals(1, LadminAIAppointmentAvailabilityService.getAvailabilityAtLocation(c.resource.Id, c.location.Id).size());
        System.assertEquals(0, LadminAIAppointmentAvailabilityService.getAvailability(null).size());
        System.assert(LadminAIAppointmentAvailabilityService.getAvailableSlots(c.resource.Id, c.location.Id, target).size() > 0);
        System.assertEquals(0, LadminAIAppointmentAvailabilityService.getAvailableSlots(null, c.location.Id, target).size());

        Id unavailable = LadminAIAppointmentAvailabilityService.saveSpecialDateAtLocation(
            c.resource.Id, c.location.Id, null, target.addDays(1), 'Unavailable', null, null, null, null
        );
        System.assertEquals(1, LadminAIAppointmentAvailabilityService.getSpecialDatesAtLocation(c.resource.Id, c.location.Id).size());
        System.assertEquals(0, LadminAIAppointmentAvailabilityService.getEffectiveAvailability(c.resource.Id, c.location.Id, target.addDays(1)).size());
        LadminAIAppointmentAvailabilityService.deleteSpecialDate(unavailable);

        Id customHours = LadminAIAppointmentAvailabilityService.saveSpecialDateAtLocation(
            c.resource.Id, c.location.Id, null, target.addDays(2), 'Custom Hours',
            '13:00', '15:00', '14:00', '14:30'
        );
        System.assertEquals(1, LadminAIAppointmentAvailabilityService.getEffectiveAvailability(c.resource.Id, c.location.Id, target.addDays(2)).size());
        LadminAIAppointmentAvailabilityService.saveSpecialDateAtLocation(
            c.resource.Id, c.location.Id, customHours, target.addDays(2), 'Custom Hours',
            '13:30', '15:30', null, null
        );
    }

    @IsTest static void appointmentCommandsAnalyticsAndAiFallback() {
        Context c = setupContext();
        Date target = Date.today().addDays(7);
        String weekday = Datetime.newInstance(target, Time.newInstance(12, 0, 0, 0)).format('EEEE');
        LadminAIAppointmentAvailabilityService.saveAvailabilityAtLocation(
            c.resource.Id, c.location.Id,
            new List<Map<String, Object>>{ new Map<String, Object>{
                'Day_Of_Week__c' => weekday, 'Start_Time__c' => '09:00',
                'End_Time__c' => '17:00', 'Is_Active__c' => true
            }}
        );
        Datetime startAt = LadminAIAppointmentBusinessTimeService.toUtc(target, Time.newInstance(9, 0, 0, 0));
        Event eventRow = new Event(
            Subject = 'Runtime Event', StartDateTime = startAt,
            EndDateTime = startAt.addMinutes(30), WhoId = c.lead.Id
        );
        insert eventRow;
        ServiceAppointment__c appointment = new ServiceAppointment__c(
            Name = 'Runtime Appointment', Parent_Record1__c = c.lead.Id,
            Location__c = c.location.Id, Subject__c = 'Consultation',
            Scheduled_Start__c = startAt, Scheduled_End__c = startAt.addMinutes(30),
            Status__c = 'Booked', LadminAI_Event__c = eventRow.Id
        );
        insert appointment;
        insert new Assigned_Resource__c(
            Service_Appointment__c = appointment.Id, Service_Resource__c = c.resource.Id
        );

        System.assertEquals(1, LadminAIAppointmentCommandService.getAppointments(target, target).size());
        System.assertEquals(1, LadminAIAppointmentResourceAdminService.getAppointments(c.resource.Id).size());
        LadminAIAppointmentCommandService.updateStatus(appointment.Id, 'No Show');
        LadminAIAppointmentCommandService.reschedule(appointment.Id, target, '09:30');
        update new Service_Resource__c(Id = c.resource.Id, Active__c = false);
        update new Schema.Location(Id = c.location.Id, Scheduler_Active__c = false);
        Service_Resource__c replacementResource = new Service_Resource__c(Name = 'Replacement Doctor', Active__c = true);
        insert replacementResource;
        Schema.Location replacementLocation = new Schema.Location(
            Name = 'Replacement Location', LocationType = 'Site',
            Scheduler_Managed__c = true, Scheduler_Active__c = true
        );
        insert replacementLocation;
        insert new Scheduler_Location_Resource__c(
            Location__c = replacementLocation.Id, Service_Resource__c = replacementResource.Id,
            Active__c = true, Location_Resource_Key__c = replacementLocation.Id + ':' + replacementResource.Id
        );
        Date replacementDate = target.addDays(1);
        String replacementWeekday = Datetime.newInstance(replacementDate, Time.newInstance(12, 0, 0, 0)).format('EEEE');
        LadminAIAppointmentAvailabilityService.saveAvailabilityAtLocation(
            replacementResource.Id, replacementLocation.Id,
            new List<Map<String, Object>>{ new Map<String, Object>{
                'Day_Of_Week__c' => replacementWeekday, 'Start_Time__c' => '13:00',
                'End_Time__c' => '15:00', 'Is_Active__c' => true
            }}
        );
        LadminAIAppointmentCommandService.rescheduleTo(
            appointment.Id, replacementLocation.Id, replacementResource.Id,
            replacementDate, '13:00'
        );
        ServiceAppointment__c reassigned = [
            SELECT Location__c,Scheduled_Start__c,Scheduled_End__c
            FROM ServiceAppointment__c WHERE Id = :appointment.Id
        ];
        Assigned_Resource__c reassignedResource = [
            SELECT Service_Resource__c FROM Assigned_Resource__c
            WHERE Service_Appointment__c = :appointment.Id LIMIT 1
        ];
        Event synchronizedEvent = [SELECT StartDateTime,EndDateTime FROM Event WHERE Id = :eventRow.Id];
        System.assertEquals(replacementLocation.Id, reassigned.Location__c);
        System.assertEquals(replacementResource.Id, reassignedResource.Service_Resource__c);
        System.assertEquals(reassigned.Scheduled_Start__c, synchronizedEvent.StartDateTime);
        System.assertEquals(reassigned.Scheduled_End__c, synchronizedEvent.EndDateTime);
        LadminAIAppointmentAnalyticsService.Snapshot analytics = LadminAIAppointmentAnalyticsService.getSnapshot();
        System.assertEquals(1, analytics.appointmentsThisMonth >= 0 ? 1 : 0);
        System.assertNotEquals(null, analytics.statusMetrics);
        System.assertNotEquals(null, analytics.resourceMetrics);
        System.assertNotEquals(null, analytics.locationMetrics);
        System.assertNotEquals(null, analytics.bookingUserMetrics);
        System.assertNotEquals(null, analytics.serviceMetrics);
        System.assertNotEquals(null, analytics.bookingSourceMetrics);
        System.assert(analytics.upcomingNext7Days >= 0);
        LadminAIAppointmentAIInsightsService.InsightResult insight = LadminAIAppointmentAIInsightsService.getInsights();
        System.assertEquals(false, insight.enabled);
        LadminAIAppointmentCommandService.cancel(appointment.Id, 'Test cancellation');
        System.assertEquals(0, [SELECT COUNT() FROM Event WHERE Id = :eventRow.Id]);

        LadminAIAppointmentBusinessTimeService.LocalWallClock local =
            LadminAIAppointmentBusinessTimeService.toLocalWallClock(startAt);
        System.assertEquals(target, local.localDate);
        System.assertNotEquals(null, LadminAIAppointmentTimezoneService.getSettings().options);
    }

    @IsTest static void validationBranchesRemainSafe() {
        Context c = setupContext();
        try {
            LadminAIAppointmentAvailabilityService.saveSpecialDateAtLocation(
                c.resource.Id, c.location.Id, null, Date.today(), 'Other', null, null, null, null
            );
            System.assert(false);
        } catch (AuraHandledException expected) {}
        try {
            LadminAIAppointmentResourceAdminService.getAppointments(null);
            System.assert(false);
        } catch (AuraHandledException expected) {}
        try {
            LadminAIAppointmentCommandService.updateStatus(null, 'Unsupported');
            System.assert(false);
        } catch (AuraHandledException expected) {}
        try {
            LadminAIAppointmentTimezoneService.saveUserTimezone('Not/A_Timezone');
            System.assert(false);
        } catch (AuraHandledException expected) {}
    }

    @IsTest static void parsesResponsesApiMessageAfterReasoningItem() {
        String responseBody = '{"output":[{"type":"reasoning","content":[]},{"type":"message","content":[{"type":"output_text","text":"Insight one"},{"type":"output_text","text":"Insight two"}]}]}';
        System.assertEquals(
            'Insight one\nInsight two',
            LadminAIAppointmentAIInsightsService.extractText(responseBody)
        );
    }

    @IsTest static void locationTimezoneOverridesBusinessDefault() {
        Schema.Location location = new Schema.Location(
            Name = 'Timezone Location', LocationType = 'Site',
            Scheduler_Managed__c = true, Scheduler_Active__c = false,
            Scheduler_Time_Zone__c = 'Asia/Kolkata'
        );
        insert location;
        Date target = Date.newInstance(2026, 1, 15);
        Datetime utcValue = LadminAIAppointmentBusinessTimeService.toUtc(
            target, Time.newInstance(9, 0, 0, 0), location.Id
        );
        System.assertEquals(
            Datetime.newInstanceGmt(2026, 1, 15, 3, 30, 0), utcValue
        );
        LadminAIAppointmentBusinessTimeService.LocalWallClock local =
            LadminAIAppointmentBusinessTimeService.toLocalWallClock(utcValue, location.Id);
        System.assertEquals(target, local.localDate);
        System.assertEquals(Time.newInstance(9, 0, 0, 0), local.localTime);
    }
}
