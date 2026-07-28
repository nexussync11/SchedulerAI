@isTest
private class AppointmentTrackingHandlerTest {

    @testSetup
    static void setupData() {

        // Create Lead
        Lead ld = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company'
        );
        insert ld;

        // Create Appointment linked to Lead
        ServiceAppointment__c appt = new ServiceAppointment__c(
            Name = 'Test Appointment',
            Parent_Record1__c = ld.Id,
            Scheduled_Start__c = System.now().addHours(2),
            Status__c = 'Qualified'
        );
        insert appt;
    }

    // ================================
    // 🔁 Test Reschedule
    // ================================
    @isTest
    static void testRescheduleIncrementsCount() {

        ServiceAppointment__c appt = [
            SELECT Id, Scheduled_Start__c, Parent_Record1__c
            FROM ServiceAppointment__c
            LIMIT 1
        ];

        Test.startTest();

        appt.Scheduled_Start__c = System.now().addHours(5);
        update appt;

        Test.stopTest();

        Lead updatedLead = [
            SELECT Reschedule_Count__c
            FROM Lead
            WHERE Id = :appt.Parent_Record1__c
        ];

        System.assertEquals(1, updatedLead.Reschedule_Count__c);
    }

    // ================================
    // 🚫 Test DNA
    // ================================
    @isTest
    static void testDNAIncrementsCount() {

        ServiceAppointment__c appt = [
            SELECT Id, Status__c, Parent_Record1__c
            FROM ServiceAppointment__c
            LIMIT 1
        ];

        Test.startTest();

        appt.Status__c = 'DNA';
        update appt;

        Test.stopTest();

        Lead updatedLead = [
            SELECT DNA_Count__c
            FROM Lead
            WHERE Id = :appt.Parent_Record1__c
        ];

        System.assertEquals(1, updatedLead.DNA_Count__c);
    }

    // ================================
    // 🔁 + 🚫 Both Together
    // ================================
    @isTest
    static void testRescheduleAndDNATogether() {

        ServiceAppointment__c appt = [
            SELECT Id, Scheduled_Start__c, Status__c, Parent_Record1__c
            FROM ServiceAppointment__c
            LIMIT 1
        ];

        Test.startTest();

        appt.Scheduled_Start__c = System.now().addHours(8);
        appt.Status__c = 'DNA';
        update appt;

        Test.stopTest();

        Lead updatedLead = [
            SELECT Reschedule_Count__c, DNA_Count__c
            FROM Lead
            WHERE Id = :appt.Parent_Record1__c
        ];

        System.assertEquals(1, updatedLead.Reschedule_Count__c);
        System.assertEquals(1, updatedLead.DNA_Count__c);
    }

    // ================================
    // 📦 Bulk Scenario
    // ================================
    @isTest
    static void testBulkReschedule() {

        Lead ld = [
            SELECT Id FROM Lead LIMIT 1
        ];

        List<ServiceAppointment__c> appts = new List<ServiceAppointment__c>();

        for(Integer i = 0; i < 5; i++){
            appts.add(new ServiceAppointment__c(
                Name = 'Bulk Appt ' + i,
                Parent_Record1__c = ld.Id,
                Scheduled_Start__c = System.now().addHours(i+2),
                Status__c = 'Qualified'
            ));
        }

        insert appts;

        // Update all to reschedule
        for(ServiceAppointment__c a : appts){
            a.Scheduled_Start__c = System.now().addHours(20);
        }

        Test.startTest();
        update appts;
        Test.stopTest();

        Lead updatedLead = [
            SELECT Reschedule_Count__c
            FROM Lead
            WHERE Id = :ld.Id
        ];

        System.assertEquals(5, updatedLead.Reschedule_Count__c);
    }

    // ================================
    // ❌ No Change Scenario
    // ================================
    @isTest
    static void testNoChangeDoesNotIncrement() {

        ServiceAppointment__c appt = [
            SELECT Id, Scheduled_Start__c, Status__c, Parent_Record1__c
            FROM ServiceAppointment__c
            LIMIT 1
        ];

        Test.startTest();
        update appt; // No changes
        Test.stopTest();

        Lead updatedLead = [
            SELECT Reschedule_Count__c, DNA_Count__c
            FROM Lead
            WHERE Id = :appt.Parent_Record1__c
        ];

        System.assertEquals(null, updatedLead.Reschedule_Count__c);
        System.assertEquals(null, updatedLead.DNA_Count__c);
    }
}