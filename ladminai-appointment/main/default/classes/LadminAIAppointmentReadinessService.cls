public with sharing class LadminAIAppointmentReadinessService {
    @AuraEnabled(cacheable=true)
    public static Readiness getReadiness() {
        Readiness result = new Readiness();
        result.businessTimezone = LadminAIAppointmentSettingsService.businessTimeZone();
        result.activeLocations = [SELECT COUNT() FROM Location WHERE Scheduler_Managed__c=true AND Scheduler_Active__c=true WITH USER_MODE];
        result.activeResources = [SELECT COUNT() FROM Service_Resource__c WHERE Active__c=true WITH USER_MODE];
        result.activeAssociations = [SELECT COUNT() FROM Scheduler_Location_Resource__c WHERE Active__c=true AND Location__r.Scheduler_Active__c=true AND Service_Resource__r.Active__c=true WITH USER_MODE];
        result.activeAvailabilityRows = [SELECT COUNT() FROM Resource_Availability__c WHERE Is_Active__c=true AND Service_Resource__r.Active__c=true WITH USER_MODE];
        result.timezoneReady = String.isNotBlank(result.businessTimezone);
        result.locationReady = result.activeLocations > 0;
        result.resourceReady = result.activeResources > 0;
        result.assignmentReady = result.activeAssociations > 0;
        result.availabilityReady = result.activeAvailabilityRows > 0;
        result.bookingReady = result.timezoneReady && result.locationReady && result.resourceReady && result.assignmentReady && result.availabilityReady;
        result.completedSteps = 0;
        for (Boolean ready : new List<Boolean>{result.timezoneReady,result.locationReady,result.resourceReady,result.assignmentReady,result.availabilityReady}) if (ready) result.completedSteps++;
        return result;
    }
    public class Readiness {
        @AuraEnabled public String businessTimezone;
        @AuraEnabled public Integer activeLocations;
        @AuraEnabled public Integer activeResources;
        @AuraEnabled public Integer activeAssociations;
        @AuraEnabled public Integer activeAvailabilityRows;
        @AuraEnabled public Integer completedSteps;
        @AuraEnabled public Boolean timezoneReady;
        @AuraEnabled public Boolean locationReady;
        @AuraEnabled public Boolean resourceReady;
        @AuraEnabled public Boolean assignmentReady;
        @AuraEnabled public Boolean availabilityReady;
        @AuraEnabled public Boolean bookingReady;
    }
}
