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
        LadminAI_Appointment_Settings__mdt current = LadminAI_Appointment_Settings__mdt.getInstance('Default');
        output.internalNotificationsEnabled = current?.LadminAI_Enable_Internal_Notifications__c == true;
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

    @AuraEnabled
    public static String saveBusinessTimezone(String timezoneSidKey) {
        Set<String> activeValues = new Set<String>();
        for (TimezoneOption option : getOptions()) activeValues.add(option.value);
        if (String.isBlank(timezoneSidKey) || !activeValues.contains(timezoneSidKey)) {
            throw safeException('Select a valid Salesforce timezone.');
        }
        if (!FeatureManagement.checkPermission('LadminAI_Configure_Appointment')) {
            throw safeException('You do not have permission to configure appointment settings.');
        }
        LadminAI_Appointment_Settings__mdt current = LadminAI_Appointment_Settings__mdt.getInstance('Default');
        return deploySettings(current, timezoneSidKey, current.LadminAI_Enable_Internal_Notifications__c);
    }

    @AuraEnabled
    public static String saveInternalNotifications(Boolean enabled) {
        if (!FeatureManagement.checkPermission('LadminAI_Configure_Appointment')) throw safeException('You do not have permission to configure appointment settings.');
        LadminAI_Appointment_Settings__mdt current = LadminAI_Appointment_Settings__mdt.getInstance('Default');
        return deploySettings(current, current.LadminAI_Default_Time_Zone__c, enabled == true);
    }

    private static String deploySettings(LadminAI_Appointment_Settings__mdt current, String timezoneSidKey, Boolean notificationsEnabled) {
        Metadata.CustomMetadata record = new Metadata.CustomMetadata();
        record.fullName = 'LadminAI_Appointment_Settings.Default';
        record.label = 'Default';
        addValue(record, 'LadminAI_Default_Time_Zone__c', timezoneSidKey);
        addValue(record, 'LadminAI_Default_Slot_Minutes__c', current.LadminAI_Default_Slot_Minutes__c);
        addValue(record, 'LadminAI_Booking_Horizon_Days__c', current.LadminAI_Booking_Horizon_Days__c);
        addValue(record, 'LadminAI_Minimum_Lead_Time_Minutes__c', current.LadminAI_Minimum_Lead_Time_Minutes__c);
        addValue(record, 'LadminAI_Create_Salesforce_Event__c', current.LadminAI_Create_Salesforce_Event__c);
        addValue(record, 'LadminAI_Default_Booking_Status__c', current.LadminAI_Default_Booking_Status__c);
        addValue(record, 'LadminAI_Enable_Parent_Adapter__c', current.LadminAI_Enable_Parent_Adapter__c);
        addValue(record, 'LadminAI_Enable_Compatibility_Aura__c', current.LadminAI_Enable_Compatibility_Aura__c);
        addValue(record, 'LadminAI_Enable_AI_Insights__c', current.LadminAI_Enable_AI_Insights__c);
        addValue(record, 'LadminAI_Enable_Internal_Notifications__c', notificationsEnabled);
        addValue(record, 'LadminAI_OpenAI_Named_Credential__c', current.LadminAI_OpenAI_Named_Credential__c);
        addValue(record, 'LadminAI_Max_Active_Locations__c', current.LadminAI_Max_Active_Locations__c);
        addValue(record, 'LadminAI_Max_Active_Service_Resources__c', current.LadminAI_Max_Active_Service_Resources__c);
        Metadata.DeployContainer container = new Metadata.DeployContainer();
        container.addMetadata(record);
        return String.valueOf(Metadata.Operations.enqueueDeployment(
            container, new LadminAISettingsDeployCallback()
        ));
    }

    private static void addValue(Metadata.CustomMetadata record, String fieldName, Object value) {
        Metadata.CustomMetadataValue item = new Metadata.CustomMetadataValue();
        item.field = fieldName;
        item.value = value;
        record.values.add(item);
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
        @AuraEnabled public Boolean internalNotificationsEnabled { get; set; }
        @AuraEnabled public List<TimezoneOption> options { get; set; }
    }
    public class TimezoneOption {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
    }
}
