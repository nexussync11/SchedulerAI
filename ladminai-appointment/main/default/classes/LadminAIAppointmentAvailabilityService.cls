public with sharing class LadminAIAppointmentAvailabilityService {
    @AuraEnabled(cacheable=true)
    public static List<Service_Resource__c> getAllServiceResources() {
        return [
            SELECT Id, Name, Active__c
            FROM Service_Resource__c
            WHERE Active__c = true
            ORDER BY Name
            LIMIT 200
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Resource_Availability__c> getAvailability(
        Id serviceResourceId
    ) {
        if (serviceResourceId == null) {
            return new List<Resource_Availability__c>();
        }
        return [
            SELECT Id, Day_Of_Week__c, Start_Time__c, End_Time__c,
                   Break_Start__c, Break_End__c, Is_Active__c
            FROM Resource_Availability__c
            WHERE Service_Resource__c = :serviceResourceId
              AND Override_Date__c = null
            ORDER BY Day_Of_Week__c
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Resource_Availability__c> getAvailabilityAtLocation(
        Id serviceResourceId,
        Id locationId
    ) {
        if (serviceResourceId == null || locationId == null) {
            return new List<Resource_Availability__c>();
        }
        LadminAIAppointmentLocationService.assertActiveAssociation(
            locationId,
            serviceResourceId
        );
        return [
            SELECT Id, Day_Of_Week__c, Start_Time__c, End_Time__c,
                   Break_Start__c, Break_End__c, Is_Active__c, Location__c
            FROM Resource_Availability__c
            WHERE Service_Resource__c = :serviceResourceId
              AND Location__c = :locationId
              AND Override_Date__c = null
            ORDER BY Day_Of_Week__c
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Resource_Availability__c> getSpecialDatesAtLocation(
        Id serviceResourceId,
        Id locationId
    ) {
        if (serviceResourceId == null || locationId == null) {
            return new List<Resource_Availability__c>();
        }
        LadminAIAppointmentLocationService.assertActiveAssociation(locationId, serviceResourceId);
        return [
            SELECT Id, Name, Override_Date__c, Override_Type__c,
                   Start_Time__c, End_Time__c, Break_Start__c, Break_End__c,
                   Service_Resource__c, Location__c
            FROM Resource_Availability__c
            WHERE Service_Resource__c = :serviceResourceId
              AND Location__c = :locationId
              AND Override_Date__c != null
              AND Is_Active__c = true
            WITH USER_MODE
            ORDER BY Override_Date__c
        ];
    }

    @AuraEnabled
    public static Id saveSpecialDateAtLocation(
        Id serviceResourceId,
        Id locationId,
        Id overrideId,
        Date overrideDate,
        String overrideType,
        String startTime,
        String endTime,
        String breakStart,
        String breakEnd
    ) {
        if (serviceResourceId == null || locationId == null || overrideDate == null) {
            throw new AuraHandledException('Doctor, location and date are required.');
        }
        if (overrideType != 'Unavailable' && overrideType != 'Custom Hours') {
            throw new AuraHandledException('Select a supported override type.');
        }
        LadminAIAppointmentLocationService.assertActiveAssociation(locationId, serviceResourceId);
        Time parsedStart = parseTime(startTime);
        Time parsedEnd = parseTime(endTime);
        Time parsedBreakStart = parseTime(breakStart);
        Time parsedBreakEnd = parseTime(breakEnd);
        if (overrideType == 'Custom Hours') {
            validateWindow(parsedStart, parsedEnd, parsedBreakStart, parsedBreakEnd);
        } else {
            parsedStart = null;
            parsedEnd = null;
            parsedBreakStart = null;
            parsedBreakEnd = null;
        }
        String overrideKey = serviceResourceId + ':' + locationId + ':'
            + String.valueOf(overrideDate);
        List<Resource_Availability__c> existing = overrideId == null
            ? [
                SELECT Id FROM Resource_Availability__c
                WHERE Override_Key__c = :overrideKey WITH USER_MODE LIMIT 1
            ]
            : [
                SELECT Id FROM Resource_Availability__c
                WHERE Id = :overrideId WITH USER_MODE LIMIT 1
            ];
        Resource_Availability__c row = existing.isEmpty()
            ? new Resource_Availability__c()
            : existing[0];
        row.Name = 'Override - ' + String.valueOf(overrideDate);
        row.Service_Resource__c = serviceResourceId;
        row.Location__c = locationId;
        row.Override_Date__c = overrideDate;
        row.Override_Type__c = overrideType;
        row.Override_Key__c = overrideKey;
        row.Start_Time__c = parsedStart;
        row.End_Time__c = parsedEnd;
        row.Break_Start__c = parsedBreakStart;
        row.Break_End__c = parsedBreakEnd;
        row.Is_Active__c = true;
        if (row.Id == null) Database.insert(row, AccessLevel.USER_MODE);
        else Database.update(row, AccessLevel.USER_MODE);
        return row.Id;
    }

    @AuraEnabled
    public static void deleteSpecialDate(Id overrideId) {
        if (overrideId == null) return;
        List<Resource_Availability__c> rows = [
            SELECT Id, Is_Active__c FROM Resource_Availability__c
            WHERE Id = :overrideId AND Override_Date__c != null
            WITH USER_MODE LIMIT 1
        ];
        if (!rows.isEmpty()) {
            rows[0].Is_Active__c = false;
            Database.update(rows[0], AccessLevel.USER_MODE);
        }
    }

    public static List<Resource_Availability__c> getEffectiveAvailability(
        Id serviceResourceId,
        Id locationId,
        Date targetDate
    ) {
        List<Resource_Availability__c> overrides = [
            SELECT Id, Start_Time__c, End_Time__c, Break_Start__c,
                   Break_End__c, Override_Type__c
            FROM Resource_Availability__c
            WHERE Service_Resource__c = :serviceResourceId
              AND Location__c = :locationId
              AND Override_Date__c = :targetDate
              AND Is_Active__c = true
            WITH USER_MODE
            LIMIT 1
        ];
        if (!overrides.isEmpty()) {
            return overrides[0].Override_Type__c == 'Unavailable'
                ? new List<Resource_Availability__c>()
                : overrides;
        }
        String weekday = Datetime.newInstance(
            targetDate, Time.newInstance(12, 0, 0, 0)
        ).format('EEEE');
        return locationId == null
            ? [
                SELECT Id, Start_Time__c, End_Time__c, Break_Start__c, Break_End__c
                FROM Resource_Availability__c
                WHERE Service_Resource__c = :serviceResourceId
                  AND Location__c = null
                  AND Day_Of_Week__c = :weekday
                  AND Override_Date__c = null
                  AND Is_Active__c = true
                WITH USER_MODE
            ]
            : [
                SELECT Id, Start_Time__c, End_Time__c, Break_Start__c, Break_End__c
                FROM Resource_Availability__c
                WHERE Service_Resource__c = :serviceResourceId
                  AND Location__c = :locationId
                  AND Day_Of_Week__c = :weekday
                  AND Override_Date__c = null
                  AND Is_Active__c = true
                WITH USER_MODE
            ];
    }

    @AuraEnabled(cacheable=true)
    public static List<List<String>> getAvailableSlots(
        Id serviceResourceId,
        Id locationId,
        Date targetDate
    ) {
        if (serviceResourceId == null || locationId == null || targetDate == null) {
            return new List<List<String>>();
        }
        LadminAIAppointmentLocationService.assertActiveAssociation(locationId, serviceResourceId);
        List<Resource_Availability__c> windows = getEffectiveAvailability(
            serviceResourceId, locationId, targetDate
        );
        if (windows.isEmpty()) return new List<List<String>>();

        Integer slotMinutes = 30;
        LadminAI_Appointment_Settings__mdt settings =
            LadminAI_Appointment_Settings__mdt.getInstance('Default');
        if (settings?.LadminAI_Default_Slot_Minutes__c != null) {
            slotMinutes = settings.LadminAI_Default_Slot_Minutes__c.intValue();
        }
        Resource_Availability__c window = windows[0];
        Datetime rangeStart = LadminAIAppointmentBusinessTimeService.toUtc(targetDate, window.Start_Time__c);
        Datetime rangeEnd = LadminAIAppointmentBusinessTimeService.toUtc(targetDate, window.End_Time__c);
        List<Assigned_Resource__c> occupied = [
            SELECT Service_Appointment__r.Scheduled_Start__c,
                   Service_Appointment__r.Scheduled_End__c,
                   Service_Appointment__r.Status__c
            FROM Assigned_Resource__c
            WHERE Service_Resource__c = :serviceResourceId
              AND Service_Appointment__r.Scheduled_Start__c < :rangeEnd
              AND Service_Appointment__r.Scheduled_End__c > :rangeStart
            WITH USER_MODE
        ];
        Set<String> nonBlocking = new Set<String>{ 'Cancel', 'Cancelled', 'No Show', 'DNA' };
        List<List<String>> output = new List<List<String>>();
        for (Datetime slotStart = rangeStart; slotStart.addMinutes(slotMinutes) <= rangeEnd;
             slotStart = slotStart.addMinutes(slotMinutes)) {
            Datetime slotEnd = slotStart.addMinutes(slotMinutes);
            LadminAIAppointmentBusinessTimeService.LocalWallClock localStart =
                LadminAIAppointmentBusinessTimeService.toLocalWallClock(slotStart);
            LadminAIAppointmentBusinessTimeService.LocalWallClock localEnd =
                LadminAIAppointmentBusinessTimeService.toLocalWallClock(slotEnd);
            if (window.Break_Start__c != null && window.Break_End__c != null &&
                localStart.localTime < window.Break_End__c && localEnd.localTime > window.Break_Start__c) {
                continue;
            }
            Boolean conflict = false;
            for (Assigned_Resource__c row : occupied) {
                if (!nonBlocking.contains(row.Service_Appointment__r.Status__c) &&
                    row.Service_Appointment__r.Scheduled_Start__c < slotEnd &&
                    row.Service_Appointment__r.Scheduled_End__c > slotStart) {
                    conflict = true;
                    break;
                }
            }
            if (!conflict) output.add(new List<String>{
                timeLabel(localStart.localTime), timeLabel(localEnd.localTime)
            });
        }
        return output;
    }

    private static String timeLabel(Time value) {
        String hour = String.valueOf(value.hour()).leftPad(2, '0');
        String minute = String.valueOf(value.minute()).leftPad(2, '0');
        return hour + ':' + minute;
    }

    @AuraEnabled
    public static Id saveAvailabilityV2(
        Id serviceResourceId,
        List<Map<String, Object>> dayRecords
    ) {
        return saveAvailabilityInternal(serviceResourceId, null, dayRecords);
    }

    @AuraEnabled
    public static Id saveAvailabilityAtLocation(
        Id serviceResourceId,
        Id locationId,
        List<Map<String, Object>> dayRecords
    ) {
        LadminAIAppointmentLocationService.assertActiveAssociation(
            locationId,
            serviceResourceId
        );
        return saveAvailabilityInternal(
            serviceResourceId,
            locationId,
            dayRecords
        );
    }

    private static Id saveAvailabilityInternal(
        Id serviceResourceId,
        Id locationId,
        List<Map<String, Object>> dayRecords
    ) {
        if (serviceResourceId == null) {
            throw new AuraHandledException('Select a doctor before saving.');
        }

        Service_Resource__c resource = [
            SELECT Id, Name
            FROM Service_Resource__c
            WHERE Id = :serviceResourceId
            LIMIT 1
        ];

        List<Resource_Availability_Schedule__c> schedules = [
            SELECT Id, Name, Service_Resource1__c
            FROM Resource_Availability_Schedule__c
            WHERE Service_Resource1__c = :serviceResourceId
            LIMIT 1
        ];
        Resource_Availability_Schedule__c schedule;
        if (schedules.isEmpty()) {
            schedule = new Resource_Availability_Schedule__c(
                Name = resource.Name,
                Service_Resource1__c = resource.Id
            );
            insert schedule;
        } else {
            schedule = schedules[0];
        }

        if (dayRecords == null || dayRecords.isEmpty()) {
            return schedule.Id;
        }

        Map<String, Resource_Availability__c> existingByDay =
            new Map<String, Resource_Availability__c>();
        for (Resource_Availability__c row : [
            SELECT Id, Day_Of_Week__c
            FROM Resource_Availability__c
            WHERE Service_Resource__c = :serviceResourceId
              AND Location__c = :locationId
              AND Override_Date__c = null
        ]) {
            existingByDay.put(row.Day_Of_Week__c, row);
        }

        List<Resource_Availability__c> rowsToUpdate =
            new List<Resource_Availability__c>();
        List<Resource_Availability__c> rowsToInsert =
            new List<Resource_Availability__c>();
        for (Map<String, Object> input : dayRecords) {
            String day = stringValue(input, 'Day_Of_Week__c');
            if (String.isBlank(day)) {
                continue;
            }
            Boolean existingRow = existingByDay.containsKey(day);
            Resource_Availability__c row = existingRow
                ? existingByDay.get(day)
                : new Resource_Availability__c();
            row.Name = resource.Name + ' - ' + day;
            row.Day_Of_Week__c = day;
            row.Service_Resource__c = resource.Id;
            row.Location__c = locationId;
            row.Availability_Schedule__c = schedule.Id;
            row.Resource_Day_Key__c = locationId == null
                ? schedule.Id + ':' + day
                : schedule.Id + ':' + locationId + ':' + day;
            row.Start_Time__c = parseTime(stringValue(input, 'Start_Time__c'));
            row.End_Time__c = parseTime(stringValue(input, 'End_Time__c'));
            row.Break_Start__c =
                parseTime(stringValue(input, 'Break_Start__c'));
            row.Break_End__c = parseTime(stringValue(input, 'Break_End__c'));
            row.Is_Active__c =
                Boolean.valueOf(stringValue(input, 'Is_Active__c'));
            if (existingRow) {
                rowsToUpdate.add(row);
            } else {
                rowsToInsert.add(row);
            }
        }
        if (!rowsToUpdate.isEmpty()) {
            update rowsToUpdate;
        }
        if (!rowsToInsert.isEmpty()) {
            insert rowsToInsert;
        }
        return schedule.Id;
    }

    private static String stringValue(Map<String, Object> input, String key) {
        Object value = input == null ? null : input.get(key);
        return value == null ? null : String.valueOf(value);
    }

    private static Time parseTime(String value) {
        if (String.isBlank(value)) {
            return null;
        }
        List<String> parts = value.split(':');
        if (parts.size() < 2) {
            throw new AuraHandledException('Use HH:mm time values.');
        }
        return Time.newInstance(
            Integer.valueOf(parts[0]),
            Integer.valueOf(parts[1]),
            0,
            0
        );
    }

    private static void validateWindow(
        Time startTime,
        Time endTime,
        Time breakStart,
        Time breakEnd
    ) {
        if (startTime == null || endTime == null || startTime >= endTime) {
            throw new AuraHandledException('Custom hours require a valid start and end time.');
        }
        if (
            (breakStart != null || breakEnd != null)
            && (
                breakStart == null || breakEnd == null
                || breakStart >= breakEnd || breakStart < startTime
                || breakEnd > endTime
            )
        ) {
            throw new AuraHandledException('The break must be complete and inside custom hours.');
        }
    }
}
