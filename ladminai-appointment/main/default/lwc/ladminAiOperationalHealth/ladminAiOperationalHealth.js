import { LightningElement } from 'lwc';
import getHealth from '@salesforce/apex/LadminAIOperationalHealthService.getHealth';

export default class LadminAiOperationalHealth extends LightningElement {
    snapshot; loading = true; error;
    connectedCallback() { this.load(); }
    async load() {
        this.loading = true; this.error = null;
        try { this.snapshot = await getHealth(); }
        catch (error) { this.error = error?.body?.message || 'Operational health could not be checked.'; }
        finally { this.loading = false; }
    }
    get bannerClass() { return this.snapshot?.healthy ? 'banner healthy' : 'banner attention'; }
    get bannerIcon() { return this.snapshot?.healthy ? 'utility:success' : 'utility:warning'; }
    get bannerText() { return this.snapshot?.healthy ? 'Core scheduling configuration is healthy' : 'One or more operational checks need attention'; }
    get checks() {
        const s = this.snapshot || {};
        return [
            this.check('Active locations', s.activeLocations > 0, s.activeLocations, 'At least one active location is required.'),
            this.check('Active resources', s.activeResources > 0, s.activeResources, 'At least one active service resource is required.'),
            this.check('Active assignments', s.activeAssignments > 0, s.activeAssignments, 'Assign a resource to a location.'),
            this.check('Availability rows', s.activeAvailabilityRows > 0, s.activeAvailabilityRows, 'Add active working hours.'),
            this.check('Resources without availability', s.activeResourcesWithoutAvailability === 0, s.activeResourcesWithoutAvailability, 'Review active resources that cannot accept bookings.'),
            this.check('Appointments missing Events', s.appointmentsMissingEvents === 0, s.appointmentsMissingEvents, 'Review appointments without Salesforce calendar projections.')
        ];
    }
    get permissions() {
        const s = this.snapshot || {};
        return [this.permission('Configure appointments', s.canConfigure), this.permission('Book appointments', s.canBook), this.permission('Manage resources', s.canManageResources)];
    }
    check(label, ok, value, guidance) { return { label, value: value ?? 0, guidance, icon: ok ? 'utility:success' : 'utility:warning', className: ok ? 'check ok' : 'check warn' }; }
    permission(label, granted) { return { label, value: granted ? 'Granted' : 'Not granted', icon: granted ? 'utility:success' : 'utility:warning', className: granted ? 'permission ok' : 'permission warn' }; }
    exportCsv() {
        if (!this.snapshot) return;
        const rows = [['Metric','Value'], ...this.checks.map((row) => [row.label, row.value]), ['Appointments in last 30 days', this.snapshot.appointmentsLast30Days], ['Business timezone', this.snapshot.businessTimezone], ['Checked at', this.snapshot.checkedAt]];
        const csv = rows.map((row) => row.map((value) => `"${String(value ?? '').replaceAll('"', '""')}"`).join(',')).join('\r\n');
        const link = document.createElement('a');
        link.href = `data:text/csv;charset=utf-8,${encodeURIComponent(csv)}`;
        link.download = 'ladminai-operational-health.csv';
        link.click();
    }
}
