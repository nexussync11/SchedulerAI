@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class LadminAIAppointmentEditionService {
    // Edition counts and activation checks must see every org record, including
    // records hidden from the current user, or the active limits can be bypassed.
    public static final String LOCATION_LIMIT_MESSAGE =
        'Additional active locations are not available in this edition.';
    public static final String RESOURCE_LIMIT_MESSAGE =
        'Additional active service resources are not available in this edition.';

    @AuraEnabled
    public static EditionLimits getLimits() {
        EditionLimits output = new EditionLimits();
        output.maxActiveLocations = configuredLimit(true);
        output.maxActiveServiceResources = configuredLimit(false);
        output.activeLocations = [
            SELECT COUNT() FROM Location
            WHERE Scheduler_Managed__c = true AND Scheduler_Active__c = true
        ];
        output.activeServiceResources = [
            SELECT COUNT() FROM Service_Resource__c WHERE Active__c = true
        ];
        output.canActivateLocation = output.activeLocations < output.maxActiveLocations;
        output.canActivateServiceResource =
            output.activeServiceResources < output.maxActiveServiceResources;
        return output;
    }

    public static void assertLocationActivationAllowed(Id existingId) {
        if (existingId != null) {
            List<Schema.Location> existing = [SELECT Scheduler_Active__c FROM Location WHERE Id=:existingId LIMIT 1];
            if (!existing.isEmpty() && existing[0].Scheduler_Active__c == true) return;
        }
        if (!getLimits().canActivateLocation) throw safe(LOCATION_LIMIT_MESSAGE);
    }

    public static void assertResourceActivationAllowed(Id existingId) {
        if (existingId != null) {
            List<Service_Resource__c> existing = [SELECT Active__c FROM Service_Resource__c WHERE Id=:existingId LIMIT 1];
            if (!existing.isEmpty() && existing[0].Active__c == true) return;
        }
        if (!getLimits().canActivateServiceResource) throw safe(RESOURCE_LIMIT_MESSAGE);
    }

    public static void enforceLocationChanges(
        List<Schema.Location> newRecords,
        Map<Id, Schema.Location> oldRecords
    ) {
        Set<Id> changedIds = new Set<Id>();
        Integer requestedActive = 0;
        List<Schema.Location> activations = new List<Schema.Location>();
        for (Schema.Location recordValue : newRecords) {
            if (recordValue.Id != null) changedIds.add(recordValue.Id);
            Boolean isManagedActive = recordValue.Scheduler_Managed__c == true &&
                recordValue.Scheduler_Active__c == true;
            if (isManagedActive) requestedActive++;
            Boolean wasManagedActive = oldRecords != null && oldRecords.containsKey(recordValue.Id) &&
                oldRecords.get(recordValue.Id).Scheduler_Managed__c == true &&
                oldRecords.get(recordValue.Id).Scheduler_Active__c == true;
            if (isManagedActive && !wasManagedActive) activations.add(recordValue);
        }
        if (activations.isEmpty()) return;
        Integer existingActive = changedIds.isEmpty()
            ? [SELECT COUNT() FROM Location WHERE Scheduler_Managed__c = true AND Scheduler_Active__c = true]
            : [SELECT COUNT() FROM Location WHERE Scheduler_Managed__c = true AND Scheduler_Active__c = true AND Id NOT IN :changedIds];
        if (existingActive + requestedActive <= configuredLimit(true)) return;
        for (Schema.Location recordValue : activations) recordValue.addError(LOCATION_LIMIT_MESSAGE);
    }

    public static void enforceResourceChanges(
        List<Service_Resource__c> newRecords,
        Map<Id, Service_Resource__c> oldRecords
    ) {
        Set<Id> changedIds = new Set<Id>();
        Integer requestedActive = 0;
        List<Service_Resource__c> activations = new List<Service_Resource__c>();
        for (Service_Resource__c recordValue : newRecords) {
            if (recordValue.Id != null) changedIds.add(recordValue.Id);
            Boolean isActive = recordValue.Active__c == true;
            if (isActive) requestedActive++;
            Boolean wasActive = oldRecords != null && oldRecords.containsKey(recordValue.Id) &&
                oldRecords.get(recordValue.Id).Active__c == true;
            if (isActive && !wasActive) activations.add(recordValue);
        }
        if (activations.isEmpty()) return;
        Integer existingActive = changedIds.isEmpty()
            ? [SELECT COUNT() FROM Service_Resource__c WHERE Active__c = true]
            : [SELECT COUNT() FROM Service_Resource__c WHERE Active__c = true AND Id NOT IN :changedIds];
        if (existingActive + requestedActive <= configuredLimit(false)) return;
        for (Service_Resource__c recordValue : activations) recordValue.addError(RESOURCE_LIMIT_MESSAGE);
    }

    public static void enforceCurrentLocationLimit(List<Schema.Location> restoredRecords) {
        if ([SELECT COUNT() FROM Location WHERE Scheduler_Managed__c = true AND Scheduler_Active__c = true] <= configuredLimit(true)) return;
        for (Schema.Location recordValue : restoredRecords) {
            if (recordValue.Scheduler_Managed__c == true && recordValue.Scheduler_Active__c == true) {
                recordValue.addError(LOCATION_LIMIT_MESSAGE);
            }
        }
    }

    public static void enforceCurrentResourceLimit(List<Service_Resource__c> restoredRecords) {
        if ([SELECT COUNT() FROM Service_Resource__c WHERE Active__c = true] <= configuredLimit(false)) return;
        for (Service_Resource__c recordValue : restoredRecords) {
            if (recordValue.Active__c == true) recordValue.addError(RESOURCE_LIMIT_MESSAGE);
        }
    }

    private static Integer configuredLimit(Boolean locationLimit) {
        LadminAI_Appointment_Settings__mdt settings = LadminAI_Appointment_Settings__mdt.getInstance('Default');
        Decimal value = locationLimit ? settings?.LadminAI_Max_Active_Locations__c
            : settings?.LadminAI_Max_Active_Service_Resources__c;
        return value == null ? 1 : Math.max(0, value.intValue());
    }
    private static AuraHandledException safe(String message) {
        AuraHandledException output = new AuraHandledException(message); output.setMessage(message); return output;
    }
    public class EditionLimits {
        @AuraEnabled public Integer maxActiveLocations;
        @AuraEnabled public Integer maxActiveServiceResources;
        @AuraEnabled public Integer activeLocations;
        @AuraEnabled public Integer activeServiceResources;
        @AuraEnabled public Boolean canActivateLocation;
        @AuraEnabled public Boolean canActivateServiceResource;
    }
}
