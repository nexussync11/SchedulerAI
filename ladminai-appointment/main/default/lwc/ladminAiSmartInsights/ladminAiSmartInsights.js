import { LightningElement } from 'lwc';
import getInsights from '@salesforce/apex/LadminAIAppointmentAIInsightsService.getInsights';

export default class LadminAiSmartInsights extends LightningElement {
    message;
    loading = true;

    connectedCallback() { this.load(); }

    async load() {
        this.loading = true;
        this.message = null;
        try {
            const result = await getInsights();
            this.message = result?.message || 'No insights were returned. Refresh to try again.';
        } catch (error) {
            this.message = 'AI Smart Insights are temporarily unavailable. Appointment analytics and scheduling are unaffected.';
        } finally {
            this.loading = false;
        }
    }
}
