/**
 * Minimal conflict detail. It intentionally excludes parent and patient data.
 */
public class LadminAIAppointmentConflict {
    @AuraEnabled public Id appointmentId { get; set; }
    @AuraEnabled public Datetime scheduledStart { get; set; }
    @AuraEnabled public Datetime scheduledEnd { get; set; }

    public LadminAIAppointmentConflict(
        Id appointmentId,
        Datetime scheduledStart,
        Datetime scheduledEnd
    ) {
        this.appointmentId = appointmentId;
        this.scheduledStart = scheduledStart;
        this.scheduledEnd = scheduledEnd;
    }
}
