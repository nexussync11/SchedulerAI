public without sharing class LadminAIAppointmentEditionService {
    public static final String LOCATION_LIMIT_MESSAGE =
        'Additional active locations are not available in this edition.';
    public static final String RESOURCE_LIMIT_MESSAGE =
        'Additional active service resources are not available in this edition.';

    @AuraEnabled(cacheable=true)
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
