public class AppointmentTrackingHandler {

    public static void handleAfterUpdate(
        List<ServiceAppointment__c> newList,
        Map<Id, ServiceAppointment__c> oldMap
    ) {

        Map<Id, Integer> rescheduleMap = new Map<Id, Integer>();
        Map<Id, Integer> dnaMap = new Map<Id, Integer>();

        for(ServiceAppointment__c newAppt : newList){

            ServiceAppointment__c oldAppt = oldMap.get(newAppt.Id);

            if(oldAppt == null) continue;

            // 🔁 Check Reschedule
            if(newAppt.Scheduled_Start__c != oldAppt.Scheduled_Start__c){

                if(newAppt.Parent_Record1__c != null){

                    Integer count = rescheduleMap.containsKey(newAppt.Parent_Record1__c)
                        ? rescheduleMap.get(newAppt.Parent_Record1__c)
                        : 0;

                    rescheduleMap.put(
                        newAppt.Parent_Record1__c,
                        count + 1
                    );
                }
            }

            // 🚫 Check DNA
            if(newAppt.Status__c == 'DNA' &&
               oldAppt.Status__c != 'DNA'){

                if(newAppt.Parent_Record1__c != null){

                    Integer count = dnaMap.containsKey(newAppt.Parent_Record1__c)
                        ? dnaMap.get(newAppt.Parent_Record1__c)
                        : 0;

                    dnaMap.put(
                        newAppt.Parent_Record1__c,
                        count + 1
                    );
                }
            }
        }

        // Merge Lead Ids
        Set<Id> leadIds = new Set<Id>();
        leadIds.addAll(rescheduleMap.keySet());
        leadIds.addAll(dnaMap.keySet());

        if(leadIds.isEmpty()) return;

        List<Lead> leadsToUpdate = [
            SELECT Id, Reschedule_Count__c, DNA_Count__c
            FROM Lead
            WHERE Id IN :leadIds
        ];

        for(Lead ld : leadsToUpdate){

            if(rescheduleMap.containsKey(ld.Id)){
                ld.Reschedule_Count__c =
                    (ld.Reschedule_Count__c == null ? 0 : ld.Reschedule_Count__c)
                    + rescheduleMap.get(ld.Id);
            }

            if(dnaMap.containsKey(ld.Id)){
                ld.DNA_Count__c =
                    (ld.DNA_Count__c == null ? 0 : ld.DNA_Count__c)
                    + dnaMap.get(ld.Id);
            }
        }

        if(!leadsToUpdate.isEmpty()){
            update leadsToUpdate;
        }
    }
}