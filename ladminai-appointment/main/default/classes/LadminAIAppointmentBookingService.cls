/**
 * Secure transactional booking service for the existing scheduler data model.
 *
 * Gate 2 performs a normal overlap query. It does not provide the row-locking
 * concurrency guarantee planned for Gate 3.
 */
public with sharing class LadminAIAppointmentBookingService {
    private static final Integer MAX_BATCH_REQUESTS = 4;
    private static final Integer MAX_DURATION_MINUTES = 1440;
    private static final Set<String> NON_BLOCKING_STATUSES =
        new Set<String>{ 'Cancel', 'No Show', 'DNA', 'Cancelled' };

    @TestVisible
    private static Boolean failAfterAppointmentInsertForTest = false;

    private class BookingOperationException extends Exception {
    }

    public static LadminAIAppointmentBookingResult bookAppointment(
        LadminAIAppointmentBookingRequest request
    ) {
        LadminAIAppointmentBookingResult validationResult = validateRequest(request);
        if (validationResult != null) {
            return validationResult;
        }

        LadminAIAppointmentBookingResult securityResult = validateAccess();
        if (securityResult != null) {
            return securityResult;
        }
        request.idempotencyKey = request.idempotencyKey.trim();

        Savepoint bookingSavepoint = Database.setSavepoint();
        try {
            List<ServiceAppointment__c> existingByKey = [
                SELECT Id, Name, Parent_Record1__c, Scheduled_Start__c,
                    Scheduled_End__c, LadminAI_Booking_Reference__c
                FROM ServiceAppointment__c
                WHERE LadminAI_Idempotency_Key__c = :request.idempotencyKey
                WITH USER_MODE
                LIMIT 1
            ];
            if (!existingByKey.isEmpty()) {
                return buildIdempotentResult(existingByKey[0], request);
            }

            List<Lead> parents = [
                SELECT Id
                FROM Lead
                WHERE Id = :request.parentRecordId
                WITH USER_MODE
                LIMIT 1
            ];
            if (parents.isEmpty()) {
                Database.rollback(bookingSavepoint);
                return failure(
                    'PARENT_NOT_ACCESSIBLE',
                    'The selected parent record is unavailable.'
                );
            }

            List<Service_Resource__c> resources = [
                SELECT Id, Name, Active__c
                FROM Service_Resource__c
                WHERE Id = :request.serviceResourceId
                WITH USER_MODE
                LIMIT 1
            ];
            if (
                resources.isEmpty() ||
                resources[0].Active__c != true
            ) {
                Database.rollback(bookingSavepoint);
                return failure(
                    'RESOURCE_UNAVAILABLE',
                    'The selected resource is unavailable.'
                );
            }

            List<Assigned_Resource__c> overlapRows = [
                SELECT Service_Appointment__c,
                    Service_Appointment__r.Scheduled_Start__c,
                    Service_Appointment__r.Scheduled_End__c,
                    Service_Appointment__r.Status__c
                FROM Assigned_Resource__c
                WHERE Service_Resource__c = :request.serviceResourceId
                    AND Service_Appointment__r.Scheduled_Start__c < :request.requestedEnd
                    AND Service_Appointment__r.Scheduled_End__c > :request.requestedStart
                WITH USER_MODE
                LIMIT 50
            ];
            List<LadminAIAppointmentConflict> conflicts =
                new List<LadminAIAppointmentConflict>();
            for (Assigned_Resource__c row : overlapRows) {
                if (!NON_BLOCKING_STATUSES.contains(row.Service_Appointment__r.Status__c)) {
                    conflicts.add(new LadminAIAppointmentConflict(
                        row.Service_Appointment__c,
                        row.Service_Appointment__r.Scheduled_Start__c,
                        row.Service_Appointment__r.Scheduled_End__c
                    ));
                }
            }
            if (!conflicts.isEmpty()) {
                Database.rollback(bookingSavepoint);
                LadminAIAppointmentBookingResult conflictResult = failure(
                    'SLOT_CONFLICT',
                    'The selected time is no longer available.'
                );
                conflictResult.conflicts = conflicts;
                return conflictResult;
            }

            Integer durationMinutes = calculateDurationMinutes(request);
            String bookingReference = createBookingReference(request.idempotencyKey);
            Service_Resource__c resource = resources[0];
            LadminAIAppointmentLocationService.assertActiveAssociation(
                request.locationId, request.serviceResourceId
            );

            ServiceAppointment__c appointment = new ServiceAppointment__c(
                Name = bookingReference,
                Parent_Record1__c = request.parentRecordId,
                Scheduled_Start__c = request.requestedStart,
                Scheduled_End__c = request.requestedEnd,
                Duration__c = durationMinutes,
                Subject__c = request.subject.trim(),
                Status__c = 'Open',
                Location__c = request.locationId,
                Booked_By_User__c = UserInfo.getUserId(),
                Service_Resource_Name__c = abbreviate(resource.Name, 40),
                LadminAI_Idempotency_Key__c = request.idempotencyKey.trim(),
                LadminAI_Booking_Reference__c = bookingReference
            );
            if (!String.isBlank(request.bookingSource)) {
                appointment.Appointment_Mode__c = request.bookingSource;
            }
            if (!String.isBlank(request.appointmentType)) {
                appointment.Appointment_Type__c = request.appointmentType;
            }

            Database.SaveResult appointmentSave =
                Database.insert(appointment, AccessLevel.USER_MODE);
            if (!appointmentSave.isSuccess()) {
                throw new BookingOperationException('APPOINTMENT_CREATE_FAILED');
            }
            appointment.Id = appointmentSave.getId();

            if (failAfterAppointmentInsertForTest) {
                throw new BookingOperationException('RELATED_OPERATION_FAILED');
            }

            Event calendarProjection = new Event(
                Subject = request.subject.trim(),
                WhoId = request.parentRecordId,
                OwnerId = UserInfo.getUserId(),
                StartDateTime = request.requestedStart,
                EndDateTime = request.requestedEnd
            );
            Database.SaveResult eventSave =
                Database.insert(calendarProjection, AccessLevel.USER_MODE);
            if (!eventSave.isSuccess()) {
                throw new BookingOperationException('EVENT_CREATE_FAILED');
            }
            appointment.LadminAI_Event__c = eventSave.getId();
            Database.update(appointment, AccessLevel.USER_MODE);

            Assigned_Resource__c assignment = new Assigned_Resource__c(
                Service_Appointment__c = appointment.Id,
                Service_Resource__c = request.serviceResourceId
            );
            Database.SaveResult assignmentSave =
                Database.insert(assignment, AccessLevel.USER_MODE);
            if (!assignmentSave.isSuccess()) {
                throw new BookingOperationException('ASSIGNMENT_CREATE_FAILED');
            }

            LadminAIAppointmentBookingResult result =
                new LadminAIAppointmentBookingResult();
            result.success = true;
            result.appointmentId = appointment.Id;
            result.eventId = eventSave.getId();
            result.assignedResourceId = assignmentSave.getId();
            result.bookingReference = bookingReference;
            result.userMessage = 'Appointment booked successfully.';
            LadminAINotificationService.notifyAsync(appointment.Id, 'booked');
            return result;
        } catch (Exception exceptionValue) {
            Database.rollback(bookingSavepoint);
            String errorCode = exceptionValue instanceof BookingOperationException
                ? exceptionValue.getMessage()
                : 'BOOKING_FAILED';
            return failure(
                errorCode,
                'The appointment could not be booked. No changes were saved.'
            );
        }
    }

    /**
     * Bounded multi-request entry point. Four requests remain below savepoint,
     * query, and DML limits with the Gate 2 implementation.
     */
    public static List<LadminAIAppointmentBookingResult> bookAppointments(
        List<LadminAIAppointmentBookingRequest> requests
    ) {
        List<LadminAIAppointmentBookingResult> results =
            new List<LadminAIAppointmentBookingResult>();
        if (requests == null || requests.isEmpty()) {
            results.add(failure('REQUEST_REQUIRED', 'At least one booking request is required.'));
            return results;
        }
        if (requests.size() > MAX_BATCH_REQUESTS) {
            results.add(failure(
                'BATCH_LIMIT_EXCEEDED',
                'A maximum of four booking requests can be processed together.'
            ));
            return results;
        }
        for (LadminAIAppointmentBookingRequest request : requests) {
            results.add(bookAppointment(request));
        }
        return results;
    }

    private static LadminAIAppointmentBookingResult validateRequest(
        LadminAIAppointmentBookingRequest request
    ) {
        LadminAIAppointmentBookingResult result =
            new LadminAIAppointmentBookingResult();
        result.errorCode = 'VALIDATION_FAILED';
        result.userMessage = 'Review the highlighted booking details.';

        if (request == null) {
            result.fieldErrors.add(new LadminAIAppointmentFieldError(
                'request',
                'A booking request is required.'
            ));
            return result;
        }
        if (
            request.parentRecordId == null ||
            request.parentRecordId.getSObjectType() != Lead.SObjectType
        ) {
            addFieldError(result, 'parentRecordId', 'A valid Lead context is required.');
        }
        if (request.serviceResourceId == null) {
            addFieldError(result, 'serviceResourceId', 'A service resource is required.');
        }
        if (request.appointmentDate == null) {
            addFieldError(result, 'appointmentDate', 'An appointment date is required.');
        }
        if (request.requestedStart == null) {
            addFieldError(result, 'requestedStart', 'A start time is required.');
        }
        if (request.requestedEnd == null) {
            addFieldError(result, 'requestedEnd', 'An end time is required.');
        }
        if (
            request.requestedStart != null &&
            request.requestedEnd != null &&
            request.requestedStart >= request.requestedEnd
        ) {
            addFieldError(result, 'requestedEnd', 'End time must be after start time.');
        }
        if (
            request.appointmentDate != null &&
            request.requestedStart != null &&
            request.appointmentDate != request.requestedStart.date()
        ) {
            addFieldError(
                result,
                'appointmentDate',
                'Appointment date must match the requested start.'
            );
        }
        if (
            request.requestedStart != null &&
            request.requestedEnd != null &&
            request.requestedStart < request.requestedEnd
        ) {
            Long durationMilliseconds =
                request.requestedEnd.getTime() - request.requestedStart.getTime();
            Integer durationSeconds = Integer.valueOf(
                String.valueOf(durationMilliseconds / 1000)
            );
            if (
                Math.mod(durationSeconds, 60) != 0 ||
                durationMilliseconds < 60000 ||
                durationMilliseconds > MAX_DURATION_MINUTES * 60000L
            ) {
                addFieldError(
                    result,
                    'requestedEnd',
                    'Duration must be between 1 and 1440 whole minutes.'
                );
            }
        }
        if (String.isBlank(request.subject) || request.subject.trim().length() > 255) {
            addFieldError(result, 'subject', 'Subject is required and must not exceed 255 characters.');
        }
        if (!String.isBlank(request.bookingSource) && !isActivePicklistValue(
            ServiceAppointment__c.Appointment_Mode__c,
            request.bookingSource
        )) {
            addFieldError(result, 'bookingSource', 'Booking source is not supported.');
        }
        if (
            !String.isBlank(request.appointmentType) &&
            !isActivePicklistValue(
                ServiceAppointment__c.Appointment_Type__c,
                request.appointmentType
            )
        ) {
            addFieldError(result, 'appointmentType', 'Appointment type is not supported.');
        }
        if (request.locationId == null) addFieldError(result, 'locationId', 'Location is required.');
        if (
            String.isBlank(request.bookingStatus) ||
            (
                !request.bookingStatus.equalsIgnoreCase('Booked') &&
                !request.bookingStatus.equalsIgnoreCase('Open')
            )
        ) {
            addFieldError(
                result,
                'bookingStatus',
                'Gate 2 supports Booked status for new appointments.'
            );
        }
        if (
            String.isBlank(request.idempotencyKey) ||
            request.idempotencyKey.trim().length() < 8 ||
            request.idempotencyKey.trim().length() > 80
        ) {
            addFieldError(
                result,
                'idempotencyKey',
                'An idempotency key between 8 and 80 characters is required.'
            );
        }
        return result.fieldErrors.isEmpty() ? null : result;
    }

    private static LadminAIAppointmentBookingResult validateAccess() {
        if (!FeatureManagement.checkPermission('LadminAI_Book_Appointment')) {
            return failure(
                'AUTHORIZATION_REQUIRED',
                'You are not authorized to book appointments.'
            );
        }
        if (
            !Lead.SObjectType.getDescribe().isAccessible() ||
            !User.SObjectType.getDescribe().isAccessible() ||
            !Service_Resource__c.SObjectType.getDescribe().isAccessible() ||
            !ServiceAppointment__c.SObjectType.getDescribe().isAccessible() ||
            !ServiceAppointment__c.SObjectType.getDescribe().isCreateable() ||
            !Assigned_Resource__c.SObjectType.getDescribe().isAccessible() ||
            !Assigned_Resource__c.SObjectType.getDescribe().isCreateable() ||
            !Event.SObjectType.getDescribe().isAccessible() ||
            !Event.SObjectType.getDescribe().isCreateable()
        ) {
            return failure(
                'OBJECT_ACCESS_REQUIRED',
                'Required booking access is not available.'
            );
        }

        List<Schema.SObjectField> readableFields = new List<Schema.SObjectField>{
            Service_Resource__c.Active__c,
            Assigned_Resource__c.Service_Appointment__c,
            Assigned_Resource__c.Service_Resource__c,
            ServiceAppointment__c.Scheduled_Start__c,
            ServiceAppointment__c.Scheduled_End__c,
            ServiceAppointment__c.Status__c,
            ServiceAppointment__c.LadminAI_Idempotency_Key__c,
            ServiceAppointment__c.LadminAI_Booking_Reference__c
        };
        List<Schema.SObjectField> createableFields = new List<Schema.SObjectField>{
            ServiceAppointment__c.Parent_Record1__c,
            ServiceAppointment__c.Scheduled_Start__c,
            ServiceAppointment__c.Scheduled_End__c,
            ServiceAppointment__c.Duration__c,
            ServiceAppointment__c.Subject__c,
            ServiceAppointment__c.Location__c,
            ServiceAppointment__c.Booked_By_User__c,
            ServiceAppointment__c.LadminAI_Event__c,
            ServiceAppointment__c.Appointment_Mode__c,
            ServiceAppointment__c.Appointment_Type__c,
            ServiceAppointment__c.Status__c,
            ServiceAppointment__c.Service_Resource_Name__c,
            ServiceAppointment__c.LadminAI_Idempotency_Key__c,
            ServiceAppointment__c.LadminAI_Booking_Reference__c,
            Assigned_Resource__c.Service_Appointment__c,
            Assigned_Resource__c.Service_Resource__c,
            Event.Subject,
            Event.WhoId,
            Event.OwnerId,
            Event.StartDateTime,
            Event.EndDateTime
        };
        if (!allReadable(readableFields) || !allCreateable(createableFields)) {
            return failure(
                'FIELD_ACCESS_REQUIRED',
                'Required booking field access is not available.'
            );
        }
        return null;
    }

    private static LadminAIAppointmentBookingResult buildIdempotentResult(
        ServiceAppointment__c existing,
        LadminAIAppointmentBookingRequest request
    ) {
        List<Assigned_Resource__c> assignments = [
            SELECT Id, Service_Resource__c
            FROM Assigned_Resource__c
            WHERE Service_Appointment__c = :existing.Id
            WITH USER_MODE
            LIMIT 1
        ];
        Boolean sameRequest =
            existing.Parent_Record1__c == request.parentRecordId &&
            existing.Scheduled_Start__c.getTime() / 1000 ==
                request.requestedStart.getTime() / 1000 &&
            existing.Scheduled_End__c.getTime() / 1000 ==
                request.requestedEnd.getTime() / 1000 &&
            !assignments.isEmpty() &&
            assignments[0].Service_Resource__c == request.serviceResourceId;
        if (!sameRequest) {
            return failure(
                'IDEMPOTENCY_KEY_REUSED',
                'The idempotency key has already been used for another booking.'
            );
        }
        LadminAIAppointmentBookingResult result =
            new LadminAIAppointmentBookingResult();
        result.success = true;
        result.idempotentReplay = true;
        result.appointmentId = existing.Id;
        result.assignedResourceId = assignments[0].Id;
        result.bookingReference = existing.LadminAI_Booking_Reference__c;
        result.userMessage = 'This appointment was already booked.';
        return result;
    }

    private static Integer calculateDurationMinutes(
        LadminAIAppointmentBookingRequest request
    ) {
        Long milliseconds = request.requestedEnd.getTime() - request.requestedStart.getTime();
        return Integer.valueOf(String.valueOf(milliseconds / 60000));
    }

    private static String createBookingReference(String idempotencyKey) {
        String seed = idempotencyKey + ':' + String.valueOf(Crypto.getRandomLong());
        String digest = EncodingUtil.convertToHex(
            Crypto.generateDigest('SHA-256', Blob.valueOf(seed))
        );
        return 'LA-' + digest.substring(0, 20).toUpperCase();
    }

    private static Boolean isActivePicklistValue(
        Schema.SObjectField fieldToken,
        String requestedValue
    ) {
        for (Schema.PicklistEntry entry : fieldToken.getDescribe().getPicklistValues()) {
            if (entry.isActive() && entry.getValue() == requestedValue) {
                return true;
            }
        }
        return false;
    }

    private static Boolean allReadable(List<Schema.SObjectField> fields) {
        for (Schema.SObjectField fieldToken : fields) {
            if (!fieldToken.getDescribe().isAccessible()) {
                return false;
            }
        }
        return true;
    }

    private static Boolean allCreateable(List<Schema.SObjectField> fields) {
        for (Schema.SObjectField fieldToken : fields) {
            if (!fieldToken.getDescribe().isCreateable()) {
                return false;
            }
        }
        return true;
    }

    private static String abbreviate(String value, Integer maxLength) {
        if (String.isBlank(value) || value.length() <= maxLength) {
            return value;
        }
        return value.substring(0, maxLength);
    }

    private static void addFieldError(
        LadminAIAppointmentBookingResult result,
        String fieldName,
        String message
    ) {
        result.fieldErrors.add(new LadminAIAppointmentFieldError(fieldName, message));
    }

    private static LadminAIAppointmentBookingResult failure(
        String errorCode,
        String userMessage
    ) {
        LadminAIAppointmentBookingResult result =
            new LadminAIAppointmentBookingResult();
        result.errorCode = errorCode;
        result.userMessage = userMessage;
        return result;
    }
}
