public with sharing class LadminAINotificationService implements Queueable {
    @TestVisible private static Boolean enabledOverride;
    private Id appointmentId;
    private String actionName;
    private Integer attempt;
    public LadminAINotificationService(Id appointmentId, String actionName) { this(appointmentId, actionName, 1); }
    private LadminAINotificationService(Id appointmentId, String actionName, Integer attempt) { this.appointmentId = appointmentId; this.actionName = actionName; this.attempt = attempt; }
    public static void notifyAsync(Id appointmentId, String actionName) {
        if (appointmentId == null || !isEnabled()) return;
        try {
            updateTracking(appointmentId, 'Pending', null, 0);
            System.enqueueJob(new LadminAINotificationService(appointmentId, actionName));
        }
        catch (Exception ignored) { System.debug(LoggingLevel.WARN, 'LadminAI internal notification could not be queued.'); }
    }
    public void execute(QueueableContext context) {
        try {
            List<ServiceAppointment__c> rows = [SELECT Name,Subject__c,Scheduled_Start__c,Scheduled_End__c,Status__c,Booked_By_User__c,Location__r.Name FROM ServiceAppointment__c WHERE Id=:appointmentId LIMIT 1];
            if (rows.isEmpty() || rows[0].Booked_By_User__c == null) return;
            ServiceAppointment__c row = rows[0];
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setTargetObjectId(row.Booked_By_User__c); message.setSaveAsActivity(false);
            message.setSubject('Appointment ' + actionName + ': ' + row.Name);
            message.setPlainTextBody('Appointment: ' + row.Name + '\nSubject: ' + row.Subject__c + '\nStatus: ' + row.Status__c + '\nLocation: ' + row.Location__r?.Name + '\nStart: ' + row.Scheduled_Start__c.format() + '\nEnd: ' + row.Scheduled_End__c.format());
            Messaging.SendEmailResult result = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{message}, false)[0];
            if (!result.isSuccess()) throw new NotificationException(result.getErrors()[0].getMessage());
            updateTracking(appointmentId, 'Sent', null, attempt);
        } catch (Exception failure) {
            updateTracking(appointmentId, 'Failed', failure.getMessage(), attempt);
            if (attempt < 2 && !Test.isRunningTest()) System.enqueueJob(new LadminAINotificationService(appointmentId, actionName, attempt + 1));
            System.debug(LoggingLevel.WARN, 'LadminAI internal notification failed: ' + failure.getMessage());
        }
    }
    private static Boolean isEnabled() {
        if (Test.isRunningTest() && enabledOverride != null) return enabledOverride;
        LadminAI_Appointment_Settings__mdt settings = LadminAI_Appointment_Settings__mdt.getInstance('Default');
        return settings?.LadminAI_Enable_Internal_Notifications__c == true;
    }
    private static void updateTracking(Id appointmentId, String status, String errorMessage, Integer attempts) {
        try {
            update new ServiceAppointment__c(
                Id = appointmentId, Notification_Status__c = status,
                Notification_Last_Attempt__c = System.now(), Notification_Attempts__c = attempts,
                Notification_Error__c = errorMessage == null ? null : errorMessage.left(255)
            );
        } catch (Exception ignored) { System.debug(LoggingLevel.WARN, 'Notification tracking could not be updated.'); }
    }
    public class NotificationException extends Exception {}
}
