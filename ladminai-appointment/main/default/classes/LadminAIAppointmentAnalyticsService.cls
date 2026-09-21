public with sharing class LadminAIAppointmentAnalyticsService {
    @AuraEnabled(cacheable=true)
    public static List<DetailRow> getDrilldown(String dimension, String value) {
        Date first = Date.today().toStartOfMonth();
        return getDrilldownForRange(dimension, value, first, first.addMonths(1).addDays(-1));
    }
    @AuraEnabled(cacheable=true)
    public static List<DetailRow> getDrilldownForRange(String dimension, String value, Date startDate, Date endDate) {
        Date first = startDate == null ? Date.today().toStartOfMonth() : startDate;
        Date last = endDate == null ? first.addMonths(1).addDays(-1) : endDate;
        if (last < first || first.daysBetween(last) > 366) throw new AuraHandledException('Select a date range of 367 days or less.');
        Datetime fromUtc = LadminAIAppointmentBusinessTimeService.toUtc(first, Time.newInstance(0,0,0,0));
        Datetime toUtc = LadminAIAppointmentBusinessTimeService.toUtc(last.addDays(1), Time.newInstance(0,0,0,0));
        if (dimension == 'upcoming') { fromUtc = System.now(); toUtc = fromUtc.addDays(7); }
        List<ServiceAppointment__c> records = [SELECT Id,Name,Subject__c,Status__c,Scheduled_Start__c,Scheduled_End__c,Location__r.Name,Parent_Record1__r.Name,Booked_By_User__r.Name,Appointment_Service__r.Name,Appointment_Mode__c FROM ServiceAppointment__c WHERE Scheduled_Start__c>=:fromUtc AND Scheduled_Start__c<:toUtc WITH USER_MODE ORDER BY Scheduled_Start__c DESC LIMIT 5000];
        Set<Id> appointmentIds = new Map<Id,ServiceAppointment__c>(records).keySet();
        Map<Id,String> resources = new Map<Id,String>();
        if (!appointmentIds.isEmpty()) for (Assigned_Resource__c assignment : [SELECT Service_Appointment__c,Service_Resource__r.Name FROM Assigned_Resource__c WHERE Service_Appointment__c IN :appointmentIds WITH USER_MODE]) resources.put(assignment.Service_Appointment__c, assignment.Service_Resource__r?.Name);
        List<DetailRow> output = new List<DetailRow>();
        for (ServiceAppointment__c recordValue : records) {
            String status = String.isBlank(recordValue.Status__c) ? 'Unspecified' : recordValue.Status__c;
            String locationName = recordValue.Location__r?.Name;
            String resourceName = resources.get(recordValue.Id);
            String bookingUser = String.isBlank(recordValue.Booked_By_User__r?.Name) ? 'Unattributed / historical' : recordValue.Booked_By_User__r.Name;
            String serviceName = String.isBlank(recordValue.Appointment_Service__r?.Name) ? 'No service selected' : recordValue.Appointment_Service__r.Name;
            String source = String.isBlank(recordValue.Appointment_Mode__c) ? 'Unspecified' : recordValue.Appointment_Mode__c;
            Boolean includeRow = dimension == null || dimension == 'all' || dimension == 'upcoming';
            if (dimension == 'status') includeRow = value == 'Cancelled' ? new Set<String>{'Cancel','Cancelled'}.contains(status) : status == value;
            if (dimension == 'location') includeRow = locationName == value;
            if (dimension == 'resource') includeRow = resourceName == value;
            if (dimension == 'user') includeRow = bookingUser == value;
            if (dimension == 'service') includeRow = serviceName == value;
            if (dimension == 'source') includeRow = source == value;
            if (!includeRow) continue;
            DetailRow row = new DetailRow();
            row.id=recordValue.Id; row.name=recordValue.Name; row.subject=recordValue.Subject__c; row.customer=recordValue.Parent_Record1__r?.Name; row.resource=resourceName; row.location=locationName; row.bookedBy=bookingUser; row.service=serviceName; row.source=source; row.startUtc=recordValue.Scheduled_Start__c; row.endUtc=recordValue.Scheduled_End__c; row.status=status;
            output.add(row);
        }
        return output;
    }
    @AuraEnabled(cacheable=true)
    public static Snapshot getSnapshot() {
        Date first = Date.today().toStartOfMonth();
        return getSnapshotForRange(first, first.addMonths(1).addDays(-1));
    }
    @AuraEnabled(cacheable=true)
    public static Snapshot getSnapshotForRange(Date startDate, Date endDate) {
        Date first = startDate == null ? Date.today().toStartOfMonth() : startDate;
        Date last = endDate == null ? first.addMonths(1).addDays(-1) : endDate;
        if (last < first || first.daysBetween(last) > 366) throw new AuraHandledException('Select a date range of 367 days or less.');
        Datetime fromUtc = LadminAIAppointmentBusinessTimeService.toUtc(first, Time.newInstance(0,0,0,0));
        Datetime toUtc = LadminAIAppointmentBusinessTimeService.toUtc(last.addDays(1), Time.newInstance(0,0,0,0));
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
        Integer days = first.daysBetween(last) + 1;
        Datetime previousFrom = LadminAIAppointmentBusinessTimeService.toUtc(first.addDays(-days), Time.newInstance(0,0,0,0));
        snapshot.previousPeriodAppointments = [SELECT COUNT() FROM ServiceAppointment__c WHERE Scheduled_Start__c>=:previousFrom AND Scheduled_Start__c<:fromUtc WITH USER_MODE];
        snapshot.periodChangePercent = snapshot.previousPeriodAppointments == 0 ? (rows.isEmpty() ? 0 : 100) : Decimal.valueOf((rows.size() - snapshot.previousPeriodAppointments) * 100).divide(snapshot.previousPeriodAppointments, 1);
        snapshot.cancellationRate = rate(snapshot.cancelled, rows.size()); snapshot.completionRate = rate(snapshot.completed, rows.size()); snapshot.noShowRate = rate(snapshot.noShows, rows.size());
        return snapshot;
    }
    private static Integer value(Map<String,Integer> values, String key) { return values.containsKey(key) ? values.get(key) : 0; }
    private static Decimal rate(Integer count, Integer total) { return total == 0 ? 0 : Decimal.valueOf(count * 100).divide(total, 1); }
    public class Snapshot {
        @AuraEnabled public Integer appointmentsThisMonth; @AuraEnabled public Integer upcomingNext7Days;
        @AuraEnabled public Integer previousPeriodAppointments; @AuraEnabled public Decimal periodChangePercent;
        @AuraEnabled public Integer cancelled; @AuraEnabled public Integer completed; @AuraEnabled public Integer noShows;
        @AuraEnabled public Decimal cancellationRate; @AuraEnabled public Decimal completionRate; @AuraEnabled public Decimal noShowRate;
        @AuraEnabled public Map<String,Integer> locationMetrics; @AuraEnabled public Map<String,Integer> resourceMetrics; @AuraEnabled public Map<String,Integer> statusMetrics;
        @AuraEnabled public Map<String,Integer> bookingUserMetrics; @AuraEnabled public Map<String,Integer> serviceMetrics; @AuraEnabled public Map<String,Integer> bookingSourceMetrics;
    }
    public class DetailRow {
        @AuraEnabled public Id id; @AuraEnabled public String name; @AuraEnabled public String subject;
        @AuraEnabled public String customer; @AuraEnabled public String resource; @AuraEnabled public String location;
        @AuraEnabled public String bookedBy; @AuraEnabled public String service; @AuraEnabled public String source;
        @AuraEnabled public Datetime startUtc; @AuraEnabled public Datetime endUtc; @AuraEnabled public String status;
    }
}
