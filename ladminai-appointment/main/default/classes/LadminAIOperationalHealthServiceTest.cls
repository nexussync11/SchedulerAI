@IsTest
private class LadminAIOperationalHealthServiceTest {
    @IsTest static void reportsConfigurationAndDataHealth() {
        Service_Resource__c resource = new Service_Resource__c(Name='Health Resource', Active__c=true); insert resource;
        Schema.Location location = new Schema.Location(Name='Health Location', LocationType='Site', Scheduler_Managed__c=true, Scheduler_Active__c=true); insert location;
        insert new Scheduler_Location_Resource__c(Location__c=location.Id, Service_Resource__c=resource.Id, Active__c=true, Location_Resource_Key__c=location.Id+':'+resource.Id);
        Lead lead = new Lead(LastName='Health',Company='Test'); insert lead;
        Datetime startAt = System.now().addDays(1);
        Event firstEvent = new Event(Subject='Health event',WhoId=lead.Id,StartDateTime=startAt.addMinutes(5),EndDateTime=startAt.addMinutes(35)); insert firstEvent;
        List<ServiceAppointment__c> appointments = new List<ServiceAppointment__c>{
            new ServiceAppointment__c(Name='Health 1',Subject__c='Health',Parent_Record1__c=lead.Id,Location__c=location.Id,Scheduled_Start__c=startAt,Scheduled_End__c=startAt.addMinutes(30),Status__c='Open',LadminAI_Event__c=firstEvent.Id),
            new ServiceAppointment__c(Name='Health 2',Subject__c='Health',Parent_Record1__c=lead.Id,Location__c=location.Id,Scheduled_Start__c=startAt.addMinutes(15),Scheduled_End__c=startAt.addMinutes(45),Status__c='Open')
        }; insert appointments;
        insert new List<Assigned_Resource__c>{new Assigned_Resource__c(Service_Appointment__c=appointments[0].Id,Service_Resource__c=resource.Id),new Assigned_Resource__c(Service_Appointment__c=appointments[1].Id,Service_Resource__c=resource.Id)};
        LadminAIOperationalHealthService.HealthSnapshot result = LadminAIOperationalHealthService.getHealth();
        System.assertEquals(1, result.activeLocations); System.assertEquals(1, result.activeResources); System.assertEquals(1, result.activeAssignments);
        System.assertEquals(1, result.activeResourcesWithoutAvailability); System.assertNotEquals(null, result.checkedAt); System.assertNotEquals(null, result.businessTimezone);
        System.assertEquals(1, result.overlappingAppointments); System.assertEquals(1, result.eventSynchronizationMismatches); System.assertEquals(false,result.integrityScanLimited);
    }
}
