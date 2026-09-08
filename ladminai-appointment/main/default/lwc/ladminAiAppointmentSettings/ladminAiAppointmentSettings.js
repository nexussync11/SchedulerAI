import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSettings from '@salesforce/apex/LadminAIAppointmentTimezoneService.getSettings';
import saveBusinessTimezone from '@salesforce/apex/LadminAIAppointmentTimezoneService.saveBusinessTimezone';
import saveUserTimezone from '@salesforce/apex/LadminAIAppointmentTimezoneService.saveUserTimezone';
export default class LadminAiAppointmentSettings extends LightningElement {
    options=[];businessTimezone;userTimezone;loading=true;saving=false;error;
    connectedCallback(){this.load();}
    async load(){this.loading=true;this.error=null;try{const data=await getSettings();this.options=data.options||[];this.businessTimezone=data.businessTimezone;this.userTimezone=data.userTimezone;}catch(e){this.error=this.message(e,'Timezone settings could not be loaded.');}finally{this.loading=false;}}
    changeBusiness(e){this.businessTimezone=e.detail.value;}
    changeUser(e){this.userTimezone=e.detail.value;}
    async saveBusiness(){this.saving=true;this.error=null;try{await saveBusinessTimezone({timezoneSidKey:this.businessTimezone});this.toast('Timezone update started','Salesforce is applying the business timezone. Refresh after the update completes.');}catch(e){this.error=this.message(e,'The business timezone could not be updated.');}finally{this.saving=false;}}
    async saveUser(){this.saving=true;this.error=null;try{const data=await saveUserTimezone({timezoneSidKey:this.userTimezone});this.userTimezone=data.userTimezone;this.toast('Display timezone saved','Your Salesforce display timezone was updated.');}catch(e){this.error=this.message(e,'Your display timezone could not be updated.');}finally{this.saving=false;}}
    toast(title,message){this.dispatchEvent(new ShowToastEvent({title,message,variant:'success'}));}
    message(e,fallback){return e?.body?.message||e?.message||fallback;}
}
