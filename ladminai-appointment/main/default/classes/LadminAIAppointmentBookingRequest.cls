/**
 * Typed input contract shared by Aura, LWC, and Apex callers.
 */
public class LadminAIAppointmentBookingRequest {
    @AuraEnabled public Id parentRecordId { get; set; }
    @AuraEnabled public Id serviceResourceId { get; set; }
    @AuraEnabled public Id locationId { get; set; }
    @AuraEnabled public Date appointmentDate { get; set; }
    @AuraEnabled public Datetime requestedStart { get; set; }
    @AuraEnabled public Datetime requestedEnd { get; set; }
    @AuraEnabled public String bookingSource { get; set; }
    @AuraEnabled public String bookingStatus { get; set; }
    @AuraEnabled public String subject { get; set; }
    @AuraEnabled public String appointmentType { get; set; }
    @AuraEnabled public String idempotencyKey { get; set; }
}
