public with sharing class AvailabilityManagerController {
    @AuraEnabled(cacheable=true)
    public static List<Service_Resource__c> getAllServiceResources() {
        return [SELECT Id, Name FROM Service_Resource__c WHERE Active__c = true ORDER BY Name LIMIT 200];
    }
    @AuraEnabled(cacheable=true)
    public static Map<String,String> getMyServiceResource() {
        Map<String,String> out = new Map<String,String>();
        List<Service_Resource__c> res = [SELECT Id, Name FROM Service_Resource__c WHERE RelatedRecordId__c = :UserInfo.getUserId() LIMIT 1];
        if (!res.isEmpty()) {
            out.put('Id', res[0].Id);
            out.put('Name', res[0].Name);
        }
        return out;
    }

    @AuraEnabled(cacheable=true)
    public static List<Resource_Availability__c> getAvailability(Id serviceResourceId) {
        if (serviceResourceId == null) return new List<Resource_Availability__c>();
        return [
            SELECT Id, Day_Of_Week__c, Start_Time__c, End_Time__c, Break_Start__c, Break_End__c, Is_Active__c
            FROM Resource_Availability__c
            WHERE Service_Resource__c = :serviceResourceId
        ];
    }

@AuraEnabled
public static Id saveAvailabilityV2(Id serviceResourceId, List<Map<String,Object>> dayRecords) {
    if (serviceResourceId == null) {
        throw new AuraHandledException('Missing Service Resource Id');
    }
    String srName = 'Resource-' + String.valueOf(serviceResourceId);
    try {
        Service_Resource__c sr = [
            SELECT Id, Name 
            FROM Service_Resource__c 
            WHERE Id = :serviceResourceId 
            LIMIT 1
        ];
        if (sr != null && !String.isBlank(sr.Name)) {
            srName = sr.Name;
        }
    } catch (Exception e) {
        System.debug('Could not fetch Service Resource name: ' + e.getMessage());
    }

    // 2️⃣ Find or create the parent schedule record
    Resource_Availability_Schedule__c schedule;
    List<Resource_Availability_Schedule__c> schList = [
        SELECT Id, Name, Service_Resource1__c 
        FROM Resource_Availability_Schedule__c 
        WHERE Service_Resource1__c = :serviceResourceId 
        LIMIT 1
    ];

    if (!schList.isEmpty()) {
        schedule = schList[0];
        if (String.isBlank(schedule.Name) || schedule.Name != srName) {
            schedule.Name = srName;
            try {
                update schedule;
            } catch (Exception ex) {
                System.debug('Failed to update schedule name: ' + ex.getMessage());
            }
        }
    } else {
        schedule = new Resource_Availability_Schedule__c();
        schedule.Service_Resource1__c = serviceResourceId;
        schedule.Name = srName;
        insert schedule;
    }
    if (dayRecords == null || dayRecords.isEmpty()) {
        return schedule.Id;
    }
    Map<String, Resource_Availability__c> mapByDay = new Map<String, Resource_Availability__c>();
    Integer skipped = 0;

    for (Map<String, Object> recMap : dayRecords) {
        if (recMap == null) {
            skipped++;
            continue;
        }

        Object dayObj = recMap.get('Day_Of_Week__c');
        if (dayObj == null) {
            if (recMap.containsKey('day')) dayObj = recMap.get('day');
            else if (recMap.containsKey('label')) dayObj = recMap.get('label');
            else if (recMap.containsKey('Day')) dayObj = recMap.get('Day');
        }
        String dayStr = (dayObj == null) ? null : String.valueOf(dayObj).trim();
        if (String.isBlank(dayStr)) {
            skipped++;
            continue;
        }
        Resource_Availability__c r = new Resource_Availability__c();
        if (recMap.containsKey('Id') && recMap.get('Id') != null) {
            try { r.Id = (Id)recMap.get('Id'); } catch (Exception e) { /* ignore */ }
        }
        r.Day_Of_Week__c = dayStr;
        r.Name = srName + ' - ' + dayStr; 
        try {
            String s;
            s = recMap.containsKey('Start_Time__c') ? String.valueOf(recMap.get('Start_Time__c')) :
                recMap.containsKey('start') ? String.valueOf(recMap.get('start')) : null;
            r.Start_Time__c = parseTimeString(s);

            s = recMap.containsKey('End_Time__c') ? String.valueOf(recMap.get('End_Time__c')) :
                recMap.containsKey('end') ? String.valueOf(recMap.get('end')) : null;
            r.End_Time__c = parseTimeString(s);

            s = recMap.containsKey('Break_Start__c') ? String.valueOf(recMap.get('Break_Start__c')) :
                recMap.containsKey('breakStart') ? String.valueOf(recMap.get('breakStart')) : null;
            r.Break_Start__c = parseTimeString(s);

            s = recMap.containsKey('Break_End__c') ? String.valueOf(recMap.get('Break_End__c')) :
                recMap.containsKey('breakEnd') ? String.valueOf(recMap.get('breakEnd')) : null;
            r.Break_End__c = parseTimeString(s);
        } catch (Exception timeEx) {
            System.debug('Time parse error for ' + dayStr + ': ' + timeEx.getMessage());
            skipped++;
            continue;
        }
        Boolean isActive = false;
        if (recMap.containsKey('Is_Active__c') && recMap.get('Is_Active__c') != null) {
            try { isActive = Boolean.valueOf(String.valueOf(recMap.get('Is_Active__c'))); } catch (Exception e) {}
        } else if (recMap.containsKey('isActive') && recMap.get('isActive') != null) {
            try { isActive = Boolean.valueOf(String.valueOf(recMap.get('isActive'))); } catch (Exception e) {}
        }
        r.Is_Active__c = isActive;
        r.Service_Resource__c = serviceResourceId;
        r.Availability_Schedule__c = schedule.Id;
        r.Resource_Day_Key__c = schedule.Id + ':' + dayStr;
        mapByDay.put(dayStr, r);
    }
    List<Resource_Availability__c> toUpsert = new List<Resource_Availability__c>(mapByDay.values());
    if (!toUpsert.isEmpty()) {
        try {
            Database.UpsertResult[] results = Database.upsert(toUpsert, Resource_Availability__c.Resource_Day_Key__c, false);
            Integer successCount = 0;
            for (Database.UpsertResult res : results) {
                if (res.isSuccess()) {
                    successCount++;
                } else {
                    for (Database.Error err : res.getErrors()) {
                        System.debug('Upsert error: ' + err.getMessage());
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Exception during upsert: ' + e.getMessage());
            throw new AuraHandledException('Error upserting availability: ' + e.getMessage());
        }
    }
    return schedule.Id;
}

// Helper method to convert time string to Time object
private static Time parseTimeString(String timeStr) {
    if (String.isBlank(timeStr)) {
        return null;
    }
    try {
        List<String> parts = timeStr.split(':');
        if (parts.size() >= 2) {
            Integer hours = Integer.valueOf(parts[0]);
            Integer minutes = Integer.valueOf(parts[1]);
            return Time.newInstance(hours, minutes, 0, 0);
        }
        return null;
    } catch (Exception e) {
        System.debug('Error parsing time: ' + timeStr);
        return null;
    }
}
}