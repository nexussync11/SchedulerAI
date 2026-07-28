/**
 * Safe field-level validation detail for a booking request.
 */
public class LadminAIAppointmentFieldError {
    @AuraEnabled public String fieldName { get; set; }
    @AuraEnabled public String message { get; set; }

    public LadminAIAppointmentFieldError(String fieldName, String message) {
        this.fieldName = fieldName;
        this.message = message;
    }
}
