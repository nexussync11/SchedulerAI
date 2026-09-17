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

    public static void assertCanReschedule(String currentStatus) {
        if (TERMINAL_STATUSES.contains(currentStatus)) {
            throw safe('A completed or cancelled appointment cannot be rescheduled.');
        }
    }

    public static void assertCanCancel(String currentStatus) {
        if (TERMINAL_STATUSES.contains(currentStatus)) {
            throw safe('A completed or cancelled appointment cannot be cancelled.');
        }
    }

    public static void assertTransition(String currentStatus, String targetStatus) {
        if (currentStatus == targetStatus) return;
        Set<String> allowed = TRANSITIONS.get(currentStatus);
        if (allowed == null || !allowed.contains(targetStatus)) {
            throw safe('The appointment cannot move from ' + currentStatus + ' to ' + targetStatus + '.');
        }
    }

    private static AuraHandledException safe(String message) {
        AuraHandledException error = new AuraHandledException(message);
        error.setMessage(message);
        return error;
    }
}
