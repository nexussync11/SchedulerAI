public with sharing class LadminAIOperationalHealthService {
    @AuraEnabled(cacheable=true)
    public static HealthSnapshot getHealth() {
        HealthSnapshot snapshot = new HealthSnapshot();
        snapshot.checkedAt = System.now();
        snapshot.businessTimezone = LadminAIAppointmentSettingsService.businessTimeZone();
        snapshot.canConfigure = FeatureManagement.checkPermission('LadminAI_Configure_Appointment');
        snapshot.canBook = FeatureManagement.checkPermission('LadminAI_Book_Appointment');
        snapshot.canManageResources = FeatureManagement.checkPermission('LadminAI_Manage_Resources');
        snapshot.activeLocations = [SELECT COUNT() FROM Location WHERE Scheduler_Managed__c=true AND Scheduler_Active__c=true WITH USER_MODE];
        snapshot.activeResources = [SELECT COUNT() FROM Service_Resource__c WHERE Active__c=true WITH USER_MODE];
        snapshot.activeAssignments = [SELECT COUNT() FROM Scheduler_Location_Resource__c WHERE Active__c=true WITH USER_MODE];
        snapshot.activeAvailabilityRows = [SELECT COUNT() FROM Resource_Availability__c WHERE Is_Active__c=true WITH USER_MODE];
        snapshot.appointmentsLast30Days = [SELECT COUNT() FROM ServiceAppointment__c WHERE Scheduled_Start__c=LAST_N_DAYS:30 WITH USER_MODE];
        snapshot.appointmentsMissingEvents = [SELECT COUNT() FROM ServiceAppointment__c WHERE LadminAI_Event__c=null AND Status__c NOT IN ('Cancelled','Cancel') WITH USER_MODE];
        Set<Id> scheduledResourceIds = new Set<Id>();
        for (Resource_Availability__c row : [SELECT Service_Resource__c FROM Resource_Availability__c WHERE Is_Active__c=true AND Service_Resource__c != null WITH USER_MODE]) scheduledResourceIds.add(row.Service_Resource__c);
        snapshot.activeResourcesWithoutAvailability = [SELECT COUNT() FROM Service_Resource__c WHERE Active__c=true AND Id NOT IN :scheduledResourceIds WITH USER_MODE];
        snapshot.healthy = snapshot.canConfigure && snapshot.activeLocations > 0 && snapshot.activeResources > 0 && snapshot.activeAssignments > 0 && snapshot.activeAvailabilityRows > 0 && snapshot.activeResourcesWithoutAvailability == 0;
        return snapshot;
    }
    public class HealthSnapshot {
        @AuraEnabled public Datetime checkedAt;
        @AuraEnabled public String businessTimezone;
        @AuraEnabled public Boolean canConfigure;
        @AuraEnabled public Boolean canBook;
        @AuraEnabled public Boolean canManageResources;
        @AuraEnabled public Boolean healthy;
        @AuraEnabled public Integer activeLocations;
        @AuraEnabled public Integer activeResources;
        @AuraEnabled public Integer activeAssignments;
        @AuraEnabled public Integer activeAvailabilityRows;
        @AuraEnabled public Integer appointmentsLast30Days;
        @AuraEnabled public Integer appointmentsMissingEvents;
        @AuraEnabled public Integer activeResourcesWithoutAvailability;
    }
}
