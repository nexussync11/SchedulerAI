public with sharing class LadminAIAppointmentBusinessTimeService {
    public class InvalidBusinessTimeException extends Exception {}

    public static Datetime toUtc(Date localDate, Time localTime) {
        if (localDate == null || localTime == null) {
            throw new IllegalArgumentException('A local date and time are required.');
        }
        TimeZone zone = configuredZone();
        Datetime wallClockAsUtc = Datetime.newInstanceGmt(localDate, localTime);
        Datetime candidateUtc = wallClockAsUtc.addSeconds(-zone.getOffset(wallClockAsUtc) / 1000);
        candidateUtc = wallClockAsUtc.addSeconds(-zone.getOffset(candidateUtc) / 1000);
        LocalWallClock roundTrip = toLocalWallClock(candidateUtc);
        if (roundTrip.localDate != localDate || roundTrip.localTime != localTime) {
            throw new InvalidBusinessTimeException('The selected time does not exist in the configured business timezone.');
        }
        return candidateUtc;
    }

    public static LocalWallClock toLocalWallClock(Datetime utcValue) {
        if (utcValue == null) throw new IllegalArgumentException('A UTC DateTime is required.');
        TimeZone zone = configuredZone();
        Datetime wallClock = utcValue.addSeconds(zone.getOffset(utcValue) / 1000);
        return new LocalWallClock(wallClock.dateGmt(), wallClock.timeGmt());
    }

    private static TimeZone configuredZone() {
        return TimeZone.getTimeZone(LadminAIAppointmentSettingsService.businessTimeZone());
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
