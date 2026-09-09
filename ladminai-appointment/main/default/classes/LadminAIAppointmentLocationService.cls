public with sharing class LadminAIAppointmentLocationService {
    private static final String SCHEDULER_LOCATION_TYPE = 'Site';
    @TestVisible private static Boolean forceAccessDenied = false;

    @AuraEnabled(cacheable=true)
    public static List<LocationRow> getLocations() {
        assertReadAccess();
        Map<Id, Integer> doctorCounts = aggregateDoctors();
        Map<Id, Integer> appointmentCounts = aggregateAppointments();
        Map<Id, Integer> availabilityCounts = aggregateAvailability();
        List<LocationRow> output = new List<LocationRow>();
        for (Schema.Location location : [
            SELECT Id, Name, LocationType, Description, Scheduler_Active__c, Scheduler_Time_Zone__c
            FROM Location
            WHERE Scheduler_Managed__c = true
            WITH USER_MODE
            ORDER BY Name
            LIMIT 500
        ]) {
            LocationRow row = new LocationRow();
            row.id = location.Id;
            row.name = location.Name;
            row.locationType = location.LocationType;
            row.description = location.Description;
            row.active = location.Scheduler_Active__c;
            row.timezoneSidKey = String.isBlank(location.Scheduler_Time_Zone__c)
                ? LadminAIAppointmentSettingsService.businessTimeZone() : location.Scheduler_Time_Zone__c;
            row.doctorCount = valueOrZero(doctorCounts, location.Id);
            row.appointmentCount = valueOrZero(appointmentCounts, location.Id);
            row.availabilityCount = valueOrZero(availabilityCounts, location.Id);
            row.doctorIds = new List<Id>();
            output.add(row);
        }
        Map<Id, LocationRow> byId = new Map<Id, LocationRow>();
        for (LocationRow row : output) byId.put(row.id, row);
        for (Scheduler_Location_Resource__c association : [
            SELECT Location__c, Service_Resource__c
            FROM Scheduler_Location_Resource__c
            WHERE Active__c = true AND Location__c IN :byId.keySet()
            WITH USER_MODE
        ]) {
            byId.get(association.Location__c).doctorIds.add(
                association.Service_Resource__c
            );
        }
        return output;
    }

    @AuraEnabled(cacheable=true)
    public static List<LocationOption> getActiveLocations() {
        assertReadAccess();
        List<LocationOption> output = new List<LocationOption>();
        for (Schema.Location row : [
            SELECT Id, Name, Scheduler_Time_Zone__c
            FROM Location
            WHERE Scheduler_Managed__c = true
              AND Scheduler_Active__c = true
            WITH USER_MODE
            ORDER BY Name
            LIMIT 500
        ]) {
            LocationOption option = new LocationOption();
            option.Id = row.Id;
            option.Name = row.Name;
            option.TimezoneSidKey = String.isBlank(row.Scheduler_Time_Zone__c)
                ? LadminAIAppointmentSettingsService.businessTimeZone() : row.Scheduler_Time_Zone__c;
            output.add(option);
        }
        return output;
    }

    @AuraEnabled(cacheable=true)
    public static List<Service_Resource__c> getDoctorsForLocation(Id locationId) {
        if (locationId == null || locationId.getSObjectType() != Schema.Location.SObjectType) {
            return new List<Service_Resource__c>();
        }
        assertReadAccess();
        Set<Id> resourceIds = new Set<Id>();
        for (Scheduler_Location_Resource__c row : [
            SELECT Service_Resource__c
            FROM Scheduler_Location_Resource__c
            WHERE Location__c = :locationId AND Active__c = true
            WITH USER_MODE
        ]) resourceIds.add(row.Service_Resource__c);
        if (resourceIds.isEmpty()) return new List<Service_Resource__c>();
        return [
            SELECT Id, Name, Active__c
            FROM Service_Resource__c
            WHERE Id IN :resourceIds AND Active__c = true
            WITH USER_MODE
            ORDER BY Name
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getLocationTypes() {
        return new List<String>{ SCHEDULER_LOCATION_TYPE };
    }

    @AuraEnabled
    public static Id saveLocation(
        Id locationId,
        String name,
        String locationType,
        String description,
        Boolean active,
        List<Id> doctorIds,
        String timezoneSidKey
    ) {
        Savepoint start = Database.setSavepoint();
        try {
            Boolean creating = locationId == null;
            assertWriteAccess(creating);
            if (active == null || active == true) {
                LadminAIAppointmentEditionService.assertLocationActivationAllowed(locationId);
            }
            if (String.isBlank(name)) {
                throw new LocationException('Location name is required.');
            }
            Schema.Location row = creating
                ? new Schema.Location()
                : [SELECT Id FROM Location WHERE Id = :locationId WITH USER_MODE LIMIT 1];
            row.Name = name.trim();
            row.LocationType = SCHEDULER_LOCATION_TYPE;
            row.Description = String.isBlank(description) ? null : description.trim();
            row.Scheduler_Active__c = active == null ? true : active;
            row.Scheduler_Managed__c = true;
            row.Scheduler_Time_Zone__c = String.isBlank(timezoneSidKey)
                ? LadminAIAppointmentSettingsService.businessTimeZone() : timezoneSidKey;
            if (creating) Database.insert(row, AccessLevel.USER_MODE);
            else Database.update(row, AccessLevel.USER_MODE);
            saveAssociations(row.Id, doctorIds);
            return row.Id;
        } catch (Exception ex) {
            Database.rollback(start);
            throw safeException(ex, 'The location could not be saved.');
        }
    }

    @AuraEnabled
    public static void setActive(Id locationId, Boolean active) {
        try {
            assertWriteAccess(false);
            if (active == true) {
                LadminAIAppointmentEditionService.assertLocationActivationAllowed(locationId);
            }
            if (locationId == null || locationId.getSObjectType() != Schema.Location.SObjectType) {
                throw new LocationException('A valid Location is required.');
            }
            Database.update(
                new Schema.Location(Id = locationId, Scheduler_Active__c = active == true),
                AccessLevel.USER_MODE
            );
        } catch (Exception ex) {
            throw safeException(ex, 'The location status could not be changed.');
        }
    }

    public static void assertActiveAssociation(Id locationId, Id resourceId) {
        if (locationId == null || resourceId == null) {
            throw new LocationException('Select a location and doctor.');
        }
        Integer matches = [
            SELECT COUNT()
            FROM Scheduler_Location_Resource__c
            WHERE Location__c = :locationId
              AND Service_Resource__c = :resourceId
              AND Active__c = true
              AND Location__r.Scheduler_Managed__c = true
              AND Location__r.Scheduler_Active__c = true
              AND Service_Resource__r.Active__c = true
            WITH USER_MODE
        ];
        if (matches != 1) {
            throw new LocationException(
                'The selected doctor is not active at this location.'
            );
        }
    }

    private static void saveAssociations(Id locationId, List<Id> doctorIds) {
        Set<Id> selected = doctorIds == null ? new Set<Id>() : new Set<Id>(doctorIds);
        Map<Id, Scheduler_Location_Resource__c> existing =
            new Map<Id, Scheduler_Location_Resource__c>();
        for (Scheduler_Location_Resource__c row : [
            SELECT Id, Service_Resource__c, Active__c
            FROM Scheduler_Location_Resource__c
            WHERE Location__c = :locationId
            WITH USER_MODE
            FOR UPDATE
        ]) existing.put(row.Service_Resource__c, row);
        List<Scheduler_Location_Resource__c> changes =
            new List<Scheduler_Location_Resource__c>();
        for (Id resourceId : selected) {
            Scheduler_Location_Resource__c row = existing.remove(resourceId);
            if (row == null) {
                row = new Scheduler_Location_Resource__c(
                    Location__c = locationId,
                    Service_Resource__c = resourceId,
                    Location_Resource_Key__c = locationId + ':' + resourceId
                );
            }
            row.Active__c = true;
            changes.add(row);
        }
        for (Scheduler_Location_Resource__c row : existing.values()) {
            if (row.Active__c) {
                row.Active__c = false;
                changes.add(row);
            }
        }
        if (!changes.isEmpty()) Database.upsert(
            changes,
            Scheduler_Location_Resource__c.Location_Resource_Key__c,
            AccessLevel.USER_MODE
        );
    }

    private static Map<Id, Integer> aggregateDoctors() {
        Map<Id, Integer> output = new Map<Id, Integer>();
        for (AggregateResult row : [
            SELECT Location__c locationId, COUNT(Id) total
            FROM Scheduler_Location_Resource__c
            WHERE Active__c = true AND Location__c != null
            WITH USER_MODE
            GROUP BY Location__c
        ]) output.put((Id) row.get('locationId'), (Integer) row.get('total'));
        return output;
    }
    private static Map<Id, Integer> aggregateAppointments() {
        Map<Id, Integer> output = new Map<Id, Integer>();
        for (AggregateResult row : [
            SELECT Location__c locationId, COUNT(Id) total
            FROM ServiceAppointment__c
            WHERE Location__c != null
            WITH USER_MODE
            GROUP BY Location__c
        ]) output.put((Id) row.get('locationId'), (Integer) row.get('total'));
        return output;
    }
    private static Map<Id, Integer> aggregateAvailability() {
        Map<Id, Integer> output = new Map<Id, Integer>();
        for (AggregateResult row : [
            SELECT Location__c locationId, COUNT(Id) total
            FROM Resource_Availability__c
            WHERE Location__c != null
            WITH USER_MODE
            GROUP BY Location__c
        ]) output.put((Id) row.get('locationId'), (Integer) row.get('total'));
        return output;
    }
    private static Integer valueOrZero(Map<Id, Integer> values, Id key) {
        return values.containsKey(key) ? values.get(key) : 0;
    }
    private static void assertReadAccess() {
        if (forceAccessDenied || !Schema.Location.SObjectType.getDescribe().isAccessible()) {
            forceAccessDenied = false;
            throw new AuraHandledException('Locations are unavailable or you do not have access.');
        }
    }
    private static void assertWriteAccess(Boolean creating) {
        if (forceAccessDenied) {
            forceAccessDenied = false;
            throw new LocationException('You do not have permission to manage locations.');
        }
        Schema.DescribeSObjectResult locationDescribe = Schema.Location.SObjectType.getDescribe();
        if ((creating && !locationDescribe.isCreateable()) || (!creating && !locationDescribe.isUpdateable())) {
            throw new LocationException('You do not have permission to manage locations.');
        }
    }
    private static AuraHandledException safeException(Exception ex, String fallback) {
        if (ex != null && ex.getMessage() == LadminAIAppointmentEditionService.LOCATION_LIMIT_MESSAGE) {
            AuraHandledException limitError = new AuraHandledException(ex.getMessage());
            limitError.setMessage(ex.getMessage());
            return limitError;
        }
        if (ex != null && ex.getMessage() != null &&
            ex.getMessage().contains('STORAGE_LIMIT_EXCEEDED')) {
            return new AuraHandledException(
                'Salesforce data storage is full. Free storage, then save the location again.'
            );
        }
        return new AuraHandledException(
            ex instanceof LocationException ? ex.getMessage() : fallback
        );
    }

    public class LocationRow {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String locationType { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public Boolean active { get; set; }
        @AuraEnabled public String timezoneSidKey { get; set; }
        @AuraEnabled public Integer doctorCount { get; set; }
        @AuraEnabled public Integer appointmentCount { get; set; }
        @AuraEnabled public Integer availabilityCount { get; set; }
        @AuraEnabled public List<Id> doctorIds { get; set; }
    }
    public class LocationOption {
        @AuraEnabled public Id Id { get; set; }
        @AuraEnabled public String Name { get; set; }
        @AuraEnabled public String TimezoneSidKey { get; set; }
    }
    public class LocationException extends Exception {}
}
