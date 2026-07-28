/**
 * Typed, safe booking result. Internal exception details are never returned.
 */
public class LadminAIAppointmentBookingResult {
    @AuraEnabled public Boolean success { get; set; }
    @AuraEnabled public Boolean idempotentReplay { get; set; }
    @AuraEnabled public Id appointmentId { get; set; }
    @AuraEnabled public Id eventId { get; set; }
    @AuraEnabled public Id assignedResourceId { get; set; }
    @AuraEnabled public String bookingReference { get; set; }
    @AuraEnabled public String userMessage { get; set; }
    @AuraEnabled public String errorCode { get; set; }
    @AuraEnabled public List<LadminAIAppointmentFieldError> fieldErrors { get; set; }
    @AuraEnabled public List<LadminAIAppointmentConflict> conflicts { get; set; }

    public LadminAIAppointmentBookingResult() {
        success = false;
        idempotentReplay = false;
        fieldErrors = new List<LadminAIAppointmentFieldError>();
        conflicts = new List<LadminAIAppointmentConflict>();
    }
}
