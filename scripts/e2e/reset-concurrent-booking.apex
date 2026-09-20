Datetime targetStart = Datetime.newInstanceGmt(2027, 3, 15, 12, 0, 0);
for (ServiceAppointment__c appointment : [
    SELECT Id, Status__c FROM ServiceAppointment__c
    WHERE Subject__c = 'LadminAI concurrency validation'
        AND Scheduled_Start__c = :targetStart
        AND Status__c != 'Cancelled'
]) {
    LadminAIAppointmentCommandService.cancel(appointment.Id, 'Reset synthetic concurrency test');
}
