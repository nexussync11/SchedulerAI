/**
 * Thin Lightning boundary. All validation and DML remain in the service.
 */
public with sharing class LadminAIAppointmentBookingController {
    @AuraEnabled
    public static LadminAIAppointmentBookingResult bookAppointment(
        LadminAIAppointmentBookingRequest request
    ) {
        return LadminAIAppointmentBookingService.bookAppointment(request);
    }

    @AuraEnabled
    public static List<LadminAIAppointmentBookingResult> bookAppointments(
        List<LadminAIAppointmentBookingRequest> requests
    ) {
        return LadminAIAppointmentBookingService.bookAppointments(requests);
    }
}
