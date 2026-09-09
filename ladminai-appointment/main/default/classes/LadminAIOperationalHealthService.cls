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
        Datetime integrityStart = System.now().addDays(-30), integrityEnd = System.now().addDays(180);
        List<Assigned_Resource__c> scheduledAssignments = [
            SELECT Service_Resource__c, Service_Appointment__c,
                   Service_Appointment__r.Scheduled_Start__c, Service_Appointment__r.Scheduled_End__c,
                   Service_Appointment__r.Status__c, Service_Appointment__r.LadminAI_Event__c
            FROM Assigned_Resource__c
            WHERE Service_Appointment__r.Scheduled_Start__c >= :integrityStart
              AND Service_Appointment__r.Scheduled_Start__c < :integrityEnd
              AND Service_Appointment__r.Status__c NOT IN ('Cancelled','Cancel')
            WITH USER_MODE ORDER BY Service_Resource__c, Service_Appointment__r.Scheduled_Start__c LIMIT 5000
        ];
        snapshot.integrityScanLimited = scheduledAssignments.size() == 5000;
        snapshot.overlappingAppointments = 0; snapshot.eventSynchronizationMismatches = 0;
        Set<Id> eventIds = new Set<Id>();
        for (Assigned_Resource__c assignment : scheduledAssignments) if (assignment.Service_Appointment__r.LadminAI_Event__c != null) eventIds.add(assignment.Service_Appointment__r.LadminAI_Event__c);
        Map<Id,Event> eventsById = eventIds.isEmpty() ? new Map<Id,Event>() : new Map<Id,Event>([SELECT Id,StartDateTime,EndDateTime FROM Event WHERE Id IN :eventIds WITH USER_MODE]);
        Map<Id,Datetime> latestEndByResource = new Map<Id,Datetime>();
        for (Assigned_Resource__c assignment : scheduledAssignments) {
            Datetime startAt = assignment.Service_Appointment__r.Scheduled_Start__c, endAt = assignment.Service_Appointment__r.Scheduled_End__c;
            Datetime latestEnd = latestEndByResource.get(assignment.Service_Resource__c);
            if (latestEnd != null && startAt < latestEnd) snapshot.overlappingAppointments++;
            if (endAt != null && (latestEnd == null || endAt > latestEnd)) latestEndByResource.put(assignment.Service_Resource__c, endAt);
            Event linkedEvent = eventsById.get(assignment.Service_Appointment__r.LadminAI_Event__c);
            if (linkedEvent != null && (linkedEvent.StartDateTime != startAt || linkedEvent.EndDateTime != endAt)) snapshot.eventSynchronizationMismatches++;
        }
        snapshot.healthy = snapshot.canConfigure && snapshot.activeLocations > 0 && snapshot.activeResources > 0 && snapshot.activeAssignments > 0 && snapshot.activeAvailabilityRows > 0 && snapshot.activeResourcesWithoutAvailability == 0 && snapshot.overlappingAppointments == 0 && snapshot.eventSynchronizationMismatches == 0;
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
        @AuraEnabled public Integer overlappingAppointments;
        @AuraEnabled public Integer eventSynchronizationMismatches;
        @AuraEnabled public Boolean integrityScanLimited;
    }
}
