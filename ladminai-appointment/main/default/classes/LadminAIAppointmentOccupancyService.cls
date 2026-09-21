/**
 * Internal scheduling invariant. Occupancy must include appointments that the
 * caller cannot read, otherwise record sharing can allow double bookings.
 * Do not expose these rows directly to the UI.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class LadminAIAppointmentOccupancyService {
    public static List<Assigned_Resource__c> forResource(
        Id resourceId, Datetime rangeStart, Datetime rangeEnd
    ) {
        return [
            SELECT Service_Appointment__c,
                Service_Appointment__r.Scheduled_Start__c,
                Service_Appointment__r.Scheduled_End__c,
                Service_Appointment__r.Status__c
            FROM Assigned_Resource__c
            WHERE Service_Resource__c = :resourceId
                AND Service_Appointment__r.Scheduled_Start__c < :rangeEnd
                AND Service_Appointment__r.Scheduled_End__c > :rangeStart
        ];
    }
}
