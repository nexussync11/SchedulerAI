@IsTest
private class LadminAIAppointmentBookingServiceTest {
    private class TestContext {
        User bookingUser;
        Lead parentLead;
        Service_Resource__c resource;
        Schema.Location bookingLocation;
    }

    @IsTest
    static void booksAppointmentAtomically() {
        User bookingUser = createUser(true);
        System.runAs(bookingUser) {
            TestContext context = createContext(bookingUser);
            LadminAIAppointmentBookingRequest request =
                validRequest(context, System.now().addDays(2));

            Test.startTest();
            LadminAIAppointmentBookingResult result =
                LadminAIAppointmentBookingController.bookAppointment(request);
            Test.stopTest();

            System.assertEquals(true, result.success);
            System.assertNotEquals(null, result.appointmentId);
            System.assertNotEquals(null, result.eventId);
            System.assertNotEquals(null, result.assignedResourceId);
            System.assert(result.bookingReference.startsWith('LA-'));

            ServiceAppointment__c appointment = [
                SELECT Parent_Record1__c, Scheduled_Start__c,
                    Scheduled_End__c, Status__c, LadminAI_Idempotency_Key__c
                FROM ServiceAppointment__c
                WHERE Id = :result.appointmentId
            ];
            System.assertEquals(context.parentLead.Id, appointment.Parent_Record1__c);
            System.assertEquals('Open', appointment.Status__c);
            System.assertEquals(request.idempotencyKey, appointment.LadminAI_Idempotency_Key__c);
        }
    }

    @IsTest
    static void rejectsMissingMandatoryFields() {
        LadminAIAppointmentBookingRequest request =
            new LadminAIAppointmentBookingRequest();

        LadminAIAppointmentBookingResult result =
            LadminAIAppointmentBookingService.bookAppointment(request);

        System.assertEquals(false, result.success);
        System.assertEquals('VALIDATION_FAILED', result.errorCode);
        System.assert(result.fieldErrors.size() >= 8);
        System.assertEquals(0, [SELECT COUNT() FROM ServiceAppointment__c]);
    }

    @IsTest
    static void rejectsInvalidDateTimeRange() {
        User bookingUser = createUser(true);
        System.runAs(bookingUser) {
            TestContext context = createContext(bookingUser);
            Datetime startTime = System.now().addDays(2);
            LadminAIAppointmentBookingRequest request = validRequest(context, startTime);
            request.requestedEnd = startTime.addMinutes(-30);

            LadminAIAppointmentBookingResult result =
                LadminAIAppointmentBookingService.bookAppointment(request);

            System.assertEquals(false, result.success);
            System.assertEquals('VALIDATION_FAILED', result.errorCode);
            System.assertEquals(0, [SELECT COUNT() FROM ServiceAppointment__c]);
        }
    }

    @IsTest
    static void rejectsOverlappingAppointment() {
        User bookingUser = createUser(true);
        System.runAs(bookingUser) {
            TestContext context = createContext(bookingUser);
            Datetime startTime = System.now().addDays(2);
            createExistingAppointment(context, startTime, startTime.addMinutes(30));
            LadminAIAppointmentBookingRequest request =
                validRequest(context, startTime.addMinutes(15));

            LadminAIAppointmentBookingResult result =
                LadminAIAppointmentBookingService.bookAppointment(request);

            System.assertEquals(false, result.success);
            System.assertEquals('SLOT_CONFLICT', result.errorCode);
            System.assertEquals(1, result.conflicts.size());
            System.assertEquals(1, [SELECT COUNT() FROM ServiceAppointment__c]);
        }
    }

    @IsTest
    static void returnsExistingBookingForRepeatedKey() {
        User bookingUser = createUser(true);
        System.runAs(bookingUser) {
            TestContext context = createContext(bookingUser);
            LadminAIAppointmentBookingRequest request =
                validRequest(context, System.now().addDays(2));

            LadminAIAppointmentBookingResult firstResult =
                LadminAIAppointmentBookingService.bookAppointment(request);
            LadminAIAppointmentBookingResult replayResult =
                LadminAIAppointmentBookingService.bookAppointment(request);

            System.assertEquals(true, firstResult.success);
            System.assertEquals(
                true,
                replayResult.success,
                'Replay failed with ' + replayResult.errorCode
            );
            System.assertEquals(true, replayResult.idempotentReplay);
            System.assertEquals(firstResult.appointmentId, replayResult.appointmentId);
            System.assertEquals(firstResult.bookingReference, replayResult.bookingReference);
            System.assertEquals(1, [
                SELECT COUNT()
                FROM ServiceAppointment__c
                WHERE LadminAI_Idempotency_Key__c = :request.idempotencyKey
            ]);
        }
    }

