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

    @AuraEnabled
    public static LadminAIAppointmentBookingResult bookFromSlot(
        Id leadId,
        Id locationId,
        Id serviceResourceId,
        Date appointmentDate,
        String startTime,
        String subject
    ) {
        if (appointmentDate == null || String.isBlank(startTime)) {
            return invalidSlotResult();
        }
        List<String> parts = startTime.split(':');
        if (parts.size() < 2) return invalidSlotResult();
        Time localTime;
        try {
            localTime = Time.newInstance(
                Integer.valueOf(parts[0]), Integer.valueOf(parts[1]), 0, 0
            );
        } catch (Exception ignored) {
            return invalidSlotResult();
        }
        Datetime requestedStart =
            LadminAIAppointmentBusinessTimeService.toUtc(appointmentDate, localTime, locationId);
        Integer durationMinutes = 30;
        LadminAI_Appointment_Settings__mdt settings =
            LadminAI_Appointment_Settings__mdt.getInstance('Default');
        if (settings?.LadminAI_Default_Slot_Minutes__c != null) {
            durationMinutes = settings.LadminAI_Default_Slot_Minutes__c.intValue();
        }
        LadminAIAppointmentBookingRequest request =
            new LadminAIAppointmentBookingRequest();
        request.parentRecordId = leadId;
        request.locationId = locationId;
        request.serviceResourceId = serviceResourceId;
        request.appointmentDate = appointmentDate;
        request.requestedStart = requestedStart;
        request.requestedEnd = requestedStart.addMinutes(durationMinutes);
        request.bookingStatus = 'Booked';
        request.subject = subject;
        request.idempotencyKey = EncodingUtil.convertToHex(
            Crypto.generateDigest('SHA-256', Blob.valueOf(
                String.valueOf(UserInfo.getUserId()) + ':' + String.valueOf(Datetime.now().getTime())
            ))
        );
        return LadminAIAppointmentBookingService.bookAppointment(request);
    }

    private static LadminAIAppointmentBookingResult invalidSlotResult() {
        LadminAIAppointmentBookingResult result =
            new LadminAIAppointmentBookingResult();
        result.success = false;
        result.errorCode = 'INVALID_SLOT';
        result.userMessage = 'Select a valid appointment date and time.';
        return result;
    }
}
