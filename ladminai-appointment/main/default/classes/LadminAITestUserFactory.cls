@IsTest
public class LadminAITestUserFactory {
    private static final Set<String> SCHEDULER_PERMISSION_SETS = new Set<String>{
        'LadminAI_Analytics_Viewer',
        'LadminAI_Appointment_Booker',
        'LadminAI_Appointment_Configurator',
        'LadminAI_Availability_Manager',
        'LadminAI_Location_Administrator',
        'LadminAI_Resource_Administrator'
    };

    public static User createSchedulerUser(String marker) {
        User runningUser = [
            SELECT ProfileId, TimeZoneSidKey, LocaleSidKey, EmailEncodingKey,
                LanguageLocaleKey
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
        String uniqueValue = marker + '-' + String.valueOf(Datetime.now().getTime()) + '-'
            + String.valueOf(Crypto.getRandomLong()).replace('-', '0');
        User testUser = new User(
            Alias = marker.left(8),
            LastName = 'Scheduler ' + marker,
            Email = uniqueValue + '@example.test',
            Username = uniqueValue + '@example.test',
            ProfileId = runningUser.ProfileId,
            TimeZoneSidKey = runningUser.TimeZoneSidKey,
            LocaleSidKey = runningUser.LocaleSidKey,
            EmailEncodingKey = runningUser.EmailEncodingKey,
            LanguageLocaleKey = runningUser.LanguageLocaleKey
        );
        insert testUser;

        List<PermissionSet> packagedPermissionSets = [
            SELECT Id, Name, NamespacePrefix
            FROM PermissionSet
            WHERE Name IN :SCHEDULER_PERMISSION_SETS
                AND IsOwnedByProfile = false
        ];
        System.assertEquals(
            SCHEDULER_PERMISSION_SETS.size(), packagedPermissionSets.size(),
            'Every packaged Scheduler permission set must be resolvable in both namespaced and unnamespaced tests.'
        );
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (PermissionSet permissionValue : packagedPermissionSets) {
            assignments.add(new PermissionSetAssignment(
                AssigneeId = testUser.Id,
                PermissionSetId = permissionValue.Id
            ));
        }
        insert assignments;
        return testUser;
    }

    public static User createUnpermissionedUser(String marker) {
        User runningUser = [
            SELECT ProfileId, TimeZoneSidKey, LocaleSidKey, EmailEncodingKey,
                LanguageLocaleKey
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
        String uniqueValue = marker + '-' + String.valueOf(Datetime.now().getTime()) + '-'
            + String.valueOf(Crypto.getRandomLong()).replace('-', '0');
        User testUser = new User(
            Alias = marker.left(8), LastName = 'Unpermissioned ' + marker,
            Email = uniqueValue + '@example.test', Username = uniqueValue + '@example.test',
            ProfileId = runningUser.ProfileId, TimeZoneSidKey = runningUser.TimeZoneSidKey,
            LocaleSidKey = runningUser.LocaleSidKey,
            EmailEncodingKey = runningUser.EmailEncodingKey,
            LanguageLocaleKey = runningUser.LanguageLocaleKey
        );
        insert testUser;
        return testUser;
    }
}
