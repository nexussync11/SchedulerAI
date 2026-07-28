public class AppointmentRescheduleHandler {
 //*************************************************
    
 
       public static void handleAfterUpdate2( 
        List<Event> newList,
        Map<Id, Event> oldMap
    ) {
          system.debug('#AppointmentRescheduleHandler called');
        Map<Id, Integer> rescheduleMap = new Map<Id, Integer>();
      

        for(Event newEvn : newList){

            Event oldEvn = oldMap.get(newEvn.Id);

            if(oldEvn == null) continue;

            // 🔁 Check Reschedule
            if(newEvn.StartDateTime != oldEvn.StartDateTime){

                if(newEvn.WhoId != null){

                    Integer count = rescheduleMap.containsKey(newEvn.WhoId)
                        ? rescheduleMap.get(newEvn.WhoId)
                        : 0;

                    rescheduleMap.put(
                        newEvn.WhoId,
                        count + 1
                    );
                }
            }


        // Merge Lead Ids
        Set<Id> leadIds = new Set<Id>();
        leadIds.addAll(rescheduleMap.keySet());
      

        if(leadIds.isEmpty()) return;

        List<Lead> leadsToUpdate = [
            SELECT Id, Reschedule_Count__c
            FROM Lead
            WHERE Id IN :leadIds
        ];

        for(Lead ld : leadsToUpdate){

            if(rescheduleMap.containsKey(ld.Id)){
                ld.Reschedule_Count__c =
                    (ld.Reschedule_Count__c == null ? 0 : ld.Reschedule_Count__c)
                    + rescheduleMap.get(ld.Id);
            }

          
        }

        if(!leadsToUpdate.isEmpty()){
            update leadsToUpdate;
        }
    }
    
    } 
}