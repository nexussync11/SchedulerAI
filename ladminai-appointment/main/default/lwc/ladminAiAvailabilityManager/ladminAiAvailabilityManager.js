import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLocations from '@salesforce/apex/LadminAIAppointmentLocationService.getActiveLocations';
import getResources from '@salesforce/apex/LadminAIAppointmentLocationService.getDoctorsForLocation';
import getAvailability from '@salesforce/apex/LadminAIAppointmentAvailabilityService.getAvailabilityAtLocation';
import saveAvailability from '@salesforce/apex/LadminAIAppointmentAvailabilityService.saveAvailabilityAtLocation';
import getSpecialDates from '@salesforce/apex/LadminAIAppointmentAvailabilityService.getSpecialDatesAtLocation';
import saveSpecialDate from '@salesforce/apex/LadminAIAppointmentAvailabilityService.saveSpecialDateAtLocation';
import deleteSpecialDate from '@salesforce/apex/LadminAIAppointmentAvailabilityService.deleteSpecialDate';
import getSlots from '@salesforce/apex/LadminAIAppointmentAvailabilityService.getAvailableSlots';

const DAYS = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
];

function emptyRows() {
    return DAYS.map((day) => ({
        day,
        isActive: false,
        start: '',
        end: '',
        breakStart: '',
        breakEnd: ''
    }));
}

export default class LadminAiAvailabilityManager extends LightningElement {
    resources = [];
    locations = [];
    locationId;
    resourceId;
    days = emptyRows();
    previewDate;
    previewSlots = [];
    isLoading = true;
    isSaving = false;
    isPreviewing = false;
    isDirty = false;
    errorMessage;
    copySourceDay = 'Monday';
    copyTargetDays = [];
    specialDates = [];
    overrideDate;
    overrideType = 'Unavailable';
    overrideStart = '';
    overrideEnd = '';
    overrideBreakStart = '';
    overrideBreakEnd = '';
    overrideId;
    isSavingOverride = false;

    connectedCallback() {
        this.loadLocations();
    }

    get locationOptions() {
        return this.locations.map((location) => ({
            label: location.Name,
            value: location.Id
        }));
    }

    get resourceOptions() {
        return this.resources.map((resource) => ({
            label: resource.Name,
            value: resource.Id
        }));
    }

    get selectedDoctor() {
        return (
            this.resources.find((resource) => resource.Id === this.resourceId)
                ?.Name || 'No doctor selected'
        );
    }

    get selectedTimezone() {
        return this.locations.find((location) => location.Id === this.locationId)
            ?.TimezoneSidKey || 'Select a location';
    }

    get activeDayCount() {
        return this.days.filter((day) => day.isActive).length;
    }

    get displayDays() {
        return this.days.map((day) => ({
            ...day,
            inputsDisabled: !day.isActive
        }));
    }

    get saveDisabled() {
        return !this.locationId || !this.resourceId || !this.isDirty || this.isSaving;
    }

    get previewDisabled() {
        return !this.locationId || !this.resourceId || !this.previewDate || this.isPreviewing;
    }

    get dayOptions() {
        return DAYS.map((day) => ({ label: day, value: day }));
    }

    get copyTargetOptions() {
        return this.dayOptions.filter((option) => option.value !== this.copySourceDay);
    }

    get overrideTypeOptions() {
        return [
            { label: 'Unavailable / Holiday', value: 'Unavailable' },
            { label: 'Custom Hours', value: 'Custom Hours' }
        ];
    }

    get isCustomHours() {
        return this.overrideType === 'Custom Hours';
    }

    get overrideSaveDisabled() {
        return !this.resourceId || !this.locationId || !this.overrideDate ||
            this.isSavingOverride;
    }

    get specialDateRows() {
        return this.specialDates.map((row) => ({
            ...row,
            typeLabel: row.Override_Type__c === 'Unavailable'
                ? 'Unavailable / Holiday' : 'Custom Hours',
            hoursLabel: row.Override_Type__c === 'Unavailable'
                ? 'No booking slots'
                : `${this.toInputTime(row.Start_Time__c)} â€“ ${this.toInputTime(row.End_Time__c)}`
        }));
    }

