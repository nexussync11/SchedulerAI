public with sharing class LadminAIAppointmentBusinessTimeService {
    public class InvalidBusinessTimeException extends Exception {}
    private static Map<Id, TimeZone> locationZones = new Map<Id, TimeZone>();
    private static TimeZone defaultZone;

    public static Datetime toUtc(Date localDate, Time localTime) {
        return toUtc(localDate, localTime, null);
    }

    public static Datetime toUtc(Date localDate, Time localTime, Id locationId) {
        if (localDate == null || localTime == null) {
            throw new IllegalArgumentException('A local date and time are required.');
        }
        TimeZone zone = configuredZone(locationId);
        Datetime wallClockAsUtc = Datetime.newInstanceGmt(localDate, localTime);
        Datetime candidateUtc = wallClockAsUtc.addSeconds(-zone.getOffset(wallClockAsUtc) / 1000);
        candidateUtc = wallClockAsUtc.addSeconds(-zone.getOffset(candidateUtc) / 1000);
        LocalWallClock roundTrip = toLocalWallClock(candidateUtc, locationId);
        if (roundTrip.localDate != localDate || roundTrip.localTime != localTime) {
            throw new InvalidBusinessTimeException('The selected time does not exist in the configured business timezone.');
        }
        return candidateUtc;
    }

    public static LocalWallClock toLocalWallClock(Datetime utcValue) {
        return toLocalWallClock(utcValue, null);
    }

    public static LocalWallClock toLocalWallClock(Datetime utcValue, Id locationId) {
        if (utcValue == null) throw new IllegalArgumentException('A UTC DateTime is required.');
        TimeZone zone = configuredZone(locationId);
        Datetime wallClock = utcValue.addSeconds(zone.getOffset(utcValue) / 1000);
        return new LocalWallClock(wallClock.dateGmt(), wallClock.timeGmt());
    }

    private static TimeZone configuredZone(Id locationId) {
        if (locationId != null && locationId.getSObjectType() == Schema.Location.SObjectType) {
            if (locationZones.containsKey(locationId)) return locationZones.get(locationId);
            List<Schema.Location> locations = [
                SELECT Scheduler_Time_Zone__c FROM Location WHERE Id = :locationId LIMIT 1
            ];
            String timezoneSidKey = locations.isEmpty() ? null : locations[0].Scheduler_Time_Zone__c;
            TimeZone zone = String.isBlank(timezoneSidKey) ? configuredDefaultZone() : TimeZone.getTimeZone(timezoneSidKey);
            locationZones.put(locationId, zone);
            return zone;
        }
        return configuredDefaultZone();
    }

    private static TimeZone configuredDefaultZone() {
        if (defaultZone == null) {
            defaultZone = TimeZone.getTimeZone(LadminAIAppointmentSettingsService.businessTimeZone());
        }
        return defaultZone;
    }

    public class LocalWallClock {
        public Date localDate { get; private set; }
        public Time localTime { get; private set; }
        private LocalWallClock(Date localDate, Time localTime) {
            this.localDate = localDate;
            this.localTime = localTime;
        }
    }
}
