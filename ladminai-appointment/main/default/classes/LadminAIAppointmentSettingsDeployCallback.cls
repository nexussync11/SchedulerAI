public with sharing class LadminAIAppointmentSettingsDeployCallback
    implements Metadata.DeployCallback {
    public void handleResult(
        Metadata.DeployResult result,
        Metadata.DeployCallbackContext context
    ) {
        if (result == null || result.status == Metadata.DeployStatus.Succeeded) return;
        System.debug(LoggingLevel.ERROR,
            'LadminAI appointment settings deployment did not succeed: ' + result.status);
    }
}
