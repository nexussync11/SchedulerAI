List<Lead> leads = [SELECT Id,OwnerId FROM Lead WHERE LastName = 'LadminAI E2E Lead' AND Company = 'LadminAI E2E' LIMIT 1];
Lead e2eLead = leads.isEmpty() ? new Lead(LastName = 'LadminAI E2E Lead', Company = 'LadminAI E2E') : leads[0];
if (e2eLead.Id == null) insert e2eLead;
List<User> operationsUsers=[SELECT Id FROM User WHERE Username='ladminai-operations@example.test' AND IsActive=true LIMIT 1];if(!operationsUsers.isEmpty()&&e2eLead.OwnerId!=operationsUsers[0].Id){e2eLead.OwnerId=operationsUsers[0].Id;update e2eLead;}
List<Schema.Location> locations=[SELECT Id FROM Location WHERE Scheduler_Managed__c=true AND Scheduler_Active__c=true LIMIT 1];
Schema.Location e2eLocation=locations.isEmpty()?new Schema.Location(Name='LadminAI UAT Clinic',LocationType='Site',Scheduler_Managed__c=true,Scheduler_Active__c=true,Scheduler_Time_Zone__c='Asia/Kolkata'):locations[0];if(e2eLocation.Id==null)insert e2eLocation;
List<Service_Resource__c> resources=[SELECT Id FROM Service_Resource__c WHERE Active__c=true LIMIT 1];Service_Resource__c e2eResource=resources.isEmpty()?new Service_Resource__c(Name='LadminAI UAT Resource',Active__c=true):resources[0];if(e2eResource.Id==null)insert e2eResource;
List<Scheduler_Location_Resource__c> assignments=[SELECT Service_Resource__c FROM Scheduler_Location_Resource__c WHERE Location__c=:e2eLocation.Id AND Service_Resource__c=:e2eResource.Id LIMIT 1];Scheduler_Location_Resource__c e2eAssignment=assignments.isEmpty()?new Scheduler_Location_Resource__c(Location__c=e2eLocation.Id,Service_Resource__c=e2eResource.Id,Active__c=true,Location_Resource_Key__c=e2eLocation.Id+':'+e2eResource.Id):assignments[0];if(e2eAssignment.Id==null)insert e2eAssignment;
List<Appointment_Service__c> services=[SELECT Id FROM Appointment_Service__c WHERE Active__c=true LIMIT 1];if(services.isEmpty())insert new Appointment_Service__c(Name='Consultation',Active__c=true,Duration_Minutes__c=30,Buffer_Before_Minutes__c=0,Buffer_After_Minutes__c=0);
List<Map<String, Object>> e2eDays = new List<Map<String, Object>>();
Set<String> configuredDays = new Set<String>();
for (Integer offset : new List<Integer>{ 2, 3 }) {
    Date target = Date.today().addDays(offset);
    String weekday = Datetime.newInstance(target, Time.newInstance(12, 0, 0, 0)).format('EEEE');
    if (configuredDays.add(weekday)) {
        e2eDays.add(new Map<String, Object>{
            'Day_Of_Week__c' => weekday,
            'Start_Time__c' => '08:00',
            'End_Time__c' => '18:00',
            'Is_Active__c' => true
        });
    }
}
LadminAIAppointmentAvailabilityService.saveAvailabilityAtLocation(
    e2eAssignment.Service_Resource__c, e2eLocation.Id, e2eDays
);
System.debug('E2E_LEAD_ID=' + e2eLead.Id);
