public with sharing class LadminAIAppointmentCommandService {
    @AuraEnabled(cacheable=true)
    public static List<AppointmentRow> getAppointments(Date startDate, Date endDate) {
        if (startDate == null) startDate = Date.today().addDays(-30);
        if (endDate == null) endDate = Date.today().addDays(60);
        Datetime fromUtc = LadminAIAppointmentBusinessTimeService.toUtc(startDate, Time.newInstance(0,0,0,0));
        Datetime toUtc = LadminAIAppointmentBusinessTimeService.toUtc(endDate.addDays(1), Time.newInstance(0,0,0,0));
        List<ServiceAppointment__c> records = [
            SELECT Id,Name,Subject__c,Scheduled_Start__c,Scheduled_End__c,Status__c,
                   Location__c,Location__r.Name,Parent_Record1__r.Name
            FROM ServiceAppointment__c WHERE Scheduled_Start__c>=:fromUtc AND Scheduled_Start__c<:toUtc
            WITH USER_MODE ORDER BY Scheduled_Start__c LIMIT 1000
        ];
        Set<Id> appointmentIds=new Map<Id,ServiceAppointment__c>(records).keySet();
        Map<Id,Assigned_Resource__c> assignments = new Map<Id,Assigned_Resource__c>();
        for(Assigned_Resource__c a:[SELECT Service_Appointment__c,Service_Resource__c,Service_Resource__r.Name FROM Assigned_Resource__c WHERE Service_Appointment__c IN :appointmentIds WITH USER_MODE]) assignments.put(a.Service_Appointment__c,a);
        List<AppointmentRow> output=new List<AppointmentRow>();
        for(ServiceAppointment__c r:records){AppointmentRow x=new AppointmentRow();x.id=r.Id;x.name=r.Name;x.subject=r.Subject__c;x.startUtc=r.Scheduled_Start__c;x.endUtc=r.Scheduled_End__c;x.status=r.Status__c;x.locationId=r.Location__c;x.locationName=r.Location__r?.Name;x.leadName=r.Parent_Record1__r?.Name;Assigned_Resource__c a=assignments.get(r.Id);if(a!=null){x.resourceId=a.Service_Resource__c;x.resourceName=a.Service_Resource__r.Name;}output.add(x);} return output;
    }
    @AuraEnabled public static void reschedule(Id appointmentId,Date targetDate,String startTime){
        ServiceAppointment__c r=locked(appointmentId);Id resourceId=resourceFor(appointmentId);List<List<String>> slots=LadminAIAppointmentAvailabilityService.getAvailableSlots(resourceId,r.Location__c,targetDate);Boolean ok=false;for(List<String>s:slots)if(s[0]==startTime)ok=true;if(!ok)throw safe('The selected time is no longer available.');List<String>p=startTime.split(':');Datetime startUtc=LadminAIAppointmentBusinessTimeService.toUtc(targetDate,Time.newInstance(Integer.valueOf(p[0]),Integer.valueOf(p[1]),0,0));Integer duration=Integer.valueOf(String.valueOf((r.Scheduled_End__c.getTime()-r.Scheduled_Start__c.getTime())/60000));r.Scheduled_Start__c=startUtc;r.Scheduled_End__c=startUtc.addMinutes(duration);r.Status__c='Rescheduled';r.Rescheduled_At__c=System.now();r.Rescheduled_By__c=UserInfo.getUserId();update r;syncEvent(r,false);
    }
    @AuraEnabled public static void cancel(Id appointmentId,String reason){ServiceAppointment__c r=locked(appointmentId);r.Status__c='Cancelled';r.Cancellation_Reason__c=reason;r.Cancelled_At__c=System.now();r.Cancelled_By__c=UserInfo.getUserId();update r;syncEvent(r,true);}
    @AuraEnabled public static void updateStatus(Id appointmentId,String status){Set<String>allowed=new Set<String>{'Booked','Confirmed','Checked In','In Progress','Arrived','Completed','No Show'};if(!allowed.contains(status))throw safe('Select a supported appointment status.');ServiceAppointment__c r=locked(appointmentId);r.Status__c=status;r.Status_Changed_At__c=System.now();r.Status_Changed_By__c=UserInfo.getUserId();if(status=='No Show'){r.No_Show_At__c=System.now();r.No_Show_By__c=UserInfo.getUserId();}update r;}
    private static ServiceAppointment__c locked(Id id){if(id==null)throw safe('An appointment is required.');return[SELECT Id,Scheduled_Start__c,Scheduled_End__c,Status__c,Location__c,LadminAI_Event__c FROM ServiceAppointment__c WHERE Id=:id WITH USER_MODE LIMIT 1 FOR UPDATE];}
    private static Id resourceFor(Id id){return[SELECT Service_Resource__c FROM Assigned_Resource__c WHERE Service_Appointment__c=:id WITH USER_MODE LIMIT 1].Service_Resource__c;}
    private static void syncEvent(ServiceAppointment__c r,Boolean removeIt){if(r.LadminAI_Event__c==null)return;if(removeIt){delete new Event(Id=r.LadminAI_Event__c);}else update new Event(Id=r.LadminAI_Event__c,StartDateTime=r.Scheduled_Start__c,EndDateTime=r.Scheduled_End__c);}
    private static AuraHandledException safe(String m){AuraHandledException e=new AuraHandledException(m);e.setMessage(m);return e;}
    public class AppointmentRow{@AuraEnabled public Id id;@AuraEnabled public String name;@AuraEnabled public String subject;@AuraEnabled public Datetime startUtc;@AuraEnabled public Datetime endUtc;@AuraEnabled public String status;@AuraEnabled public Id resourceId;@AuraEnabled public String resourceName;@AuraEnabled public Id locationId;@AuraEnabled public String locationName;@AuraEnabled public String leadName;}
}
