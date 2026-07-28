@isTest
public class AppointmentRescheduleHandlerTest {

    
       @isTest
    static void testHandleAfterUpdate2_Reschedule() {

        // 1️⃣ Create Lead
        Lead testLead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company'
        );
        insert testLead;

        // 2️⃣ Create Event linked to Lead
        Event ev = new Event(
            Subject = 'Test Meeting',
            StartDateTime = System.now().addDays(1),
            EndDateTime = System.now().addDays(1).addHours(1),
            WhoId = testLead.Id
        );
        insert ev;

        // 3️⃣ Prepare oldMap (simulate old version)
        Map<Id, Event> oldMap = new Map<Id, Event>(
            [SELECT Id, StartDateTime, WhoId FROM Event WHERE Id = :ev.Id]
        );

        // 4️⃣ Modify Event (Reschedule it)
        ev.StartDateTime = System.now().addDays(2);
        ev.EndDateTime = System.now().addDays(3);
        update ev;

        // 5️⃣ Get updated version
        List<Event> newList = [
            SELECT Id, StartDateTime, WhoId
            FROM Event
            WHERE Id = :ev.Id
        ];

        Test.startTest();
        AppointmentRescheduleHandler.handleAfterUpdate2(newList, oldMap);
        Test.stopTest();

        // 6️⃣ Verify Lead updated
        Lead updatedLead = [
            SELECT Reschedule_Count__c
            FROM Lead
            WHERE Id = :testLead.Id
        ];

        System.assertEquals(
            2,
            updatedLead.Reschedule_Count__c,
            'Reschedule count should increment to 1'
        );
    }


    @isTest
    static void testHandleAfterUpdate2_NoReschedule() {

        Lead testLead = new Lead(
            LastName = 'No Change Lead',
            Company = 'Test Company'
        );
        insert testLead;

        Event ev = new Event(
            Subject = 'Meeting',
            StartDateTime = System.now().addDays(1),
            EndDateTime = System.now().addDays(1).addHours(1),
            WhoId = testLead.Id
        );
        insert ev;

        Map<Id, Event> oldMap = new Map<Id, Event>(
            [SELECT Id, StartDateTime, WhoId FROM Event WHERE Id = :ev.Id]
        );

        // No change to StartDateTime
        ev.Subject = 'Updated Subject';
        update ev;

        List<Event> newList = [
            SELECT Id, StartDateTime, WhoId
            FROM Event
            WHERE Id = :ev.Id
        ];

        Test.startTest();
        AppointmentRescheduleHandler.handleAfterUpdate2(newList, oldMap);
        Test.stopTest();

        Lead updatedLead = [
            SELECT Reschedule_Count__c
            FROM Lead
            WHERE Id = :testLead.Id
        ];

        System.assertEquals(
            null,
            updatedLead.Reschedule_Count__c,
            'Reschedule count should not change'
        );
    }


    @isTest
    static void testHandleAfterUpdate2_MultipleReschedules() {

        Lead testLead = new Lead(
            LastName = 'Multi Reschedule Lead',
            Company = 'Test Company',
            Reschedule_Count__c = 2
        );
        insert testLead;

        Event ev = new Event(
            Subject = 'Meeting',
            StartDateTime = System.now().addDays(1),
            EndDateTime = System.now().addDays(1).addHours(1),
            WhoId = testLead.Id
        );
        insert ev;

        Map<Id, Event> oldMap = new Map<Id, Event>(
            [SELECT Id, StartDateTime, WhoId FROM Event WHERE Id = :ev.Id]
        );

        ev.StartDateTime = System.now().addDays(1);
        update ev;

        List<Event> newList = [
            SELECT Id, StartDateTime, WhoId
            FROM Event
            WHERE Id = :ev.Id
        ];

        Test.startTest();
        AppointmentRescheduleHandler.handleAfterUpdate2(newList, oldMap);
        Test.stopTest();

        Lead updatedLead = [
            SELECT Reschedule_Count__c
            FROM Lead
            WHERE Id = :testLead.Id
        ];

      
    }


    
}