public with sharing class LadminAIAppointmentServiceCatalog {
    @AuraEnabled(cacheable=true) public static List<Appointment_Service__c> getServices(){return[SELECT Id,Name,Active__c,Description__c,Duration_Minutes__c,Buffer_Before_Minutes__c,Buffer_After_Minutes__c FROM Appointment_Service__c WITH USER_MODE ORDER BY Active__c DESC,Name LIMIT 500];}
    @AuraEnabled(cacheable=true) public static List<Appointment_Service__c> getActiveServices(){return[SELECT Id,Name,Duration_Minutes__c,Buffer_Before_Minutes__c,Buffer_After_Minutes__c FROM Appointment_Service__c WHERE Active__c=true WITH USER_MODE ORDER BY Name LIMIT 500];}
    @AuraEnabled public static Id saveService(Id serviceId,String name,Decimal durationMinutes,Decimal bufferBefore,Decimal bufferAfter,String description,Boolean active){
        if(String.isBlank(name))throw safe('Service name is required.');if(durationMinutes==null||durationMinutes<5||durationMinutes>480)throw safe('Duration must be between 5 and 480 minutes.');
        Decimal beforeValue=bufferBefore==null?0:bufferBefore,afterValue=bufferAfter==null?0:bufferAfter;if(beforeValue<0||afterValue<0||beforeValue>240||afterValue>240)throw safe('Buffers must be between 0 and 240 minutes.');
        Appointment_Service__c row=serviceId==null?new Appointment_Service__c():[SELECT Id FROM Appointment_Service__c WHERE Id=:serviceId WITH USER_MODE LIMIT 1];row.Name=name.trim();row.Duration_Minutes__c=durationMinutes;row.Buffer_Before_Minutes__c=beforeValue;row.Buffer_After_Minutes__c=afterValue;row.Description__c=description;row.Active__c=active==true;if(serviceId==null)Database.insert(row,AccessLevel.USER_MODE);else Database.update(row,AccessLevel.USER_MODE);return row.Id;
    }
    @AuraEnabled public static void setActive(Id serviceId,Boolean active){if(serviceId==null)throw safe('A service is required.');Database.update(new Appointment_Service__c(Id=serviceId,Active__c=active==true),AccessLevel.USER_MODE);}
    @AuraEnabled(cacheable=true) public static EligibilityOptions getEligibility(Id serviceId){
        EligibilityOptions output=new EligibilityOptions();output.resources=new List<EligibilityOption>();output.locations=new List<EligibilityOption>();for(Service_Resource__c row:[SELECT Id,Name FROM Service_Resource__c WHERE Active__c=true WITH USER_MODE ORDER BY Name])output.resources.add(new EligibilityOption(row.Id,row.Name));for(Schema.Location row:[SELECT Id,Name FROM Location WHERE Scheduler_Managed__c=true AND Scheduler_Active__c=true WITH USER_MODE ORDER BY Name])output.locations.add(new EligibilityOption(row.Id,row.Name));output.resourceIds=new List<Id>();output.locationIds=new List<Id>();
        if(serviceId!=null){for(Service_Resource_Eligibility__c row:[SELECT Resource__c FROM Service_Resource_Eligibility__c WHERE Service__c=:serviceId WITH USER_MODE])output.resourceIds.add(row.Resource__c);for(Service_Location_Eligibility__c row:[SELECT Location__c FROM Service_Location_Eligibility__c WHERE Service__c=:serviceId WITH USER_MODE])output.locationIds.add(row.Location__c);}return output;
    }
    @AuraEnabled public static void saveEligibility(Id serviceId,List<Id> resourceIds,List<Id> locationIds){
        if(serviceId==null)throw safe('Save the service before configuring eligibility.');
        delete as user [SELECT Id FROM Service_Resource_Eligibility__c WHERE Service__c=:serviceId WITH USER_MODE];delete as user [SELECT Id FROM Service_Location_Eligibility__c WHERE Service__c=:serviceId WITH USER_MODE];
        List<Service_Resource_Eligibility__c> resources=new List<Service_Resource_Eligibility__c>();for(Id resourceId:resourceIds==null?new List<Id>():resourceIds)resources.add(new Service_Resource_Eligibility__c(Service__c=serviceId,Resource__c=resourceId,Eligibility_Key__c=serviceId+':'+resourceId));if(!resources.isEmpty())insert as user resources;
        List<Service_Location_Eligibility__c> locations=new List<Service_Location_Eligibility__c>();for(Id locationId:locationIds==null?new List<Id>():locationIds)locations.add(new Service_Location_Eligibility__c(Service__c=serviceId,Location__c=locationId,Eligibility_Key__c=serviceId+':'+locationId));if(!locations.isEmpty())insert as user locations;
    }
    @AuraEnabled public static ImportResult importServices(List<ServiceImportRow> inputRows) {
        ImportResult output = new ImportResult(); output.imported = 0; output.errors = new List<String>();
        if (inputRows == null || inputRows.isEmpty()) { output.errors.add('The CSV does not contain any service rows.'); return output; }
        if (inputRows.size() > 500) { output.errors.add('Import supports a maximum of 500 service rows.'); return output; }
        Map<String,Appointment_Service__c> existingByName = new Map<String,Appointment_Service__c>();
        for (Appointment_Service__c existing : [SELECT Id,Name FROM Appointment_Service__c WITH USER_MODE]) existingByName.put(existing.Name.toLowerCase(), existing);
        Set<String> seen = new Set<String>(); List<Appointment_Service__c> changes = new List<Appointment_Service__c>(); List<Integer> sourceRows = new List<Integer>();
        for (Integer index = 0; index < inputRows.size(); index++) {
            ServiceImportRow input = inputRows[index]; Integer csvRow = index + 2;
            if (input == null || String.isBlank(input.name)) { output.errors.add('Row ' + csvRow + ': Service name is required.'); continue; }
            String key = input.name.trim().toLowerCase();
            if (seen.contains(key)) { output.errors.add('Row ' + csvRow + ': Duplicate service name in this file.'); continue; }
            seen.add(key);
            if (input.durationMinutes == null || input.durationMinutes < 5 || input.durationMinutes > 480) { output.errors.add('Row ' + csvRow + ': Duration must be between 5 and 480 minutes.'); continue; }
            Decimal beforeValue = input.bufferBefore == null ? 0 : input.bufferBefore, afterValue = input.bufferAfter == null ? 0 : input.bufferAfter;
            if (beforeValue < 0 || beforeValue > 240 || afterValue < 0 || afterValue > 240) { output.errors.add('Row ' + csvRow + ': Buffers must be between 0 and 240 minutes.'); continue; }
            Appointment_Service__c change = existingByName.containsKey(key) ? new Appointment_Service__c(Id=existingByName.get(key).Id) : new Appointment_Service__c();
            change.Name=input.name.trim(); change.Duration_Minutes__c=input.durationMinutes; change.Buffer_Before_Minutes__c=beforeValue; change.Buffer_After_Minutes__c=afterValue; change.Description__c=input.description; change.Active__c=input.active==true;
            changes.add(change); sourceRows.add(csvRow);
        }
        if (!changes.isEmpty()) {
            Database.UpsertResult[] results = Database.upsert(changes, false, AccessLevel.USER_MODE);
            for (Integer index=0; index<results.size(); index++) {
                if (results[index].isSuccess()) output.imported++;
                else output.errors.add('Row ' + sourceRows[index] + ': ' + results[index].getErrors()[0].getMessage());
            }
        }
        return output;
    }
    public class ServiceImportRow { @AuraEnabled public String name; @AuraEnabled public Decimal durationMinutes; @AuraEnabled public Decimal bufferBefore; @AuraEnabled public Decimal bufferAfter; @AuraEnabled public String description; @AuraEnabled public Boolean active; }
    public class ImportResult { @AuraEnabled public Integer imported; @AuraEnabled public List<String> errors; }
    public class EligibilityOptions {@AuraEnabled public List<EligibilityOption> resources;@AuraEnabled public List<EligibilityOption> locations;@AuraEnabled public List<Id> resourceIds;@AuraEnabled public List<Id> locationIds;}
    public class EligibilityOption {@AuraEnabled public Id value;@AuraEnabled public String label;public EligibilityOption(Id value,String label){this.value=value;this.label=label;}}
    private static AuraHandledException safe(String message){AuraHandledException e=new AuraHandledException(message);e.setMessage(message);return e;}
}
