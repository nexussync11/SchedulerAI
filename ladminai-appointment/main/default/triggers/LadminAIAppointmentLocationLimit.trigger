trigger LadminAIAppointmentLocationLimit on Location (
    before insert,
    before update,
    after undelete
) {
    if (Trigger.isBefore) {
        LadminAIAppointmentEditionService.enforceLocationChanges(
            Trigger.new,
            Trigger.isUpdate ? Trigger.oldMap : null
        );
    } else {
        LadminAIAppointmentEditionService.enforceCurrentLocationLimit(Trigger.new);
    }
}
