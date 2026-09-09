public with sharing class LadminAIAppointmentAIInsightsService {
    @AuraEnabled(cacheable=false)
    public static InsightResult getInsights() {
        InsightResult output = new InsightResult();
        LadminAI_Appointment_Settings__mdt settings = LadminAI_Appointment_Settings__mdt.getInstance('Default');
        if (settings == null || settings.LadminAI_Enable_AI_Insights__c != true || String.isBlank(settings.LadminAI_OpenAI_Named_Credential__c)) {
            output.enabled = false;
            output.message = 'Connect OpenAI to enable AI Smart Insights.';
            return output;
        }
        try {
            LadminAIAppointmentAnalyticsService.Snapshot metrics = LadminAIAppointmentAnalyticsService.getSnapshot();
            Map<String,Object> input = new Map<String,Object>{
                'appointmentsThisMonth' => metrics.appointmentsThisMonth,
                'cancellationRate' => metrics.cancellationRate,
                'locationMetrics' => metrics.locationMetrics
            };
            HttpRequest requestValue = new HttpRequest();
            requestValue.setEndpoint('callout:' + settings.LadminAI_OpenAI_Named_Credential__c.trim() + '/v1/responses');
            requestValue.setMethod('POST');
            requestValue.setHeader('Content-Type', 'application/json');
            requestValue.setTimeout(15000);
            requestValue.setBody(JSON.serialize(new Map<String,Object>{
                'model' => 'gpt-5-mini',
                'instructions' => 'Return three concise, read-only appointment operations insights. Do not infer personal information.',
                'input' => JSON.serialize(input)
            }));
            HttpResponse responseValue = new Http().send(requestValue);
            if (responseValue.getStatusCode() < 200 || responseValue.getStatusCode() > 299) throw new CalloutException('AI service unavailable');
            output.message = extractText(responseValue.getBody());
            if (String.isBlank(output.message)) output.message = 'No insights were returned. Refresh to try again.';
            output.enabled = true;
        } catch (Exception ignored) {
            output.enabled = false;
            output.message = 'AI Smart Insights are temporarily unavailable. Appointment analytics and scheduling are unaffected.';
        }
        return output;
    }

    @TestVisible
    private static String extractText(String responseBody) {
        Map<String,Object> body = (Map<String,Object>)JSON.deserializeUntyped(responseBody);
        List<Object> outputs = (List<Object>)body.get('output');
        if (outputs == null) return null;
        List<String> textValues = new List<String>();
        for (Object outputItem : outputs) {
            Map<String,Object> item = (Map<String,Object>)outputItem;
            List<Object> content = (List<Object>)item.get('content');
            if (content == null) continue;
            for (Object contentItem : content) {
                Map<String,Object> value = (Map<String,Object>)contentItem;
                if (value.get('type') == 'output_text' && !String.isBlank((String)value.get('text'))) textValues.add((String)value.get('text'));
            }
        }
        return String.join(textValues, '\n');
    }

    public class InsightResult {
        @AuraEnabled public Boolean enabled;
        @AuraEnabled public String message;
    }
}
