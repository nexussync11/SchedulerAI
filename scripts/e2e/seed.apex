List<Lead> leads = [SELECT Id FROM Lead WHERE LastName = 'LadminAI E2E Lead' AND Company = 'LadminAI E2E' LIMIT 1];
Lead e2eLead = leads.isEmpty() ? new Lead(LastName = 'LadminAI E2E Lead', Company = 'LadminAI E2E') : leads[0];
if (e2eLead.Id == null) insert e2eLead;
Schema.Location e2eLocation = [
    SELECT Id FROM Location
    WHERE Scheduler_Managed__c = true AND Scheduler_Active__c = true
    LIMIT 1
];
Scheduler_Location_Resource__c e2eAssignment = [
    SELECT Service_Resource__c FROM Scheduler_Location_Resource__c
    WHERE Location__c = :e2eLocation.Id AND Active__c = true
    AND Service_Resource__r.Active__c = true
    LIMIT 1
];
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
