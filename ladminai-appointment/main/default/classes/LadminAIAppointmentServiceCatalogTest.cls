@IsTest
private class LadminAIAppointmentServiceCatalogTest {
    @IsTest static void managesServicesAndEligibility() {
        Id serviceId=LadminAIAppointmentServiceCatalog.saveService(null,'Consultation',45,5,10,'Initial consultation',true);
        Service_Resource__c resource=new Service_Resource__c(Name='Eligible resource',Active__c=true);insert resource;
        Schema.Location location=new Schema.Location(Name='Eligible location',LocationType='Site',Scheduler_Managed__c=true,Scheduler_Active__c=true);insert location;
        insert new Scheduler_Location_Resource__c(Location__c=location.Id,Service_Resource__c=resource.Id,Active__c=true,Location_Resource_Key__c=location.Id+':'+resource.Id);
        LadminAIAppointmentServiceCatalog.saveEligibility(serviceId,new List<Id>{resource.Id},new List<Id>{location.Id});
        LadminAIAppointmentServiceCatalog.EligibilityOptions options=LadminAIAppointmentServiceCatalog.getEligibility(serviceId);
        System.assertEquals(1,options.resourceIds.size());System.assertEquals(1,options.locationIds.size());
        System.assertEquals(1,LadminAIAppointmentServiceCatalog.getEligibleResources(serviceId,location.Id).size());
        LadminAIAppointmentServiceCatalog.assertEligible(serviceId,location.Id,resource.Id);
        System.assertEquals(1,LadminAIAppointmentServiceCatalog.getServices().size());System.assertEquals(1,LadminAIAppointmentServiceCatalog.getActiveServices().size());
        LadminAIAppointmentServiceCatalog.saveService(serviceId,'Consultation Updated',60,0,0,null,true);LadminAIAppointmentServiceCatalog.setActive(serviceId,false);System.assertEquals(0,LadminAIAppointmentServiceCatalog.getActiveServices().size());
    }
    @IsTest static void validatesDuration(){try{LadminAIAppointmentServiceCatalog.saveService(null,'Bad',0,0,0,null,true);System.assert(false);}catch(AuraHandledException expected){}}
    @IsTest static void importsValidRowsAndReportsInvalidRows(){LadminAIAppointmentServiceCatalog.ServiceImportRow valid=new LadminAIAppointmentServiceCatalog.ServiceImportRow();valid.name='Imported Service';valid.durationMinutes=45;valid.bufferBefore=5;valid.bufferAfter=10;valid.description='Imported';valid.active=true;LadminAIAppointmentServiceCatalog.ServiceImportRow invalid=new LadminAIAppointmentServiceCatalog.ServiceImportRow();invalid.name='Bad Service';invalid.durationMinutes=0;LadminAIAppointmentServiceCatalog.ImportResult result=LadminAIAppointmentServiceCatalog.importServices(new List<LadminAIAppointmentServiceCatalog.ServiceImportRow>{valid,invalid});System.assertEquals(1,result.imported);System.assertEquals(1,result.errors.size());System.assertEquals(1,[SELECT COUNT() FROM Appointment_Service__c WHERE Name='Imported Service']);}
}
