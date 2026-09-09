import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import productLogo from '@salesforce/resourceUrl/LadminAI_Smart_Appointments_Logo';
import canManageAdministration from '@salesforce/customPermission/LadminAI_Configure_Appointment';
import getSettings from '@salesforce/apex/LadminAIAppointmentTimezoneService.getSettings';

const STANDARD_NAVIGATION = [['home', 'Home', 'utility:home'], ['booking', 'Appointment Booking', 'utility:event'], ['schedule', 'Appointment Schedule', 'utility:date_time'], ['salesforceCalendar', 'Salesforce Calendar', 'utility:event'], ['reports', 'Reports & Dashboard', 'utility:chart']];
const ADMIN_NAVIGATION = [['availability', 'Resource Availability', 'utility:clock'], ['resources', 'Doctors / Resources', 'utility:user'], ['services', 'Services', 'utility:choice'], ['locations', 'Locations', 'utility:location'], ['settings', 'Settings', 'utility:settings']];

export default class LadminAiAppointmentHome extends NavigationMixin(LightningElement) {
    productLogo = productLogo;
    canManageAdministration = canManageAdministration;
    activeView = 'home';
    businessTimezone = 'Salesforce default';
    connectedCallback() { this.loadTimezone(); }
    async loadTimezone() {
        try { const settings = await getSettings(); this.businessTimezone = settings?.businessTimezone || 'Salesforce default'; }
        catch (error) { this.businessTimezone = 'Salesforce default'; }
    }
    get navigationItems() {
        const items = this.canManageAdministration ? [...STANDARD_NAVIGATION, ...ADMIN_NAVIGATION] : STANDARD_NAVIGATION;
        return items.map(([id, label, icon]) => ({ id, label, icon, className: id === this.activeView ? 'nav-item nav-item_active' : 'nav-item', ariaCurrent: id === this.activeView ? 'page' : null }));
    }
    get isHome() { return this.activeView === 'home'; }
    get isBooking() { return this.activeView === 'booking'; }
    get isSchedule() { return this.activeView === 'schedule'; }
    get isAvailability() { return this.activeView === 'availability'; }
    get isResources() { return this.activeView === 'resources'; }
    get isServices() { return this.activeView === 'services'; }
    get isLocations() { return this.activeView === 'locations'; }
    get isReports() { return this.activeView === 'reports'; }
    get isSettings() { return this.activeView === 'settings'; }
    handleNavigate(event) {
        const target = event.currentTarget.dataset.view;
        if (target === 'salesforceCalendar') {
            this[NavigationMixin.Navigate]({ type: 'standard__objectPage', attributes: { objectApiName: 'Event', actionName: 'home' } });
            return;
        }
        if (this.navigationItems.some(({ id }) => id === target)) {
            this.activeView = target;
            requestAnimationFrame(() => this.template.querySelector('main h1')?.focus());
        }
    }
}
