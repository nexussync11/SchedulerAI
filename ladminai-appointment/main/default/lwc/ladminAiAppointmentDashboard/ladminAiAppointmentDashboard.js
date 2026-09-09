import { LightningElement } from 'lwc';
import getSnapshot from '@salesforce/apex/LadminAIAppointmentAnalyticsService.getSnapshot';
export default class LadminAiAppointmentDashboard extends LightningElement {
    data; error; loading = true;
    connectedCallback() { this.load(); }
    async load() {
        this.loading = true; this.error = null;
        try { this.data = await getSnapshot(); }
        catch (error) { this.error = error?.body?.message || 'Analytics could not be loaded.'; }
        finally { this.loading = false; }
    }
    get statusRows() { return this.toRows(this.data?.statusMetrics); }
    get locationRows() { return this.toRows(this.data?.locationMetrics); }
    get resourceRows() { return this.toRows(this.data?.resourceMetrics); }
    toRows(values) {
        const entries = Object.entries(values || {}).sort((a,b) => b[1] - a[1]);
        const max = Math.max(1, ...entries.map(([,value]) => value));
        return entries.map(([label,value]) => ({ label, value, style: `width:${Math.max(4, Math.round(value * 100 / max))}%` }));
    }
}
