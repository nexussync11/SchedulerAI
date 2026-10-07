trigger LadminAIAppointmentResourceLimit on Service_Resource__c (
    before insert,
    before update,
    after undelete
) {
    if (Trigger.isBefore) {
        LadminAIAppointmentEditionService.enforceResourceChanges(
            Trigger.new,
            Trigger.isUpdate ? Trigger.oldMap : null
        );
    } else {
        LadminAIAppointmentEditionService.enforceCurrentResourceLimit(Trigger.new);
    }
}
