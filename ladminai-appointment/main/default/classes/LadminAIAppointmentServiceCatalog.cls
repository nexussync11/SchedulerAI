public with sharing class LadminAIAppointmentServiceCatalog {
    @AuraEnabled(cacheable=true) public static List<Appointment_Service__c> getServices(){return[SELECT Id,Name,Active__c,Description__c,Duration_Minutes__c,Buffer_Before_Minutes__c,Buffer_After_Minutes__c FROM Appointment_Service__c WITH USER_MODE ORDER BY Active__c DESC,Name LIMIT 500];}
    @AuraEnabled(cacheable=true) public static List<Appointment_Service__c> getActiveServices(){return[SELECT Id,Name,Duration_Minutes__c,Buffer_Before_Minutes__c,Buffer_After_Minutes__c FROM Appointment_Service__c WHERE Active__c=true WITH USER_MODE ORDER BY Name LIMIT 500];}
    @AuraEnabled public static Id saveService(Id serviceId,String name,Decimal durationMinutes,Decimal bufferBefore,Decimal bufferAfter,String description,Boolean active){
        if(String.isBlank(name))throw safe('Service name is required.');if(durationMinutes==null||durationMinutes<5||durationMinutes>480)throw safe('Duration must be between 5 and 480 minutes.');
        Decimal beforeValue=bufferBefore==null?0:bufferBefore,afterValue=bufferAfter==null?0:bufferAfter;if(beforeValue<0||afterValue<0||beforeValue>240||afterValue>240)throw safe('Buffers must be between 0 and 240 minutes.');
        Appointment_Service__c row=serviceId==null?new Appointment_Service__c():[SELECT Id FROM Appointment_Service__c WHERE Id=:serviceId WITH USER_MODE LIMIT 1];row.Name=name.trim();row.Duration_Minutes__c=durationMinutes;row.Buffer_Before_Minutes__c=beforeValue;row.Buffer_After_Minutes__c=afterValue;row.Description__c=description;row.Active__c=active==true;if(serviceId==null)Database.insert(row,AccessLevel.USER_MODE);else Database.update(row,AccessLevel.USER_MODE);return row.Id;
    }
    @AuraEnabled public static void setActive(Id serviceId,Boolean active){if(serviceId==null)throw safe('A service is required.');Database.update(new Appointment_Service__c(Id=serviceId,Active__c=active==true),AccessLevel.USER_MODE);}
    private static AuraHandledException safe(String message){AuraHandledException e=new AuraHandledException(message);e.setMessage(message);return e;}
}
