@IsTest private class LadminAIAppointmentReadinessServiceTest {
    @IsTest static void reportsIncompleteAndCompleteSetup() {
        LadminAIAppointmentReadinessService.Readiness empty = LadminAIAppointmentReadinessService.getReadiness();
        System.assertEquals(false, empty.bookingReady);
        Service_Resource__c resource = new Service_Resource__c(Name='Ready Resource',Active__c=true); insert resource;
        Schema.Location location = new Schema.Location(Name='Ready Location',LocationType='Site',Scheduler_Managed__c=true,Scheduler_Active__c=true); insert location;
        insert new Scheduler_Location_Resource__c(Location__c=location.Id,Service_Resource__c=resource.Id,Active__c=true,Location_Resource_Key__c=location.Id+':'+resource.Id);
        insert new Resource_Availability__c(Name='Ready Monday',Service_Resource__c=resource.Id,Location__c=location.Id,Day_Of_Week__c='Monday',Start_Time__c=Time.newInstance(9,0,0,0),End_Time__c=Time.newInstance(17,0,0,0),Is_Active__c=true,Resource_Day_Key__c='ready-monday');
        LadminAIAppointmentReadinessService.Readiness ready = LadminAIAppointmentReadinessService.getReadiness();
        System.assertEquals(true, ready.bookingReady);
        System.assertEquals(5, ready.completedSteps);
    }
}
