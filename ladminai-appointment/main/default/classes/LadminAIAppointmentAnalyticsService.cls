public with sharing class LadminAIAppointmentAnalyticsService {
    @AuraEnabled(cacheable=true)
    public static Snapshot getSnapshot() {
        Date first = Date.today().toStartOfMonth();
        Datetime fromUtc = LadminAIAppointmentBusinessTimeService.toUtc(first, Time.newInstance(0,0,0,0));
        Datetime toUtc = LadminAIAppointmentBusinessTimeService.toUtc(first.addMonths(1), Time.newInstance(0,0,0,0));
        List<ServiceAppointment__c> rows = [SELECT Id,Status__c,Scheduled_Start__c,Location__r.Name,Booked_By_User__r.Name,Appointment_Service__r.Name,Appointment_Mode__c FROM ServiceAppointment__c WHERE Scheduled_Start__c>=:fromUtc AND Scheduled_Start__c<:toUtc WITH USER_MODE ORDER BY Scheduled_Start__c LIMIT 5000];
        Snapshot snapshot = new Snapshot();
        snapshot.appointmentsThisMonth = rows.size(); snapshot.cancelled = 0; snapshot.completed = 0; snapshot.noShows = 0;
        snapshot.locationMetrics = new Map<String,Integer>(); snapshot.resourceMetrics = new Map<String,Integer>(); snapshot.statusMetrics = new Map<String,Integer>();
        snapshot.bookingUserMetrics = new Map<String,Integer>(); snapshot.serviceMetrics = new Map<String,Integer>(); snapshot.bookingSourceMetrics = new Map<String,Integer>();
        Set<Id> appointmentIds = new Map<Id,ServiceAppointment__c>(rows).keySet();
        for (ServiceAppointment__c row : rows) {
            String status = String.isBlank(row.Status__c) ? 'Unspecified' : row.Status__c;
            snapshot.statusMetrics.put(status, value(snapshot.statusMetrics, status) + 1);
            if (status == 'Cancelled' || status == 'Cancel') snapshot.cancelled++;
            if (status == 'Completed') snapshot.completed++;
            if (status == 'No Show') snapshot.noShows++;
            String locationName = row.Location__r?.Name;
            if (locationName != null) snapshot.locationMetrics.put(locationName, value(snapshot.locationMetrics, locationName) + 1);
            String bookingUser = row.Booked_By_User__r?.Name;
            if (String.isBlank(bookingUser)) bookingUser = 'Unattributed / historical';
            snapshot.bookingUserMetrics.put(bookingUser, value(snapshot.bookingUserMetrics, bookingUser) + 1);
            String serviceName = row.Appointment_Service__r?.Name;
            if (String.isBlank(serviceName)) serviceName = 'No service selected';
            snapshot.serviceMetrics.put(serviceName, value(snapshot.serviceMetrics, serviceName) + 1);
            String bookingSource = String.isBlank(row.Appointment_Mode__c) ? 'Unspecified' : row.Appointment_Mode__c;
            snapshot.bookingSourceMetrics.put(bookingSource, value(snapshot.bookingSourceMetrics, bookingSource) + 1);
        }
        if (!appointmentIds.isEmpty()) for (Assigned_Resource__c assignment : [SELECT Service_Resource__r.Name FROM Assigned_Resource__c WHERE Service_Appointment__c IN :appointmentIds WITH USER_MODE]) {
            String resourceName = assignment.Service_Resource__r?.Name;
            if (resourceName != null) snapshot.resourceMetrics.put(resourceName, value(snapshot.resourceMetrics, resourceName) + 1);
        }
        Datetime nowValue = System.now();
        Datetime sevenDays = nowValue.addDays(7);
        snapshot.upcomingNext7Days = [SELECT COUNT() FROM ServiceAppointment__c WHERE Scheduled_Start__c>=:nowValue AND Scheduled_Start__c<:sevenDays AND Status__c NOT IN ('Cancelled','Cancel','Completed','No Show') WITH USER_MODE];
        snapshot.cancellationRate = rate(snapshot.cancelled, rows.size()); snapshot.completionRate = rate(snapshot.completed, rows.size()); snapshot.noShowRate = rate(snapshot.noShows, rows.size());
        return snapshot;
    }
    private static Integer value(Map<String,Integer> values, String key) { return values.containsKey(key) ? values.get(key) : 0; }
    private static Decimal rate(Integer count, Integer total) { return total == 0 ? 0 : Decimal.valueOf(count * 100).divide(total, 1); }
    public class Snapshot {
        @AuraEnabled public Integer appointmentsThisMonth; @AuraEnabled public Integer upcomingNext7Days;
        @AuraEnabled public Integer cancelled; @AuraEnabled public Integer completed; @AuraEnabled public Integer noShows;
        @AuraEnabled public Decimal cancellationRate; @AuraEnabled public Decimal completionRate; @AuraEnabled public Decimal noShowRate;
        @AuraEnabled public Map<String,Integer> locationMetrics; @AuraEnabled public Map<String,Integer> resourceMetrics; @AuraEnabled public Map<String,Integer> statusMetrics;
        @AuraEnabled public Map<String,Integer> bookingUserMetrics; @AuraEnabled public Map<String,Integer> serviceMetrics; @AuraEnabled public Map<String,Integer> bookingSourceMetrics;
    }
}
