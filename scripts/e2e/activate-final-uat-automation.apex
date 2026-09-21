for (CronTrigger job : [SELECT Id,CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name IN ('LadminAI Appointment Reminders','LadminAI Event Reconciliation')]) System.abortJob(job.Id);
System.schedule('LadminAI Appointment Reminders','0 0 * * * ?',new LadminAIAppointmentReminderScheduler());
System.schedule('LadminAI Event Reconciliation','0 15 * * * ?',new LadminAIEventReconciliationService());
System.debug('LADMINAI_AUTOMATION_JOBS=' + [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name IN ('LadminAI Appointment Reminders','LadminAI Event Reconciliation')]);
