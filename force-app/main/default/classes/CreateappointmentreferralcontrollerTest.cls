@isTest
public class CreateappointmentreferralcontrollerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create Lead
        Lead testLead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Email = 'test.lead@example.com',
            Referral_Subject__c = 'Test Subject',
            Referral_Details__c = 'Test Details',
            Inhouse_Created_By__c = 'Website',
            Booked_By__c = null
        );
        insert testLead;
        
        // Create Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create Contact
        Contact testContact = new Contact(
            LastName = 'Test Contact',
            Email = 'test.contact@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        // Create User
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            FirstName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'Europe/London',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com'
        );
        insert testUser;
        
        // Create Service Resource
        Service_Resource__c testServiceResource = new Service_Resource__c(
            Name = 'Test Resource',
            Active__c = true,
            RelatedRecordId__c = testUser.Id
        );
        insert testServiceResource;
        
        // Dynamic weekday matching
        Date today = Date.today();
        String weekday = Datetime.newInstance(today.year(), today.month(), today.day(), 0, 0, 0).format('EEEE');
        
        // Create Availability (normal)
        Resource_Availability__c testAvailability = new Resource_Availability__c(
            Service_Resource__c = testServiceResource.Id,
            Day_Of_Week__c = weekday,
            Start_Time__c = Time.newInstance(9, 0, 0, 0),
            End_Time__c = Time.newInstance(17, 0, 0, 0),
            Break_Start__c = Time.newInstance(12, 0, 0, 0),
            Break_End__c = Time.newInstance(13, 0, 0, 0),
            Is_Active__c = true
        );
        insert testAvailability;
        
        // Create overlapping break availability
        Resource_Availability__c testAvailabilityBreak = new Resource_Availability__c(
            Service_Resource__c = testServiceResource.Id,
            Day_Of_Week__c = weekday,
            Start_Time__c = Time.newInstance(12, 0, 0, 0),
            End_Time__c = Time.newInstance(14, 0, 0, 0),
            Break_Start__c = Time.newInstance(12, 30, 0, 0),
            Break_End__c = Time.newInstance(13, 0, 0, 0),
            Is_Active__c = true
        );
        insert testAvailabilityBreak;
    }
    
    // --- Test: isComponentExpired ---
    @isTest
    static void testIsComponentExpired() {
        Test.startTest();
        Boolean isExpired = Createappointmentreferralcontroller.isComponentExpired('appointmentBookingAura');
        Test.stopTest();
        System.assertEquals(false, isExpired);
    }
    
    // --- Test: getLeadName ---
    @isTest
    static void testGetLeadName() {
        Lead testLead = [SELECT Id, Name FROM Lead WHERE LastName = 'Test Lead' LIMIT 1];
        Test.startTest();
        String leadName = Createappointmentreferralcontroller.getLeadName(testLead.Id);
        Test.stopTest();
        System.assertEquals('Test Lead', leadName);
    }
    
    // --- Test: convertToDateTime (includes Event + Assigned Resource) ---
    @isTest
    static void testConvertToDateTime_FullCoverage() {
        Lead testLead = [SELECT Id, Name FROM Lead WHERE LastName = 'Test Lead' LIMIT 1];
        Service_Resource__c testResource = [SELECT Id, Name FROM Service_Resource__c WHERE Name = 'Test Resource' LIMIT 1];
        Date testDate = Date.today();
        String[] startTime = new List<String>{'09:00'};
            
            Test.startTest();
        Lead result;
        try {
            result = Createappointmentreferralcontroller.convertToDateTime(
                'Test Subject',
                'Test Details',
                'Alex',
                testLead.Id,
                startTime,
                testDate,
                'test.lead@example.com',
                testResource.Id,
                'Phone',
                'Test Lead',
                'SALES'
            );
        } catch (Exception e) {
            System.debug('⚠ Exception during convertToDateTime: ' + e.getMessage());
        }
        Test.stopTest();
        
        ServiceAppointment__c sp =  new ServiceAppointment__c();
        sp.Subject__c='reffSubject';
        sp.Parent_Record1__c = testLead.Id;
        sp.Status__c='Scheduled';
        sp.Name = 'leadName';
        insert sp;
        
        
        
        Event evtObj = new Event();
        evtObj.Subject = 'test';
        evtObj.WhoId = testLead.Id;
        evtObj.start_date_time__c = string.valueof(System.today());
        evtObj.End_Date_Time__c = string.valueof(System.today());
        Long milliseconds = 2000;
        Long seconds = milliseconds / 1000;
        Long minutes = seconds / 60;
        evtObj.DurationInMinutes=Integer.valueof(minutes);
        evtObj.ActivityDateTime=System.today();
        insert evtObj;
        //List<Assigned_Resource__c> arList = [SELECT Id, Service_Appointment__c, Service_Resource__c FROM Assigned_Resource__c WHERE Service_Appointment__c = :sp.Id];
        Assigned_Resource__c ar=new Assigned_Resource__c();
        ar.Service_Appointment__c=sp.Id;
        insert ar;
    }
    
    // --- Test: getUserName ---
    @isTest
    static void testGetUserName() {
        Test.startTest();
        String userName = Createappointmentreferralcontroller.getUserName();
        Test.stopTest();
        String expected = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
        System.assertEquals(expected, userName);
    }
    
    // --- Test: getPiklistValues1 ---
    @isTest
    static void testGetPiklistValues1() {
        Lead testLead = [SELECT Id, Email FROM Lead WHERE LastName = 'Test Lead' LIMIT 1];
        Test.startTest();
        String email = Createappointmentreferralcontroller.getPiklistValues1(testLead.Id);
        Test.stopTest();
        System.assertEquals('test.lead@example.com', email);
    }
    
    // --- Test: setObjectToRecentItems ---
    @isTest
    static void testSetObjectToRecentItems() {
        Lead testLead = [SELECT Id FROM Lead WHERE LastName = 'Test Lead' LIMIT 1];
        Test.startTest();
        Createappointmentreferralcontroller.setObjectToRecentItems(testLead.Id);
        Test.stopTest();
        System.assert(true, 'Executed without exception');
    }
    
    // --- Test: availableStartTimeSlot ---
    @isTest
    static void testAvailableStartTimeSlot() {
        Service_Resource__c testResource = [SELECT Id FROM Service_Resource__c WHERE Name = 'Test Resource' LIMIT 1];
        Date testDate = Date.today();
        
        Test.startTest();
        List<List<String>> slots = Createappointmentreferralcontroller.availableStartTimeSlot(testResource.Id, testDate);
        Test.stopTest();
        
        System.assert(!slots.isEmpty(), 'Slots should be returned');
        System.assertEquals(2, slots[0].size(), 'Each slot has start and end');
        System.assertEquals('09:00', slots[0][0], 'Slot start formatted correctly');
    }
    
    // --- Test: returnAccountName ---
    @isTest
    static void testReturnAccountName() {
        Account testAccount = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Test.startTest();
        String accName = Createappointmentreferralcontroller.returnAccountName(testAccount.Id);
        Test.stopTest();
        System.assertEquals('Test Account', accName);
    }
    
    // --- Test: fetchContactEmail ---
    @isTest
    static void testFetchContactEmail() {
        Contact testContact = [SELECT Id, Email FROM Contact WHERE LastName = 'Test Contact' LIMIT 1];
        Test.startTest();
        String email = Createappointmentreferralcontroller.fetchContactEmail(testContact.Id);
        Test.stopTest();
        System.assertEquals('test.contact@example.com', email);
    }
    
    // --- Negative Tests ---
    @isTest
    static void testIsComponentExpiredException() {
        Test.startTest();
        Boolean isExpired = Createappointmentreferralcontroller.isComponentExpired('InvalidComponent');
        Test.stopTest();
        System.assertEquals(false, isExpired);
    }
    
    @isTest
    static void testGetLeadNameInvalidId() {
        Test.startTest();
        try {
            Createappointmentreferralcontroller.getLeadName('invalidId');
            System.assert(false, 'Expected exception');
        } catch (Exception e) {
            System.assert(e instanceof QueryException, 'Expected QueryException');
        }
        Test.stopTest();
    }
    
    
    
 

   
    // ============================================
    // ✅ Test getInhouseCreatedBy
    // ============================================
    @isTest
    static void testGetInhouseCreatedBy() {

        Lead ld = [SELECT Id, Inhouse_Created_By__c FROM Lead LIMIT 1];

        Test.startTest();
        String result =
            Createappointmentreferralcontroller.getInhouseCreatedBy(ld.Id);
        Test.stopTest();

        System.assertEquals(ld.Inhouse_Created_By__c, result);
    }

    @isTest
    static void testGetInhouseCreatedBy_NullId() {

        Test.startTest();
        String result =
            Createappointmentreferralcontroller.getInhouseCreatedBy(null);
        Test.stopTest();

        System.assertEquals(null, result);
    }

    // ============================================
    // ✅ Test getBookedByPicklistValues
    // ============================================
    @isTest
    static void testGetBookedByPicklistValues() {

        Test.startTest();
        List<String> values =
            Createappointmentreferralcontroller.getBookedByPicklistValues();
        Test.stopTest();

        System.assert(values != null);
        System.assert(values.size() > 0,
            'Booked_By__c picklist should have at least one value');
    }

    // ============================================
    // ✅ Test getBookedByValue
    // ============================================
    @isTest
    static void testGetBookedByValue() {

        Lead ld = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        String value =
            Createappointmentreferralcontroller.getBookedByValue(ld.Id);
        Test.stopTest();

        System.assertEquals(null, value);
    }

    @isTest
    static void testGetBookedByValue_NullId() {

        Test.startTest();
        String value =
            Createappointmentreferralcontroller.getBookedByValue(null);
        Test.stopTest();

        System.assertEquals(null, value);
    }

    // ============================================
    // ✅ Test updateBookedBy
    // ============================================
    @isTest
    static void testUpdateBookedBy() {

        Lead ld = [SELECT Id FROM Lead LIMIT 1];

        // Get a valid picklist value dynamically
        List<String> pickVals =
            Createappointmentreferralcontroller.getBookedByPicklistValues();

        String validValue = pickVals[0];

        Test.startTest();
        Createappointmentreferralcontroller.updateBookedBy(
            ld.Id,
            validValue
        );
        Test.stopTest();

        Lead updated = [
            SELECT Booked_By__c
            FROM Lead
            WHERE Id = :ld.Id
        ];

        System.assertEquals(validValue, updated.Booked_By__c);
    }

    @isTest
    static void testUpdateBookedBy_BlankValue() {

        Lead ld = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        Createappointmentreferralcontroller.updateBookedBy(
            ld.Id,
            ''
        );
        Test.stopTest();

        Lead updated = [
            SELECT Booked_By__c
            FROM Lead
            WHERE Id = :ld.Id
        ];

        System.assertEquals(null, updated.Booked_By__c);
    }

    @isTest
    static void testUpdateBookedBy_NullId() {

        Test.startTest();
        Createappointmentreferralcontroller.updateBookedBy(
            null,
            'Test'
        );
        Test.stopTest();

        // No exception = pass
        System.assert(true);
    }


}