    @IsTest
    static void rollsBackWhenRelatedOperationFails() {
        User bookingUser = createUser(true);
        System.runAs(bookingUser) {
            TestContext context = createContext(bookingUser);
            LadminAIAppointmentBookingRequest request =
                validRequest(context, System.now().addDays(2));

            Test.startTest();
            LadminAIAppointmentBookingService.failAfterAppointmentInsertForTest = true;
            LadminAIAppointmentBookingResult result =
                LadminAIAppointmentBookingService.bookAppointment(request);
            LadminAIAppointmentBookingService.failAfterAppointmentInsertForTest = false;
            Test.stopTest();

            System.assertEquals(false, result.success);
            System.assertEquals('RELATED_OPERATION_FAILED', result.errorCode);
            System.assertEquals(0, [
                SELECT COUNT()
                FROM ServiceAppointment__c
                WHERE LadminAI_Idempotency_Key__c = :request.idempotencyKey
            ]);
            System.assertEquals(0, [SELECT COUNT() FROM Assigned_Resource__c]);
            System.assertEquals(0, [SELECT COUNT() FROM Event]);
        }
    }

    @IsTest
    static void rejectsUserWithoutBookingPermission() {
        User unauthorizedUser = createUser(false);
        System.runAs(unauthorizedUser) {
            Lead parentLead = new Lead(
                LastName = 'Unauthorized Context',
                Company = 'LadminAI Test'
            );
            insert parentLead;
            Datetime startTime = System.now().addDays(2);
            LadminAIAppointmentBookingRequest request =
                new LadminAIAppointmentBookingRequest();
            request.parentRecordId = parentLead.Id;
            request.serviceResourceId = parentLead.Id;
            request.locationId = parentLead.Id;
            request.appointmentDate = startTime.date();
            request.requestedStart = startTime;
            request.requestedEnd = startTime.addMinutes(30);
            request.bookingSource = firstActiveValue(
                ServiceAppointment__c.Appointment_Mode__c
            );
            request.bookingStatus = 'Booked';
            request.subject = 'Consultation';
            request.idempotencyKey = 'unauthorized-request';

            LadminAIAppointmentBookingResult result =
                LadminAIAppointmentBookingService.bookAppointment(request);

            System.assertEquals(false, result.success);
            System.assertEquals('AUTHORIZATION_REQUIRED', result.errorCode);
            System.assertEquals(0, [SELECT COUNT() FROM ServiceAppointment__c]);
        }
    }

    @IsTest
    static void processesBoundedBatchWithoutLimitGrowth() {
        User bookingUser = createUser(true);
        System.runAs(bookingUser) {
            TestContext context = createContext(bookingUser);
            Datetime firstStart = System.now().addDays(2);
            List<LadminAIAppointmentBookingRequest> requests =
                new List<LadminAIAppointmentBookingRequest>();
            for (Integer indexValue = 0; indexValue < 3; indexValue++) {
                LadminAIAppointmentBookingRequest request =
                    validRequest(context, firstStart.addMinutes(indexValue * 60));
                request.idempotencyKey += '-' + indexValue;
                requests.add(request);
            }

            Test.startTest();
            List<LadminAIAppointmentBookingResult> results =
                LadminAIAppointmentBookingController.bookAppointments(requests);
            Test.stopTest();

            System.assertEquals(3, results.size());
            for (LadminAIAppointmentBookingResult result : results) {
                System.assertEquals(true, result.success);
            }
            System.assertEquals(3, [SELECT COUNT() FROM ServiceAppointment__c]);
            System.assertEquals(3, [SELECT COUNT() FROM Assigned_Resource__c]);
        }
    }

