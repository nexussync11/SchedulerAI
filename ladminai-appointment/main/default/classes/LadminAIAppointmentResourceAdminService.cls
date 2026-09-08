public with sharing class LadminAIAppointmentResourceAdminService {
    @TestVisible private static Boolean forceAccessDenied = false;

    public class ResourceRow {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public Boolean active { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public Integer appointmentCount { get; set; }
        @AuraEnabled public Integer availabilityCount { get; set; }
        @AuraEnabled public List<String> locationNames { get; set; }
    }

    public class AppointmentRow {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public Datetime scheduledStart { get; set; }
        @AuraEnabled public Datetime scheduledEnd { get; set; }
        @AuraEnabled public String status { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static List<ResourceRow> getResources() {
        assertReadAccess();
        List<Service_Resource__c> resources = [
            SELECT Id, Name, Active__c, Description__c
            FROM Service_Resource__c
            WITH USER_MODE
            ORDER BY Active__c DESC, Name ASC
        ];
        Map<Id, Integer> appointmentCounts = assignmentCounts();
        Map<Id, Integer> availabilityCounts = availabilityCounts();
        List<ResourceRow> output = new List<ResourceRow>();
        for (Service_Resource__c resource : resources) {
            ResourceRow row = new ResourceRow();
            row.id = resource.Id;
            row.name = resource.Name;
            row.active = resource.Active__c;
            row.description = resource.Description__c;
            row.appointmentCount = appointmentCounts.get(resource.Id) == null
                ? 0 : appointmentCounts.get(resource.Id);
            row.availabilityCount = availabilityCounts.get(resource.Id) == null
                ? 0 : availabilityCounts.get(resource.Id);
            row.locationNames = new List<String>();
            output.add(row);
        }
        Map<Id, ResourceRow> rowsById = new Map<Id, ResourceRow>();
        for (ResourceRow row : output) rowsById.put(row.id, row);
        if (!rowsById.isEmpty()) {
            Set<Id> resourceIds = rowsById.keySet();
            Map<String, Object> queryBinds = new Map<String, Object>{
                'resourceIds' => resourceIds
            };
            for (SObject associationRecord :
                Database.queryWithBinds(
                    'SELECT Service_Resource__c, Location__r.Name '
                    + 'FROM Scheduler_Location_Resource__c '
                    + 'WHERE Service_Resource__c IN :resourceIds '
                    + 'AND Active__c = true ORDER BY Location__r.Name',
                    queryBinds,
                    AccessLevel.USER_MODE
                )
            ) {
                Scheduler_Location_Resource__c association =
                    (Scheduler_Location_Resource__c) associationRecord;
                rowsById.get(association.Service_Resource__c)
                    .locationNames.add(association.Location__r.Name);
            }
        }
        return output;
    }

    private static Map<Id, Integer> assignmentCounts() {
        Map<Id, Integer> output = new Map<Id, Integer>();
        if (!Assigned_Resource__c.Service_Resource__c.getDescribe().isAccessible()) {
            return output;
        }
        for (AggregateResult row : [
            SELECT Service_Resource__c resourceId, COUNT(Id) total
            FROM Assigned_Resource__c
            WHERE Service_Resource__c != null
            WITH USER_MODE
            GROUP BY Service_Resource__c
        ]) {
            output.put((Id) row.get('resourceId'), (Integer) row.get('total'));
        }
        return output;
    }

    private static Map<Id, Integer> availabilityCounts() {
        Map<Id, Integer> output = new Map<Id, Integer>();
        if (!Resource_Availability__c.Service_Resource__c.getDescribe().isAccessible()) {
            return output;
        }
        for (AggregateResult row : [
            SELECT Service_Resource__c resourceId, COUNT(Id) total
            FROM Resource_Availability__c
            WHERE Service_Resource__c != null
            WITH USER_MODE
            GROUP BY Service_Resource__c
        ]) {
            output.put((Id) row.get('resourceId'), (Integer) row.get('total'));
        }
        return output;
    }

    @AuraEnabled(cacheable=true)
    public static List<AppointmentRow> getAppointments(Id resourceId) {
        assertReadAccess();
        if (resourceId == null) {
            throw safeException('A resource is required.');
        }
        List<AppointmentRow> output = new List<AppointmentRow>();
        for (Assigned_Resource__c assignment : [
            SELECT Service_Appointment__c, Service_Appointment__r.Name,
                   Service_Appointment__r.Scheduled_Start__c,
                   Service_Appointment__r.Scheduled_End__c,
                   Service_Appointment__r.Status__c
            FROM Assigned_Resource__c
            WHERE Service_Resource__c = :resourceId
            WITH USER_MODE
            ORDER BY Service_Appointment__r.Scheduled_Start__c DESC
            LIMIT 100
        ]) {
            AppointmentRow row = new AppointmentRow();
            row.id = assignment.Service_Appointment__c;
            row.name = assignment.Service_Appointment__r.Name;
            row.scheduledStart = assignment.Service_Appointment__r.Scheduled_Start__c;
            row.scheduledEnd = assignment.Service_Appointment__r.Scheduled_End__c;
            row.status = assignment.Service_Appointment__r.Status__c;
            output.add(row);
        }
        return output;
    }

    @AuraEnabled
    public static Id saveResource(
        Id resourceId,
        String name,
        Boolean active,
        String description
    ) {
        if (String.isBlank(name)) {
            throw safeException('Resource name is required.');
        }
        Boolean creating = resourceId == null;
        assertWriteAccess(creating);
        Service_Resource__c resource = creating
            ? new Service_Resource__c()
            : [
                SELECT Id FROM Service_Resource__c
                WHERE Id = :resourceId
                WITH USER_MODE
                LIMIT 1
            ];
        resource.Name = name.trim();
        resource.Active__c = active == true;
        resource.Description__c = description;
        try {
            if (creating) {
                Database.insert(resource, AccessLevel.USER_MODE);
            } else {
                Database.update(resource, AccessLevel.USER_MODE);
            }
            return resource.Id;
        } catch (DmlException exceptionValue) {
            if (isStorageLimit(exceptionValue)) {
                throw safeException(
                    'Salesforce data storage is full. Free storage, then save the resource again.'
                );
            }
            throw safeException('The resource could not be saved. Check the values and your access.');
        }
    }

    @AuraEnabled
    public static void setActive(Id resourceId, Boolean active) {
        if (resourceId == null) {
            throw safeException('A resource is required.');
        }
        assertWriteAccess(false);
        Service_Resource__c resource = [
            SELECT Id, Active__c FROM Service_Resource__c
            WHERE Id = :resourceId
            WITH USER_MODE
            LIMIT 1
        ];
        resource.Active__c = active == true;
        try {
            Database.update(resource, AccessLevel.USER_MODE);
        } catch (DmlException exceptionValue) {
            throw safeException('The resource status could not be changed.');
        }
    }

    private static void assertReadAccess() {
        if (forceAccessDenied || !Service_Resource__c.SObjectType.getDescribe().isAccessible()) {
            throw safeException('You do not have access to resource administration.');
        }
    }

    private static void assertWriteAccess(Boolean creating) {
        Schema.DescribeSObjectResult objectDescribe =
            Service_Resource__c.SObjectType.getDescribe();
        if (
            forceAccessDenied ||
            (creating && !objectDescribe.isCreateable()) ||
            (!creating && !objectDescribe.isUpdateable())
        ) {
            throw safeException('You do not have permission to manage resources.');
        }
        List<Schema.SObjectField> fields = new List<Schema.SObjectField>{
            Service_Resource__c.Name,
            Service_Resource__c.Active__c,
            Service_Resource__c.Description__c
        };
        for (Schema.SObjectField fieldValue : fields) {
            Schema.DescribeFieldResult describeValue = fieldValue.getDescribe();
            if (creating ? !describeValue.isCreateable() : !describeValue.isUpdateable()) {
                throw safeException('You do not have permission to manage resource fields.');
            }
        }
    }

    private static AuraHandledException safeException(String message) {
        AuraHandledException output = new AuraHandledException(message);
        output.setMessage(message);
        return output;
    }

    private static Boolean isStorageLimit(DmlException exceptionValue) {
        return exceptionValue != null &&
            exceptionValue.getMessage().contains('STORAGE_LIMIT_EXCEEDED');
    }
}
