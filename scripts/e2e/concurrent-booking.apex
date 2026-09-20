Lead leadRecord = [SELECT Id FROM Lead WHERE LastName = 'LadminAI E2E Lead' AND Company = 'LadminAI E2E' LIMIT 1];
Schema.Location locationRecord = [SELECT Id FROM Location WHERE Scheduler_Managed__c = true AND Scheduler_Active__c = true LIMIT 1];
Scheduler_Location_Resource__c association = [
    SELECT Service_Resource__c FROM Scheduler_Location_Resource__c
    WHERE Location__c = :locationRecord.Id AND Active__c = true AND Service_Resource__r.Active__c = true LIMIT 1
];
Datetime startAt = Datetime.newInstanceGmt(2027, 3, 15, 12, 0, 0);
LadminAIAppointmentBookingRequest request = new LadminAIAppointmentBookingRequest();
request.parentRecordId = leadRecord.Id;
request.serviceResourceId = association.Service_Resource__c;
request.locationId = locationRecord.Id;
request.appointmentDate = startAt.date();
request.requestedStart = startAt;
request.requestedEnd = startAt.addMinutes(30);
request.bookingStatus = 'Booked';
request.subject = 'LadminAI concurrency validation';
request.idempotencyKey = 'concurrency-' + String.valueOf(Crypto.getRandomLong()).replace('-', '0');
LadminAIAppointmentBookingResult result = LadminAIAppointmentBookingService.bookAppointment(request);
System.debug('CONCURRENCY_RESULT=' + result.success + ':' + result.errorCode);
