@IsTest
private class LadminAIOperationalHealthServiceTest {
    @IsTest static void reportsConfigurationAndDataHealth() {
        Service_Resource__c resource = new Service_Resource__c(Name='Health Resource', Active__c=true); insert resource;
        Schema.Location location = new Schema.Location(Name='Health Location', LocationType='Site', Scheduler_Managed__c=true, Scheduler_Active__c=true); insert location;
        insert new Scheduler_Location_Resource__c(Location__c=location.Id, Service_Resource__c=resource.Id, Active__c=true, Location_Resource_Key__c=location.Id+':'+resource.Id);
        LadminAIOperationalHealthService.HealthSnapshot result = LadminAIOperationalHealthService.getHealth();
        System.assertEquals(1, result.activeLocations); System.assertEquals(1, result.activeResources); System.assertEquals(1, result.activeAssignments);
        System.assertEquals(1, result.activeResourcesWithoutAvailability); System.assertNotEquals(null, result.checkedAt); System.assertNotEquals(null, result.businessTimezone);
    }
}
