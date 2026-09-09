@IsTest private class LadminAINotificationServiceTest {
    @IsTest static void disabledNotificationsDoNotQueueWork() {
        LadminAINotificationService.enabledOverride = false;
        Test.startTest(); LadminAINotificationService.notifyAsync(null, 'booked'); Test.stopTest();
        System.assertEquals(0, Limits.getQueueableJobs());
    }
}
