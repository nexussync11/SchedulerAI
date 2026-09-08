@IsTest
private class LadminAIAppointmentEditionServiceTest {
    @IsTest static void enforcesDefaultActiveResourceLimit() {
        Service_Resource__c first = new Service_Resource__c(Name='First', Active__c=true);
        insert first;
        System.assertEquals(false,
            LadminAIAppointmentEditionService.getLimits().canActivateServiceResource);
        try {
            LadminAIAppointmentEditionService.assertResourceActivationAllowed(null);
            System.assert(false, 'Expected the edition limit.');
        } catch (AuraHandledException error) {
            System.assertEquals(
                'Additional active service resources are not available in this edition.',
                error.getMessage());
        }
        LadminAIAppointmentEditionService.assertResourceActivationAllowed(first.Id);
    }

    @IsTest static void enforcesDefaultActiveLocationLimit() {
        Location first = new Location(
            Name='First', LocationType='Site', Scheduler_Managed__c=true,
            Scheduler_Active__c=true
        );
        insert first;
        System.assertEquals(false,
            LadminAIAppointmentEditionService.getLimits().canActivateLocation);
        try {
            LadminAIAppointmentEditionService.assertLocationActivationAllowed(null);
            System.assert(false, 'Expected the edition limit.');
        } catch (AuraHandledException error) {
            System.assertEquals(
                'Additional active locations are not available in this edition.',
                error.getMessage());
        }
        LadminAIAppointmentEditionService.assertLocationActivationAllowed(first.Id);
    }

    @IsTest static void inactiveHistoryDoesNotConsumeLimits() {
        insert new Service_Resource__c(Name='Inactive Resource', Active__c=false);
        insert new Location(Name='Inactive Location', LocationType='Site',
            Scheduler_Managed__c=true, Scheduler_Active__c=false);
        LadminAIAppointmentEditionService.EditionLimits limits =
            LadminAIAppointmentEditionService.getLimits();
        System.assertEquals(true, limits.canActivateServiceResource);
        System.assertEquals(true, limits.canActivateLocation);
    }
}
