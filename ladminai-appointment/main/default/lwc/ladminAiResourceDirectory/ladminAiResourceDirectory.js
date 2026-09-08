import { LightningElement } from 'lwc';
import getResources from '@salesforce/apex/LadminAIAppointmentResourceAdminService.getResources';
import getAppointments from '@salesforce/apex/LadminAIAppointmentResourceAdminService.getAppointments';
import saveResource from '@salesforce/apex/LadminAIAppointmentResourceAdminService.saveResource';
import setActive from '@salesforce/apex/LadminAIAppointmentResourceAdminService.setActive';
import getLimits from '@salesforce/apex/LadminAIAppointmentEditionService.getLimits';

export default class LadminAiResourceDirectory extends LightningElement {
    resources = [];
    appointments = [];
    searchTerm = '';
    statusFilter = 'ALL';
    isLoading = true;
    isSaving = false;
    errorMessage;
    showEditor = false;
    showAppointments = false;
    editor = this.blankEditor();
    selectedDoctorName;
    limits;

    connectedCallback() { this.loadResources(); }

    get statusOptions() {
        return [
            { label: 'All doctors', value: 'ALL' },
            { label: 'Active', value: 'ACTIVE' },
            { label: 'Inactive', value: 'INACTIVE' }
        ];
    }

    get filteredResources() {
        const term = this.searchTerm.trim().toLowerCase();
        return this.resources.filter((resource) => {
            const textMatch = !term || [
                resource.name,
                ...(resource.locationNames || [])
            ].some((value) => value?.toLowerCase().includes(term));
            const statusMatch =
                this.statusFilter === 'ALL' ||
                (this.statusFilter === 'ACTIVE' && resource.active) ||
                (this.statusFilter === 'INACTIVE' && !resource.active);
            return textMatch && statusMatch;
        }).map((resource) => ({
            ...resource,
            statusLabel: resource.active ? 'Active' : 'Inactive',
            statusClass: resource.active ? 'status status_active' : 'status status_inactive',
            toggleLabel: resource.active ? 'Deactivate' : 'Activate',
            activationDisabled: !resource.active && !this.limits?.canActivateServiceResource,
            locationLabel: (resource.locationNames || []).join(', ') ||
                'No location assigned'
        }));
    }

    get hasResources() { return this.filteredResources.length > 0; }
    get addDisabled() { return this.limits && !this.limits.canActivateServiceResource; }
    get editorTitle() { return this.editor.id ? 'Edit doctor' : 'Add doctor'; }
    get saveDisabled() {
        return this.isSaving || !this.editor.name?.trim();
    }
    get hasAppointments() { return this.appointments.length > 0; }

    async loadResources() {
        this.isLoading = true;
        this.errorMessage = null;
        try {
            const [resources, limits] = await Promise.all([getResources(), getLimits()]);
            this.resources = resources;
            this.limits = limits;
        }
        catch (error) { this.errorMessage = this.message(error, 'Doctors could not be loaded.'); }
        finally { this.isLoading = false; }
    }

    handleSearch(event) { this.searchTerm = event.target.value; }
    handleStatusFilter(event) { this.statusFilter = event.detail.value; }
    handleAdd() { this.editor = this.blankEditor(); this.showEditor = true; }
    handleCloseEditor() { if (!this.isSaving) this.showEditor = false; }
    handleCloseAppointments() { this.showAppointments = false; }

    handleEdit(event) {
        const resource = this.resources.find((item) => item.id === event.currentTarget.dataset.id);
        this.editor = { ...resource };
        this.showEditor = true;
    }

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        this.editor = {
            ...this.editor,
            [field]: event.target.type === 'checkbox' ? event.target.checked : event.target.value
        };
    }

    async handleSave() {
        if (this.saveDisabled) return;
        this.isSaving = true;
        this.errorMessage = null;
        try {
            await saveResource({
                resourceId: this.editor.id || null,
                name: this.editor.name,
                active: this.editor.active,
                description: this.editor.description || null
            });
            this.showEditor = false;
            await this.loadResources();
        } catch (error) { this.errorMessage = this.message(error, 'The doctor could not be saved.'); }
        finally { this.isSaving = false; }
    }

    async handleToggle(event) {
        const resource = this.resources.find((item) => item.id === event.currentTarget.dataset.id);
        this.isLoading = true;
        try {
            await setActive({ resourceId: resource.id, active: !resource.active });
            await this.loadResources();
        } catch (error) {
            this.errorMessage = this.message(error, 'The doctor status could not be changed.');
            this.isLoading = false;
        }
    }

    async handleAppointments(event) {
        const resource = this.resources.find((item) => item.id === event.currentTarget.dataset.id);
        this.selectedDoctorName = resource.name;
        this.appointments = [];
        this.showAppointments = true;
        try { this.appointments = await getAppointments({ resourceId: resource.id }); }
        catch (error) { this.errorMessage = this.message(error, 'Appointments could not be loaded.'); }
    }

    handleAvailability(event) {
        this.dispatchEvent(new CustomEvent('navigate', {
            detail: { view: 'availability', resourceId: event?.currentTarget?.dataset?.id || null }
        }));
    }

    blankEditor() {
        return { id: null, name: '', active: true, description: '' };
    }

    message(error, fallback) { return error?.body?.message || error?.message || fallback; }
}
