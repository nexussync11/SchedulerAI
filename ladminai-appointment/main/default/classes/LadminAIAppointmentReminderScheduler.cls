public without sharing class LadminAIAppointmentReminderScheduler implements Schedulable {
    public void execute(SchedulableContext context) { sendDueReminders(); }
    public static Integer sendDueReminders() {
        LadminAI_Appointment_Settings__mdt settings = LadminAI_Appointment_Settings__mdt.getInstance('Default');
        if (settings?.LadminAI_Enable_Customer_Notifications__c != true) return 0;
        Integer leadHours = settings.LadminAI_Reminder_Lead_Hours__c == null ? 24 : settings.LadminAI_Reminder_Lead_Hours__c.intValue();
        Datetime fromTime = System.now().addHours(leadHours).addMinutes(-30);
        Datetime toTime = System.now().addHours(leadHours).addMinutes(30);
        List<ServiceAppointment__c> due = [
            SELECT Id FROM ServiceAppointment__c
            WHERE Reminder_Sent__c = false AND Scheduled_Start__c >= :fromTime AND Scheduled_Start__c < :toTime
                AND Status__c NOT IN ('Cancelled','Cancel','Completed','No Show') LIMIT 200
        ];
        for (ServiceAppointment__c row : due) {
            LadminAINotificationService.notifyAsync(row.Id, 'reminder');
            row.Reminder_Sent__c = true;
        }
        if (!due.isEmpty()) update due;
        return due.size();
    }
}
