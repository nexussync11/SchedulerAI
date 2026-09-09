import { LightningElement } from 'lwc';
import getReadiness from '@salesforce/apex/LadminAIAppointmentReadinessService.getReadiness';
export default class LadminAiSetupReadiness extends LightningElement {
    readiness; loading=true; error;
    connectedCallback(){this.load();}
    async load(){this.loading=true;this.error=null;try{this.readiness=await getReadiness();}catch(e){this.error=e?.body?.message||'Setup readiness could not be checked.';}finally{this.loading=false;}}
    get summary(){return this.readiness?`${this.readiness.completedSteps} of 5 setup steps complete`:'Checking the configuration required to accept appointments.';}
    get statusClass(){return this.readiness?.bookingReady?'status status_ready':'status status_attention';}
    get statusIcon(){return this.readiness?.bookingReady?'utility:success':'utility:warning';}
    get statusText(){return this.readiness?.bookingReady?'Ready to book appointments':'Setup needs attention';}
    get steps(){const r=this.readiness||{};return [
        this.step('Business timezone',r.timezoneReady,r.businessTimezone||'Choose the operating timezone.'),
        this.step('Active location',r.locationReady,r.locationReady?`${r.activeLocations} active`:'Create or activate a location.'),
        this.step('Active doctor / resource',r.resourceReady,r.resourceReady?`${r.activeResources} active`:'Create or activate a service resource.'),
        this.step('Location assignment',r.assignmentReady,r.assignmentReady?`${r.activeAssociations} active assignment`:'Assign the active resource to the location.'),
        this.step('Availability',r.availabilityReady,r.availabilityReady?`${r.activeAvailabilityRows} active schedule rows`:'Add working hours and optional breaks.')
    ];}
    step(label,ready,detail){return{label,detail,icon:ready?'utility:success':'utility:warning',className:ready?'complete':'incomplete'};}
}
