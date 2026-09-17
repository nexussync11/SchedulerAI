public with sharing class LadminAIAppointmentSettingsService {
    private static final String FALLBACK_TIME_ZONE = 'UTC';
    @TestVisible private static Integer cancellationCutoffOverride;
    @TestVisible private static Integer rescheduleCutoffOverride;

    public static String businessTimeZone() {
        LadminAI_Appointment_Settings__mdt settings =
            LadminAI_Appointment_Settings__mdt.getInstance('Default');
        if (settings == null || String.isBlank(settings.LadminAI_Default_Time_Zone__c)) {
            return FALLBACK_TIME_ZONE;
        }
        return settings.LadminAI_Default_Time_Zone__c.trim();
    }

    public static Integer cancellationCutoffMinutes() {
        if (Test.isRunningTest() && cancellationCutoffOverride != null) return cancellationCutoffOverride;
        LadminAI_Appointment_Settings__mdt settings = LadminAI_Appointment_Settings__mdt.getInstance('Default');
        return nonNegativeInteger(settings?.LadminAI_Cancellation_Cutoff_Minutes__c);
    }

    public static Integer rescheduleCutoffMinutes() {
        if (Test.isRunningTest() && rescheduleCutoffOverride != null) return rescheduleCutoffOverride;
        LadminAI_Appointment_Settings__mdt settings = LadminAI_Appointment_Settings__mdt.getInstance('Default');
        return nonNegativeInteger(settings?.LadminAI_Reschedule_Cutoff_Minutes__c);
    }

    private static Integer nonNegativeInteger(Decimal value) {
        return value == null ? 0 : Math.max(0, value.intValue());
    }
}
