public with sharing class LadminAIAppointmentTimezoneService {
    @AuraEnabled(cacheable=true)
    public static TimezoneSettings getSettings() {
        User currentUser = [
            SELECT TimeZoneSidKey FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH USER_MODE LIMIT 1
        ];
        TimezoneSettings output = new TimezoneSettings();
        output.businessTimezone = LadminAIAppointmentSettingsService.businessTimeZone();
        output.userTimezone = currentUser.TimeZoneSidKey;
        output.options = getOptions();
        return output;
    }

    @AuraEnabled
    public static TimezoneSettings saveUserTimezone(String timezoneSidKey) {
        Set<String> activeValues = new Set<String>();
        for (TimezoneOption option : getOptions()) activeValues.add(option.value);
        if (String.isBlank(timezoneSidKey) || !activeValues.contains(timezoneSidKey)) {
            throw safeException('Select a valid Salesforce timezone.');
        }
        if (!Schema.User.TimeZoneSidKey.getDescribe().isUpdateable()) {
            throw safeException('You do not have permission to change your display timezone.');
        }
        try {
            Database.update(new User(Id = UserInfo.getUserId(), TimeZoneSidKey = timezoneSidKey), AccessLevel.USER_MODE);
        } catch (DmlException exceptionValue) {
            throw safeException('Your display timezone could not be updated.');
        }
        return getSettings();
    }

    private static List<TimezoneOption> getOptions() {
        List<TimezoneOption> output = new List<TimezoneOption>();
        for (Schema.PicklistEntry entry : Schema.User.TimeZoneSidKey.getDescribe().getPicklistValues()) {
            if (!entry.isActive()) continue;
            TimezoneOption option = new TimezoneOption();
            option.label = entry.getLabel();
            option.value = entry.getValue();
            output.add(option);
        }
        return output;
    }

    private static AuraHandledException safeException(String message) {
        AuraHandledException output = new AuraHandledException(message);
        output.setMessage(message);
        return output;
    }

    public class TimezoneSettings {
        @AuraEnabled public String businessTimezone { get; set; }
        @AuraEnabled public String userTimezone { get; set; }
        @AuraEnabled public List<TimezoneOption> options { get; set; }
    }
    public class TimezoneOption {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
    }
}
