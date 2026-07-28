trigger AppointmentTracking on ServiceAppointment__c (after update) {

    if(Trigger.isAfter && Trigger.isUpdate){
        AppointmentTrackingHandler.handleAfterUpdate(
            Trigger.new,
            Trigger.oldMap
        );
    }
}