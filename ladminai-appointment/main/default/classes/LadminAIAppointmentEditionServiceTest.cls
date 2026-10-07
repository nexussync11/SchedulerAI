@IsTest
private class LadminAIAppointmentEditionServiceTest {
    @IsTest static void enforcesFiveActiveResourcesAcrossServiceAndDirectDml() {
        List<Service_Resource__c> resources = new List<Service_Resource__c>();
        for (Integer index = 1; index <= 5; index++) {
            resources.add(new Service_Resource__c(Name='Resource ' + index, Active__c=true));
        }
        insert resources;
        LadminAIAppointmentEditionService.EditionLimits limits = LadminAIAppointmentEditionService.getLimits();
        System.assertEquals(5, limits.maxActiveServiceResources);
        System.assertEquals(5, limits.activeServiceResources);
        System.assertEquals(false, limits.canActivateServiceResource);
        assertResourceLimitFromService();
        LadminAIAppointmentEditionService.assertResourceActivationAllowed(resources[0].Id);

        Database.SaveResult blockedInsert = Database.insert(new Service_Resource__c(Name='Resource 6', Active__c=true), false);
        System.assertEquals(false, blockedInsert.isSuccess());
        System.assert(blockedInsert.getErrors()[0].getMessage().contains(LadminAIAppointmentEditionService.RESOURCE_LIMIT_MESSAGE));

        Service_Resource__c inactive = new Service_Resource__c(Name='Inactive', Active__c=false);
        insert inactive;
        inactive.Active__c = true;
        Database.SaveResult blockedActivation = Database.update(inactive, false);
        System.assertEquals(false, blockedActivation.isSuccess());
        System.assert(blockedActivation.getErrors()[0].getMessage().contains(LadminAIAppointmentEditionService.RESOURCE_LIMIT_MESSAGE));

        resources[0].Active__c = false;
        update resources[0];
        insert new Service_Resource__c(Name='Replacement', Active__c=true);
        System.assertEquals(5, [SELECT COUNT() FROM Service_Resource__c WHERE Active__c=true]);
    }

    @IsTest static void enforcesTwoManagedActiveLocationsAcrossServiceAndDirectDml() {
        List<Schema.Location> locations = new List<Schema.Location>{
            location('Location 1', true, true), location('Location 2', true, true)
        };
        insert locations;
        LadminAIAppointmentEditionService.EditionLimits limits = LadminAIAppointmentEditionService.getLimits();
        System.assertEquals(2, limits.maxActiveLocations);
        System.assertEquals(2, limits.activeLocations);
        System.assertEquals(false, limits.canActivateLocation);
        assertLocationLimitFromService();
        LadminAIAppointmentEditionService.assertLocationActivationAllowed(locations[0].Id);

        Database.SaveResult blockedInsert = Database.insert(location('Location 3', true, true), false);
        System.assertEquals(false, blockedInsert.isSuccess());
        System.assert(blockedInsert.getErrors()[0].getMessage().contains(LadminAIAppointmentEditionService.LOCATION_LIMIT_MESSAGE));

        Schema.Location inactive = location('Inactive', true, false);
        insert inactive;
        inactive.Scheduler_Active__c = true;
        Database.SaveResult blockedActivation = Database.update(inactive, false);
        System.assertEquals(false, blockedActivation.isSuccess());
        System.assert(blockedActivation.getErrors()[0].getMessage().contains(LadminAIAppointmentEditionService.LOCATION_LIMIT_MESSAGE));

        insert location('Unmanaged Salesforce Location', false, true);
        locations[0].Scheduler_Active__c = false;
        update locations[0];
        insert location('Replacement', true, true);
        System.assertEquals(2, [SELECT COUNT() FROM Location WHERE Scheduler_Managed__c=true AND Scheduler_Active__c=true]);
    }

    @IsTest static void inactiveHistoryDoesNotConsumeLimits() {
        List<Service_Resource__c> inactiveResources = new List<Service_Resource__c>();
        for (Integer index = 0; index < 8; index++) inactiveResources.add(new Service_Resource__c(Name='Inactive Resource ' + index, Active__c=false));
        insert inactiveResources;
        List<Schema.Location> inactiveLocations = new List<Schema.Location>();
        for (Integer index = 0; index < 4; index++) inactiveLocations.add(location('Inactive Location ' + index, true, false));
        insert inactiveLocations;
        LadminAIAppointmentEditionService.EditionLimits limits = LadminAIAppointmentEditionService.getLimits();
        System.assertEquals(true, limits.canActivateServiceResource);
        System.assertEquals(true, limits.canActivateLocation);
        System.assertEquals(0, limits.activeServiceResources);
        System.assertEquals(0, limits.activeLocations);
    }

    @IsTest static void systemContextCountsAreNotReducedByCallerContext() {
        insert new List<Service_Resource__c>{
            new Service_Resource__c(Name='Visible or hidden 1', Active__c=true),
            new Service_Resource__c(Name='Visible or hidden 2', Active__c=true)
        };
        insert new List<Schema.Location>{location('Visible or hidden 1', true, true), location('Visible or hidden 2', true, true)};
        User restrictedUser = new User(
            Alias='limitusr', Email='limit-user@example.test', EmailEncodingKey='UTF-8',
            LastName='Limit User', LanguageLocaleKey='en_US', LocaleSidKey='en_US',
            ProfileId=UserInfo.getProfileId(), TimeZoneSidKey='America/Los_Angeles',
            Username='limit-user-' + System.now().getTime() + '@example.test'
        );
        insert restrictedUser;
        System.runAs(restrictedUser) {
            LadminAIAppointmentEditionService.EditionLimits limits = LadminAIAppointmentEditionService.getLimits();
            System.assertEquals(2, limits.activeLocations);
            System.assertEquals(2, limits.activeServiceResources);
            System.assertEquals(false, limits.canActivateLocation);
            System.assertEquals(true, limits.canActivateServiceResource);
        }
    }

    private static Schema.Location location(String name, Boolean managed, Boolean active) {
        return new Schema.Location(Name=name, LocationType='Site', Scheduler_Managed__c=managed, Scheduler_Active__c=active);
    }

    private static void assertResourceLimitFromService() {
        try {
            LadminAIAppointmentEditionService.assertResourceActivationAllowed(null);
            System.assert(false, 'Expected the resource edition limit.');
        } catch (AuraHandledException error) {
            System.assertEquals('Additional active service resources are not available in this edition.', error.getMessage());
        }
    }

    private static void assertLocationLimitFromService() {
        try {
            LadminAIAppointmentEditionService.assertLocationActivationAllowed(null);
            System.assert(false, 'Expected the location edition limit.');
        } catch (AuraHandledException error) {
            System.assertEquals('Additional active locations are not available in this edition.', error.getMessage());
        }
    }
}
