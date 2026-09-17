public class LadminAIAppointmentLifecyclePolicy {
    private static final Set<String> TERMINAL_STATUSES = new Set<String>{ 'Completed', 'Cancelled', 'Cancel' };
    private static final Map<String, Set<String>> TRANSITIONS = new Map<String, Set<String>>{
        'Booked' => new Set<String>{ 'Confirmed', 'Checked In', 'Arrived', 'In Progress', 'Completed', 'No Show' },
        'Confirmed' => new Set<String>{ 'Checked In', 'Arrived', 'In Progress', 'Completed', 'No Show' },
        'Rescheduled' => new Set<String>{ 'Confirmed', 'Checked In', 'Arrived', 'In Progress', 'Completed', 'No Show' },
        'Checked In' => new Set<String>{ 'Arrived', 'In Progress', 'Completed', 'No Show' },
        'Arrived' => new Set<String>{ 'In Progress', 'Completed', 'No Show' },
        'In Progress' => new Set<String>{ 'Completed' },
        'Open' => new Set<String>{ 'Booked', 'Confirmed', 'Checked In', 'Arrived', 'In Progress', 'Completed', 'No Show' }
    };

    public static void assertCanReschedule(String currentStatus, Datetime scheduledStart) {
        if (TERMINAL_STATUSES.contains(currentStatus)) {
            throw safe('A completed or cancelled appointment cannot be rescheduled.');
        }
        assertBeforeCutoff(scheduledStart, LadminAIAppointmentSettingsService.rescheduleCutoffMinutes(), 'rescheduled');
    }

    public static void assertCanCancel(String currentStatus, Datetime scheduledStart) {
        if (TERMINAL_STATUSES.contains(currentStatus)) {
            throw safe('A completed or cancelled appointment cannot be cancelled.');
        }
        assertBeforeCutoff(scheduledStart, LadminAIAppointmentSettingsService.cancellationCutoffMinutes(), 'cancelled');
    }

    public static void assertTransition(String currentStatus, String targetStatus) {
        if (currentStatus == targetStatus) return;
        Set<String> allowed = TRANSITIONS.get(currentStatus);
        if (allowed == null || !allowed.contains(targetStatus)) {
            throw safe('The appointment cannot move from ' + currentStatus + ' to ' + targetStatus + '.');
        }
    }

    private static void assertBeforeCutoff(Datetime scheduledStart, Integer cutoffMinutes, String action) {
        if (scheduledStart == null) throw safe('The appointment has no scheduled start time.');
        if (scheduledStart <= System.now()) throw safe('An appointment that has already started cannot be ' + action + '.');
        if (cutoffMinutes > 0 && scheduledStart < System.now().addMinutes(cutoffMinutes)) {
            throw safe('This appointment is inside the configured ' + action + ' cutoff window.');
        }
    }

    private static AuraHandledException safe(String message) {
        AuraHandledException error = new AuraHandledException(message);
        error.setMessage(message);
        return error;
    }
}
