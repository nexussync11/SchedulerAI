LadminAIAppointmentAIInsightsService.InsightResult result = LadminAIAppointmentAIInsightsService.getInsights();
System.debug('LADMINAI_AI_ENABLED=' + result.enabled);
System.debug('LADMINAI_AI_RESPONSE_LENGTH=' + (result.message == null ? 0 : result.message.length()));
