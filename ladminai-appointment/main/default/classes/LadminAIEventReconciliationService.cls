@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class LadminAIEventReconciliationService implements Schedulable {
    public void execute(SchedulableContext context) { reconcile(200); }
    @AuraEnabled
    public static ReconciliationResult reconcile(Integer maximumRecords) {
        Integer recordLimit = maximumRecords == null ? 200 : Math.max(1, Math.min(500, maximumRecords));
        Datetime lowerBound = System.now().addDays(-1);
        List<ServiceAppointment__c> appointments = [
            SELECT Id, Name, Subject__c, Parent_Record1__c, Scheduled_Start__c, Scheduled_End__c,
                Status__c, LadminAI_Event__c, Event_Sync_Attempts__c
            FROM ServiceAppointment__c
            WHERE Status__c NOT IN ('Cancelled','Cancel') AND Scheduled_End__c >= :lowerBound
            ORDER BY Scheduled_Start__c LIMIT :recordLimit
        ];
        Set<Id> eventIds = new Set<Id>();
        for (ServiceAppointment__c appointment : appointments) if (appointment.LadminAI_Event__c != null) eventIds.add(appointment.LadminAI_Event__c);
        Map<Id, Event> events = eventIds.isEmpty() ? new Map<Id, Event>() : new Map<Id, Event>([
            SELECT Id, Subject, WhoId, StartDateTime, EndDateTime FROM Event WHERE Id IN :eventIds
        ]);
        ReconciliationResult result = new ReconciliationResult();
        List<ServiceAppointment__c> updates = new List<ServiceAppointment__c>();
        for (ServiceAppointment__c appointment : appointments) {
            Event linked = events.get(appointment.LadminAI_Event__c);
            Boolean needsRepair = linked == null || linked.StartDateTime != appointment.Scheduled_Start__c || linked.EndDateTime != appointment.Scheduled_End__c;
            if (!needsRepair) continue;
            ServiceAppointment__c tracking = new ServiceAppointment__c(Id=appointment.Id, Event_Sync_Attempts__c=(appointment.Event_Sync_Attempts__c==null?0:appointment.Event_Sync_Attempts__c)+1);
            try {
                if (linked == null) {
                    linked = new Event(Subject=appointment.Subject__c,WhoId=appointment.Parent_Record1__c,OwnerId=UserInfo.getUserId(),StartDateTime=appointment.Scheduled_Start__c,EndDateTime=appointment.Scheduled_End__c);
                    insert linked; tracking.LadminAI_Event__c=linked.Id; result.recreated++;
                } else {
                    linked.Subject=appointment.Subject__c; linked.StartDateTime=appointment.Scheduled_Start__c; linked.EndDateTime=appointment.Scheduled_End__c; update linked; result.repaired++;
                }
                tracking.Event_Sync_Status__c='Synchronized'; tracking.Event_Sync_Error__c=null;
            } catch (Exception failure) {
                tracking.Event_Sync_Status__c='Failed'; tracking.Event_Sync_Error__c=failure.getMessage().left(255); result.failed++;
            }
            updates.add(tracking);
        }
        if (!updates.isEmpty()) update updates;
        return result;
    }
    public class ReconciliationResult { @AuraEnabled public Integer repaired=0; @AuraEnabled public Integer recreated=0; @AuraEnabled public Integer failed=0; }
}
