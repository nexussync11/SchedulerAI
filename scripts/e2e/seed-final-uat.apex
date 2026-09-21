Schema.Location location = [SELECT Id FROM Location WHERE Scheduler_Managed__c=true AND Scheduler_Active__c=true LIMIT 1];
Service_Resource__c resource = [SELECT Id,Name FROM Service_Resource__c WHERE Active__c=true LIMIT 1];
Appointment_Service__c service = [SELECT Id FROM Appointment_Service__c WHERE Active__c=true LIMIT 1];
List<User> personas = [SELECT Id FROM User WHERE IsActive=true AND Username IN ('ladminai-operations@example.test','ladminai-administrator@example.test') ORDER BY Username];
if (personas.isEmpty()) personas = new List<User>{[SELECT Id FROM User WHERE Id=:UserInfo.getUserId()]};
for (Integer index = 1; index <= 10; index++) {
    String reference = 'FINAL-UAT-' + String.valueOf(index).leftPad(2, '0');
    if ([SELECT COUNT() FROM ServiceAppointment__c WHERE LadminAI_Booking_Reference__c=:reference] > 0) continue;
    Lead customer = new Lead(LastName='Final UAT Patient ' + index,Company='LadminAI Final UAT',OwnerId=personas[Math.mod(index,personas.size())].Id);
    insert customer;
    Integer dayOffset = index <= 5 ? -index : index - 4;
    Datetime startAt = Datetime.newInstance(Date.today().addDays(dayOffset),Time.newInstance(10 + Math.mod(index,4),0,0,0));
    String status = index <= 2 ? 'Completed' : index == 3 ? 'No Show' : index == 4 ? 'Cancelled' : index == 5 ? 'Completed' : 'Booked';
    Event calendarEvent = new Event(Subject='Final UAT Appointment ' + index,WhoId=customer.Id,OwnerId=UserInfo.getUserId(),StartDateTime=startAt,EndDateTime=startAt.addMinutes(30));
    insert calendarEvent;
    ServiceAppointment__c appointment = new ServiceAppointment__c(
        Name='Final UAT Appointment ' + index,Subject__c='Consultation',Parent_Record1__c=customer.Id,
        Location__c=location.Id,Appointment_Service__c=service.Id,Scheduled_Start__c=startAt,
        Scheduled_End__c=startAt.addMinutes(30),Duration__c=30,Status__c=status,
        Booked_By_User__c=personas[Math.mod(index,personas.size())].Id,LadminAI_Event__c=calendarEvent.Id,
        LadminAI_Booking_Reference__c=reference,LadminAI_Idempotency_Key__c='final-uat-' + index
    );
    insert appointment;
    insert new Assigned_Resource__c(Service_Appointment__c=appointment.Id,Service_Resource__c=resource.Id);
}
System.debug('FINAL_UAT_APPOINTMENTS=' + [SELECT COUNT() FROM ServiceAppointment__c WHERE LadminAI_Booking_Reference__c LIKE 'FINAL-UAT-%']);
