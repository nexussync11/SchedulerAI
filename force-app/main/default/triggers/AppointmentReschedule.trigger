trigger AppointmentReschedule on Event (after update) {
    
     if(Trigger.isAfter && Trigger.isUpdate){
        AppointmentRescheduleHandler.handleAfterUpdate2(
            Trigger.new,
            Trigger.oldMap
        );
    }

}