    get specialDateMonths() {
        const groups = new Map();
        this.specialDateRows.forEach((row) => {
            const date = new Date(`${row.Override_Date__c}T12:00:00Z`);
            const key = row.Override_Date__c.slice(0, 7);
            if (!groups.has(key)) {
                groups.set(key, {
                    key,
                    label: new Intl.DateTimeFormat('en-GB', {
                        month: 'long', year: 'numeric', timeZone: 'UTC'
                    }).format(date),
                    rows: []
                });
            }
            groups.get(key).rows.push({
                ...row,
                dayNumber: date.getUTCDate(),
                weekday: new Intl.DateTimeFormat('en-GB', {
                    weekday: 'short', timeZone: 'UTC'
                }).format(date),
                cardClass: row.Override_Type__c === 'Unavailable'
                    ? 'override-day override-day_closed'
                    : 'override-day override-day_custom'
            });
        });
        return [...groups.values()].sort((left, right) =>
            left.key.localeCompare(right.key)
        );
    }

    async loadLocations() {
        this.isLoading = true;
        this.errorMessage = null;
        try {
            this.locations = await getLocations();
        } catch (error) {
            this.errorMessage =
                'Locations could not be loaded. Check your Salesforce access.';
        } finally {
            this.isLoading = false;
        }
    }

    async handleLocationChange(event) {
        this.locationId = event.detail.value;
        this.resourceId = null;
        this.resources = [];
        this.days = emptyRows();
        this.specialDates = [];
        this.resetOverrideForm();
        this.previewSlots = [];
        this.isDirty = false;
        this.isLoading = true;
        try {
            this.resources = await getResources({ locationId: this.locationId });
        } catch (error) {
            this.errorMessage = 'Doctors could not be loaded for this location.';
        } finally {
            this.isLoading = false;
        }
    }

    async handleResourceChange(event) {
        this.resourceId = event.detail.value;
        this.isLoading = true;
        this.errorMessage = null;
        this.previewSlots = [];
        try {
            const [existing, specialDates] = await Promise.all([
                getAvailability({
                    serviceResourceId: this.resourceId,
                    locationId: this.locationId
                }),
                getSpecialDates({
                    serviceResourceId: this.resourceId,
                    locationId: this.locationId
                })
            ]);
            const byDay = new Map(existing.map((row) => [row.Day_Of_Week__c, row]));
            this.days = DAYS.map((day) => {
                const row = byDay.get(day);
                return {
                    day,
                    isActive: row?.Is_Active__c || false,
                    start: this.toInputTime(row?.Start_Time__c),
                    end: this.toInputTime(row?.End_Time__c),
                    breakStart: this.toInputTime(row?.Break_Start__c),
                    breakEnd: this.toInputTime(row?.Break_End__c)
                };
            });
            this.specialDates = specialDates || [];
            this.isDirty = false;
        } catch (error) {
            this.days = emptyRows();
            this.errorMessage =
                'Availability could not be loaded for this doctor.';
        } finally {
            this.isLoading = false;
        }
    }

    toInputTime(value) {
        if (!value) {
            return '';
        }
        return String(value).substring(0, 5);
    }

    handleDayChange(event) {
        const dayName = event.target.dataset.day;
        const field = event.target.dataset.field;
        const value =
            field === 'isActive' ? event.target.checked : event.target.value;
        this.days = this.days.map((day) =>
            day.day === dayName ? { ...day, [field]: value } : day
        );
        this.isDirty = true;
    }

    handleCopySource(event) {
        this.copySourceDay = event.detail.value;
        this.copyTargetDays = this.copyTargetDays.filter(
            (day) => day !== this.copySourceDay
        );
    }

    handleCopyTargets(event) {
        this.copyTargetDays = event.detail.value;
    }

    copyAvailability(targets) {
        const source = this.days.find((day) => day.day === this.copySourceDay);
        if (!source) return;
        const selected = new Set(targets);
        this.days = this.days.map((day) => selected.has(day.day)
            ? {
                ...day,
                isActive: source.isActive,
                start: source.start,
                end: source.end,
                breakStart: source.breakStart,
                breakEnd: source.breakEnd
            }
            : day
        );
        this.isDirty = true;
    }

    handleCopySelected() {
        this.copyAvailability(this.copyTargetDays);
    }

    handleCopyWeekdays() {
        this.copyAvailability(['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']);
    }

    handleOverrideInput(event) {
        this[event.target.name] = event.detail?.value ?? event.target.value;
        if (event.target.name === 'overrideType' && !this.isCustomHours) {
            this.overrideStart = '';
            this.overrideEnd = '';
            this.overrideBreakStart = '';
            this.overrideBreakEnd = '';
        }
    }

