public with sharing class LadminAIAppointmentSettingsService {
    private static final String FALLBACK_TIME_ZONE = 'UTC';

    public static String businessTimeZone() {
        LadminAI_Appointment_Settings__mdt settings =
            LadminAI_Appointment_Settings__mdt.getInstance('Default');
        if (settings == null || String.isBlank(settings.LadminAI_Default_Time_Zone__c)) {
            return FALLBACK_TIME_ZONE;
        }
        return settings.LadminAI_Default_Time_Zone__c.trim();
    }
}
