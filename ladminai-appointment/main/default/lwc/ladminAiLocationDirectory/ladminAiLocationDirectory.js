import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLocations from '@salesforce/apex/LadminAIAppointmentLocationService.getLocations';
import getLocationTypes from '@salesforce/apex/LadminAIAppointmentLocationService.getLocationTypes';
import saveLocation from '@salesforce/apex/LadminAIAppointmentLocationService.saveLocation';
import setActive from '@salesforce/apex/LadminAIAppointmentLocationService.setActive';
import getResources from '@salesforce/apex/LadminAIAppointmentResourceAdminService.getResources';
import getLimits from '@salesforce/apex/LadminAIAppointmentEditionService.getLimits';

export default class LadminAiLocationDirectory extends LightningElement {
    locations = [];
    doctors = [];
    locationTypes = [];
    search = '';
    status = 'active';
    loading = true;
    saving = false;
    error;
    showEditor = false;
    editor = this.blankEditor();
    limits;

    connectedCallback() { this.load(); }
    blankEditor() {
        return { id: null, name: '', locationType: '', description: '', active: true, doctorIds: [] };
    }
    get statusOptions() {
        return [
            { label: 'Active locations', value: 'active' },
            { label: 'Inactive locations', value: 'inactive' },
            { label: 'All locations', value: 'all' }
        ];
    }
    get typeOptions() {
        return this.locationTypes.map((value) => ({ label: value, value }));
    }
    get doctorOptions() {
        return this.doctors.map((doctor) => ({ label: doctor.name, value: doctor.id }));
    }
    get filteredLocations() {
        const term = this.search.trim().toLowerCase();
        return this.locations.filter((row) => {
            const statusMatches = this.status === 'all' ||
                (this.status === 'active' ? row.active : !row.active);
            const textMatches = !term || `${row.name} ${row.locationType || ''} ${row.description || ''}`
                .toLowerCase().includes(term);
            return statusMatches && textMatches;
        }).map((row) => ({
            ...row,
            statusLabel: row.active ? 'Active' : 'Inactive',
            statusClass: row.active ? 'status active' : 'status inactive',
            toggleLabel: row.active ? 'Deactivate' : 'Activate',
            activationDisabled: !row.active && !this.limits?.canActivateLocation
        }));
    }
    get hasLocations() { return this.filteredLocations.length > 0; }
    get addDisabled() { return this.limits && !this.limits.canActivateLocation; }
    get editorTitle() { return this.editor.id ? 'Edit Location' : 'Add Location'; }
    get saveDisabled() {
        return this.saving || !this.editor.name.trim() || !this.editor.locationType;
    }
    async load() {
        this.loading = true;
        this.error = null;
        try {
            const [locations, types, doctors, limits] = await Promise.all([
                getLocations(), getLocationTypes(), getResources(), getLimits()
            ]);
            this.locations = locations || [];
            this.locationTypes = types || [];
            this.doctors = doctors || [];
            this.limits = limits;
        } catch (error) {
            this.error = 'Locations could not be loaded. Check your access.';
        } finally { this.loading = false; }
    }
    handleSearch(event) { this.search = event.target.value; }
    handleStatus(event) { this.status = event.detail.value; }
    handleAdd() {
        this.editor = this.blankEditor();
        if (this.locationTypes.length === 1) this.editor.locationType = this.locationTypes[0];
        this.showEditor = true;
    }
    handleEdit(event) {
        const row = this.locations.find((item) => item.id === event.currentTarget.dataset.id);
        if (!row) return;
        this.editor = {
            id: row.id,
            name: row.name || '',
            locationType: row.locationType || '',
            description: row.description || '',
            active: row.active,
            doctorIds: row.doctorIds || []
        };
        this.showEditor = true;
    }
    handleField(event) {
        const field = event.target.dataset.field;
        const value = event.target.type === 'checkbox' ? event.target.checked :
            (event.detail?.value ?? event.target.value);
        this.editor = { ...this.editor, [field]: value };
    }
    handleDoctors(event) {
        this.editor = { ...this.editor, doctorIds: event.detail.value };
    }
    handleClose() { if (!this.saving) this.showEditor = false; }
    async handleSave() {
        if (this.saveDisabled) return;
        this.saving = true;
        this.error = null;
        try {
            await saveLocation({
                locationId: this.editor.id,
                name: this.editor.name,
                locationType: this.editor.locationType,
                description: this.editor.description,
                active: this.editor.active,
                doctorIds: this.editor.doctorIds
            });
            this.showEditor = false;
            await this.load();
            this.toast('Location saved', 'The Scheduler location was saved.', 'success');
        } catch (error) {
            this.error = error?.body?.message || 'The location could not be saved.';
        } finally { this.saving = false; }
    }
    async handleToggle(event) {
        const row = this.locations.find((item) => item.id === event.currentTarget.dataset.id);
        if (!row) return;
        try {
            await setActive({ locationId: row.id, active: !row.active });
            await this.load();
            this.toast('Location updated', `${row.name} is now ${row.active ? 'inactive' : 'active'}.`, 'success');
        } catch (error) {
            this.error = error?.body?.message || 'Location status could not be changed.';
        }
    }
    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
