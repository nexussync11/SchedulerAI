import { api, LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLocations from '@salesforce/apex/LadminAIAppointmentLocationService.getActiveLocations';
import getResources from '@salesforce/apex/LadminAIAppointmentLocationService.getDoctorsForLocation';
import getSlots from '@salesforce/apex/LadminAIAppointmentAvailabilityService.getAvailableSlots';
import bookFromSlot from '@salesforce/apex/LadminAIAppointmentBookingController.bookFromSlot';

export default class LadminAiAppointmentBooking extends LightningElement {
    @api recordId;
    locations = [];
    resources = [];
    locationId;
    resourceId;
    appointmentDate;
    subject = '';
    slots = [];
    selectedSlot;
    loading = true;
    checking = false;
    saving = false;
    error;
    result;

    connectedCallback() { this.loadLocations(); }
    get leadId() { return this.recordId; }
    get needsLeadPicker() { return !this.recordId; }
    get locationOptions() { return this.locations.map((v) => ({ label: v.Name, value: v.Id })); }
    get resourceOptions() { return this.resources.map((v) => ({ label: v.Name, value: v.Id })); }
    get slotOptions() { return this.slots.map((v) => ({ label: `${v[0]} – ${v[1]}`, value: v[0] })); }
    get minimumDate() { return new Date().toISOString().slice(0, 10); }
    get checkDisabled() { return this.checking || !this.leadId || !this.locationId || !this.resourceId || !this.appointmentDate; }
    get saveDisabled() { return this.saving || this.checkDisabled || !this.selectedSlot || !this.subject.trim(); }

    async loadLocations() {
        this.loading = true;
        try { this.locations = await getLocations(); }
        catch (e) { this.error = this.message(e, 'Locations could not be loaded.'); }
        finally { this.loading = false; }
    }
    handleLead(event) { this.recordId = event.detail.recordId; this.resetSlots(); }
    async handleLocation(event) {
        this.locationId = event.detail.value;
        this.resourceId = null;
        this.resources = [];
        this.resetSlots();
        try { this.resources = await getResources({ locationId: this.locationId }); }
        catch (e) { this.error = this.message(e, 'Resources could not be loaded.'); }
    }
    handleInput(event) { this[event.target.name] = event.detail?.value ?? event.target.value; this.resetSlots(); }
    handleSubject(event) { this.subject = event.target.value; }
    resetSlots() { this.slots = []; this.selectedSlot = null; this.result = null; }
    async checkAvailability() {
        this.checking = true; this.error = null; this.result = null;
        try {
            this.slots = await getSlots({ serviceResourceId: this.resourceId, locationId: this.locationId, targetDate: this.appointmentDate });
            if (!this.slots.length) this.error = 'No available times were found for this date.';
        } catch (e) { this.error = this.message(e, 'Availability could not be loaded.'); }
        finally { this.checking = false; }
    }
    handleSlot(event) { this.selectedSlot = event.detail.value; }
    async book() {
        this.saving = true; this.error = null;
        try {
            const response = await bookFromSlot({
                leadId: this.leadId, locationId: this.locationId,
                serviceResourceId: this.resourceId, appointmentDate: this.appointmentDate,
                startTime: this.selectedSlot, subject: this.subject.trim()
            });
            if (!response?.success) throw new Error(response?.userMessage || 'The appointment could not be booked.');
            this.result = response;
            this.slots = []; this.selectedSlot = null;
            this.dispatchEvent(new ShowToastEvent({ title: 'Appointment booked', message: response.userMessage, variant: 'success' }));
        } catch (e) { this.error = this.message(e, 'The appointment could not be booked.'); }
        finally { this.saving = false; }
    }
    message(error, fallback) { return error?.body?.message || error?.message || fallback; }
}