    @IsTest
    static void keepsApprovedAdapterExtensionPointLightweight() {
        LadminAIAppointmentIBookingParentAdapter adapter =
            new LadminAIAppointmentLeadParentAdapter();
        System.assertNotEquals(null, adapter);
    }

    private static User createUser(Boolean assignBookingPermission) {
        User currentUser = [
            SELECT ProfileId, TimeZoneSidKey, LocaleSidKey,
                EmailEncodingKey, LanguageLocaleKey
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
        String uniqueValue = String.valueOf(Crypto.getRandomLong()).replace('-', '0');
        User testUser = new User(
            Alias = ('la' + uniqueValue).left(8),
            Email = 'ladminai-' + uniqueValue + '@example.com',
            EmailEncodingKey = currentUser.EmailEncodingKey,
            LastName = 'Booking User',
            LanguageLocaleKey = currentUser.LanguageLocaleKey,
            LocaleSidKey = currentUser.LocaleSidKey,
            ProfileId = currentUser.ProfileId,
            TimeZoneSidKey = currentUser.TimeZoneSidKey,
            Username = 'ladminai-' + uniqueValue + '@example.com'
        );
        insert testUser;
        if (assignBookingPermission) {
            PermissionSet bookingPermission = [
                SELECT Id
                FROM PermissionSet
                WHERE Name = 'LadminAI_Appointment_Booker'
                LIMIT 1
            ];
            insert new PermissionSetAssignment(
                AssigneeId = testUser.Id,
                PermissionSetId = bookingPermission.Id
            );
        }
        return testUser;
    }

    private static TestContext createContext(User bookingUser) {
        TestContext context = new TestContext();
        context.bookingUser = bookingUser;
        context.parentLead = new Lead(
            LastName = 'Booking Context',
            Company = 'LadminAI Test'
        );
        insert as system context.parentLead;
        context.resource = new Service_Resource__c(
            Name = 'Test Resource',
            Active__c = true
        );
        insert as system context.resource;
        context.bookingLocation = new Schema.Location(
            Name = 'Test Location', LocationType = 'Site',
            Scheduler_Active__c = true, Scheduler_Managed__c = true
        );
        insert as system context.bookingLocation;
        insert as system new Scheduler_Location_Resource__c(
            Location__c = context.bookingLocation.Id,
            Service_Resource__c = context.resource.Id,
            Active__c = true,
            Location_Resource_Key__c = context.bookingLocation.Id + ':' + context.resource.Id
        );
        return context;
    }

    private static LadminAIAppointmentBookingRequest validRequest(
        TestContext context,
        Datetime startTime
    ) {
        LadminAIAppointmentBookingRequest request =
            new LadminAIAppointmentBookingRequest();
        request.parentRecordId = context.parentLead.Id;
        request.serviceResourceId = context.resource.Id;
        request.locationId = context.bookingLocation.Id;
        request.appointmentDate = startTime.date();
        request.requestedStart = startTime;
        request.requestedEnd = startTime.addMinutes(30);
        request.bookingSource = firstActiveValue(
            ServiceAppointment__c.Appointment_Mode__c
        );
        request.bookingStatus = 'Booked';
        request.subject = 'Consultation';
        request.idempotencyKey =
            'test-' + String.valueOf(Crypto.getRandomLong()).replace('-', '0');
        return request;
    }

    private static void createExistingAppointment(
        TestContext context,
        Datetime startTime,
        Datetime endTime
    ) {
        ServiceAppointment__c appointment = new ServiceAppointment__c(
            Name = 'Existing Appointment',
            Parent_Record1__c = context.parentLead.Id,
            Scheduled_Start__c = startTime,
            Scheduled_End__c = endTime,
            Status__c = 'Open'
        );
        insert appointment;
        insert new Assigned_Resource__c(
            Service_Appointment__c = appointment.Id,
            Service_Resource__c = context.resource.Id
        );
    }

    private static String firstActiveValue(Schema.SObjectField fieldToken) {
        for (Schema.PicklistEntry entry : fieldToken.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                return entry.getValue();
            }
        }
        System.assert(false, 'Expected an active picklist value for test setup.');
        return null;
    }
}