    resetOverrideForm() {
        this.overrideId = null;
        this.overrideDate = null;
        this.overrideType = 'Unavailable';
        this.overrideStart = '';
        this.overrideEnd = '';
        this.overrideBreakStart = '';
        this.overrideBreakEnd = '';
    }

    handleEditOverride(event) {
        const row = this.specialDates.find(
            (item) => item.Id === event.currentTarget.dataset.id
        );
        if (!row) return;
        this.overrideId = row.Id;
        this.overrideDate = row.Override_Date__c;
        this.overrideType = row.Override_Type__c;
        this.overrideStart = this.toInputTime(row.Start_Time__c);
        this.overrideEnd = this.toInputTime(row.End_Time__c);
        this.overrideBreakStart = this.toInputTime(row.Break_Start__c);
        this.overrideBreakEnd = this.toInputTime(row.Break_End__c);
    }

    async refreshSpecialDates() {
        this.specialDates = await getSpecialDates({
            serviceResourceId: this.resourceId,
            locationId: this.locationId
        });
    }

    async handleSaveOverride() {
        this.isSavingOverride = true;
        this.errorMessage = null;
        try {
            await saveSpecialDate({
                serviceResourceId: this.resourceId,
                locationId: this.locationId,
                overrideId: this.overrideId,
                overrideDate: this.overrideDate,
                overrideType: this.overrideType,
                startTime: this.overrideStart || null,
                endTime: this.overrideEnd || null,
                breakStart: this.overrideBreakStart || null,
                breakEnd: this.overrideBreakEnd || null
            });
            await this.refreshSpecialDates();
            this.resetOverrideForm();
            this.dispatchEvent(new ShowToastEvent({
                title: 'Special date saved',
                message: 'The date-specific availability override was saved.',
                variant: 'success'
            }));
        } catch (error) {
            this.errorMessage = error?.body?.message ||
                'The special date could not be saved.';
        } finally {
            this.isSavingOverride = false;
        }
    }

    async handleDeleteOverride(event) {
        this.errorMessage = null;
        try {
            await deleteSpecialDate({
                overrideId: event.currentTarget.dataset.id
            });
            await this.refreshSpecialDates();
        } catch (error) {
            this.errorMessage = error?.body?.message ||
                'The special date could not be removed.';
        }
    }

    handlePreviewDate(event) {
        this.previewDate = event.target.value;
        this.previewSlots = [];
    }

    validateRows() {
        for (const day of this.days) {
            if (!day.isActive) {
                continue;
            }
            if (!day.start || !day.end || day.start >= day.end) {
                return `${day.day}: start time must be before end time.`;
            }
            if (
                (day.breakStart || day.breakEnd) &&
                (!day.breakStart ||
                    !day.breakEnd ||
                    day.breakStart >= day.breakEnd ||
                    day.breakStart < day.start ||
                    day.breakEnd > day.end)
            ) {
                return `${day.day}: the break must be complete and inside working hours.`;
            }
        }
        return null;
    }

    async handleSave() {
        const validationError = this.validateRows();
        if (validationError) {
            this.errorMessage = validationError;
            return;
        }
        this.isSaving = true;
        this.errorMessage = null;
        try {
            await saveAvailability({
                serviceResourceId: this.resourceId,
                locationId: this.locationId,
                dayRecords: this.days.map((day) => ({
                    Day_Of_Week__c: day.day,
                    Start_Time__c: day.start || null,
                    End_Time__c: day.end || null,
                    Break_Start__c: day.breakStart || null,
                    Break_End__c: day.breakEnd || null,
                    Is_Active__c: day.isActive
                }))
            });
            this.isDirty = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Availability saved',
                    message: `${this.selectedDoctor}'s weekly availability was saved.`,
                    variant: 'success'
                })
            );
        } catch (error) {
            this.errorMessage =
                error?.body?.message ||
                'Availability could not be saved. No unsupported schedule features were applied.';
        } finally {
            this.isSaving = false;
        }
    }

    async handlePreview() {
        this.isPreviewing = true;
        this.errorMessage = null;
        try {
            const slots = await getSlots({
                serviceResourceId: this.resourceId,
                targetDate: this.previewDate,
                locationId: this.locationId
            });
            this.previewSlots = slots.map((slot) => ({
                key: slot.join('-'),
                label: `${slot[0]} – ${slot[1]}`
            }));
        } catch (error) {
            this.previewSlots = [];
            this.errorMessage =
                'The existing booking service could not preview slots.';
        } finally {
            this.isPreviewing = false;
        }
    }
}
