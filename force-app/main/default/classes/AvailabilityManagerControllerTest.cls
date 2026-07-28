@isTest
private class AvailabilityManagerControllerTest {
    
    // Setup method to create test data
    @TestSetup
    static void setupTestData() {
        // Create a test user
        User testUser = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com'
        );
        insert testUser;

        // Create a Service Resource
        Service_Resource__c sr = new Service_Resource__c(
            Name = 'Test Resource',
            Active__c = true,
            RelatedRecordId__c = testUser.Id
        );
        insert sr;

        // Create a Resource Availability Schedule
        Resource_Availability_Schedule__c schedule = new Resource_Availability_Schedule__c(
            Name = 'Test Resource',
            Service_Resource1__c = sr.Id
        );
        insert schedule;

        // Create a Resource Availability record
        Resource_Availability__c availability = new Resource_Availability__c(
            Name = 'Test Resource - Monday',
            Service_Resource__c = sr.Id,
            Availability_Schedule__c = schedule.Id,
            Day_Of_Week__c = 'Monday',
            Start_Time__c = Time.newInstance(9, 0, 0, 0),
            End_Time__c = Time.newInstance(17, 0, 0, 0),
            Break_Start__c = Time.newInstance(12, 0, 0, 0),
            Break_End__c = Time.newInstance(13, 0, 0, 0),
            Is_Active__c = true,
            Resource_Day_Key__c = schedule.Id + ':Monday'
        );
        insert availability;
    }

    // Test getAllServiceResources method
    @isTest
    static void testGetAllServiceResources() {
        Test.startTest();
        List<Service_Resource__c> resources = AvailabilityManagerController.getAllServiceResources();
        Test.stopTest();

        System.assertNotEquals(0, resources.size(), 'Should return at least one service resource');
        System.assertEquals('Test Resource', resources[0].Name, 'Service resource name should match');
    }

    // Test getMyServiceResource method - Positive case
    @isTest
    static void testGetMyServiceResource() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            Map<String, String> result = AvailabilityManagerController.getMyServiceResource();
            Test.stopTest();

            System.assertNotEquals(0, result.size(), 'Should return a non-empty map');
            System.assertEquals('Test Resource', result.get('Name'), 'Service resource name should match');
            System.assertNotEquals(null, result.get('Id'), 'Service resource Id should be present');
        }
    }

    // Test getMyServiceResource method - Negative case (no related resource)
    @isTest
    static void testGetMyServiceResourceNoMatch() {
        User newUser = new User(
            Alias = 'newuser',
            Email = 'newuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'New',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'newuser' + System.currentTimeMillis() + '@example.com'
        );
        insert newUser;

        System.runAs(newUser) {
            Test.startTest();
            Map<String, String> result = AvailabilityManagerController.getMyServiceResource();
            Test.stopTest();

            System.assertEquals(0, result.size(), 'Should return an empty map when no resource is found');
        }
    }

    // Test getAvailability method - Positive case
    @isTest
    static void testGetAvailability() {
        Service_Resource__c sr = [SELECT Id FROM Service_Resource__c WHERE Name = 'Test Resource' LIMIT 1];

        Test.startTest();
        List<Resource_Availability__c> availabilities = AvailabilityManagerController.getAvailability(sr.Id);
        Test.stopTest();

        System.assertEquals(1, availabilities.size(), 'Should return one availability record');
        System.assertEquals('Monday', availabilities[0].Day_Of_Week__c, 'Day of week should match');
        System.assertEquals(true, availabilities[0].Is_Active__c, 'Availability should be active');
    }

    // Test getAvailability method - Negative case (null serviceResourceId)
    @isTest
    static void testGetAvailabilityNullId() {
        Test.startTest();
        List<Resource_Availability__c> availabilities = AvailabilityManagerController.getAvailability(null);
        Test.stopTest();

        System.assertEquals(0, availabilities.size(), 'Should return an empty list for null serviceResourceId');
    }

    // Test saveAvailabilityV2 method - Positive case (create new)
    @isTest
    static void testSaveAvailabilityV2Create() {
        Service_Resource__c sr = [SELECT Id, Name FROM Service_Resource__c WHERE Name = 'Test Resource' LIMIT 1];

        List<Map<String, Object>> dayRecords = new List<Map<String, Object>>();
        Map<String, Object> dayRecord = new Map<String, Object>{
            'Day_Of_Week__c' => 'Tuesday',
            'Start_Time__c' => '09:00',
            'End_Time__c' => '17:00',
            'Break_Start__c' => '12:00',
            'Break_End__c' => '13:00',
            'Is_Active__c' => true
        };
        dayRecords.add(dayRecord);

        Test.startTest();
        Id scheduleId = AvailabilityManagerController.saveAvailabilityV2(sr.Id, dayRecords);
        Test.stopTest();

        Resource_Availability__c savedAvailability = [
            SELECT Id, Day_Of_Week__c, Start_Time__c, Is_Active__c
            FROM Resource_Availability__c
            WHERE Service_Resource__c = :sr.Id AND Day_Of_Week__c = 'Tuesday'
            LIMIT 1
        ];

        System.assertNotEquals(null, scheduleId, 'Should return a valid schedule Id');
        System.assertNotEquals(null, savedAvailability, 'Should have created an availability record');
        System.assertEquals('Tuesday', savedAvailability.Day_Of_Week__c, 'Day of week should match');
        System.assertEquals(true, savedAvailability.Is_Active__c, 'Availability should be active');
    }

    // Test saveAvailabilityV2 method - Update existing record
    @isTest
    static void testSaveAvailabilityV2Update() {
        Service_Resource__c sr = [SELECT Id, Name FROM Service_Resource__c WHERE Name = 'Test Resource' LIMIT 1];
        Resource_Availability__c existing = [
            SELECT Id, Day_Of_Week__c
            FROM Resource_Availability__c
            WHERE Service_Resource__c = :sr.Id
            LIMIT 1
        ];

        List<Map<String, Object>> dayRecords = new List<Map<String, Object>>();
        Map<String, Object> dayRecord = new Map<String, Object>{
            'Id' => existing.Id,
            'Day_Of_Week__c' => 'Monday',
            'Start_Time__c' => '10:00',
            'End_Time__c' => '18:00',
            'Break_Start__c' => '13:00',
            'Break_End__c' => '14:00',
            'Is_Active__c' => false
        };
        dayRecords.add(dayRecord);

        Test.startTest();
        Id scheduleId = AvailabilityManagerController.saveAvailabilityV2(sr.Id, dayRecords);
        Test.stopTest();

        Resource_Availability__c updatedAvailability = [
            SELECT Id, Start_Time__c, Is_Active__c
            FROM Resource_Availability__c
            WHERE Id = :existing.Id
            LIMIT 1
        ];

        System.assertNotEquals(null, scheduleId, 'Should return a valid schedule Id');
        System.assertEquals(Time.newInstance(10, 0, 0, 0), updatedAvailability.Start_Time__c, 'Start time should be updated');
        System.assertEquals(false, updatedAvailability.Is_Active__c, 'Active flag should be updated');
    }

    // Test saveAvailabilityV2 method - Negative case (null serviceResourceId)
    @isTest
    static void testSaveAvailabilityV2NullId() {
        List<Map<String, Object>> dayRecords = new List<Map<String, Object>>{
            new Map<String, Object>{ 'Day_Of_Week__c' => 'Tuesday' }
        };

        Test.startTest();
        try {
            AvailabilityManagerController.saveAvailabilityV2(null, dayRecords);
            System.assert(false, 'Should have thrown an exception for null serviceResourceId');
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }

    // Test saveAvailabilityV2 method - Negative case (empty dayRecords)
    @isTest
    static void testSaveAvailabilityV2EmptyRecords() {
        Service_Resource__c sr = [SELECT Id FROM Service_Resource__c WHERE Name = 'Test Resource' LIMIT 1];

        Test.startTest();
        Id scheduleId = AvailabilityManagerController.saveAvailabilityV2(sr.Id, null);
        Test.stopTest();

        System.assertNotEquals(null, scheduleId, 'Should return a valid schedule Id even with null dayRecords');
    }
    // Test saveAvailabilityV2 - Cover update branch (schedule name blank)
    @isTest
    static void testSaveAvailabilityV2_UpdateScheduleName() {
        Service_Resource__c sr = [SELECT Id, Name FROM Service_Resource__c WHERE Name = 'Test Resource' LIMIT 1];

        // Make the existing schedule name blank to trigger update logic
        Resource_Availability_Schedule__c existingSchedule = [
            SELECT Id, Name, Service_Resource1__c 
            FROM Resource_Availability_Schedule__c 
            WHERE Service_Resource1__c = :sr.Id 
            LIMIT 1
        ];
        existingSchedule.Name = null;
        update existingSchedule;

        List<Map<String, Object>> dayRecords = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Day_Of_Week__c' => 'Wednesday',
                'Start_Time__c' => '09:00',
                'End_Time__c' => '17:00',
                'Break_Start__c' => '12:00',
                'Break_End__c' => '13:00',
                'Is_Active__c' => true
            }
        };

        Test.startTest();
        Id scheduleId = AvailabilityManagerController.saveAvailabilityV2(sr.Id, dayRecords);
        Test.stopTest();

        // Validate that the blank schedule name got updated
        Resource_Availability_Schedule__c updatedSchedule = [
            SELECT Id, Name FROM Resource_Availability_Schedule__c WHERE Id = :scheduleId
        ];
        System.assertNotEquals(null, updatedSchedule.Name, 'Schedule name should be updated');
    }

    // Test saveAvailabilityV2 - Cover insert branch (no existing schedule)
    @isTest
    static void testSaveAvailabilityV2_InsertNewSchedule() {
        // Create a new Service Resource without a schedule
        User anotherUser = new User(
            Alias = 'auser',
            Email = 'auser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Another',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'auser' + System.currentTimeMillis() + '@example.com'
        );
        insert anotherUser;

        Service_Resource__c srNew = new Service_Resource__c(
            Name = 'Fresh Resource',
            Active__c = true,
            RelatedRecordId__c = anotherUser.Id
        );
        insert srNew;

        // Prepare new day record to trigger schedule creation
        List<Map<String, Object>> dayRecords = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Day_Of_Week__c' => 'Thursday',
                'Start_Time__c' => '08:00',
                'End_Time__c' => '16:00',
                'Break_Start__c' => '12:00',
                'Break_End__c' => '12:30',
                'Is_Active__c' => true
            }
        };

        Test.startTest();
        Id newScheduleId = AvailabilityManagerController.saveAvailabilityV2(srNew.Id, dayRecords);
        Test.stopTest();

        // Verify schedule got inserted
        Resource_Availability_Schedule__c newSchedule = [
            SELECT Id, Name, Service_Resource1__c 
            FROM Resource_Availability_Schedule__c 
            WHERE Id = :newScheduleId
        ];
        System.assertEquals(srNew.Id, newSchedule.Service_Resource1__c, 'Schedule should be linked to the new Service Resource');
    }

    
}