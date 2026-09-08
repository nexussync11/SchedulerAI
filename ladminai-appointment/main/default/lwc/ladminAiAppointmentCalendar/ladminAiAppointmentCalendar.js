import { LightningElement } from 'lwc';
import getAppointments from '@salesforce/apex/LadminAIAppointmentCommandService.getAppointments';
import getSlots from '@salesforce/apex/LadminAIAppointmentAvailabilityService.getAvailableSlots';
import reschedule from '@salesforce/apex/LadminAIAppointmentCommandService.reschedule';
import cancel from '@salesforce/apex/LadminAIAppointmentCommandService.cancel';
import updateStatus from '@salesforce/apex/LadminAIAppointmentCommandService.updateStatus';
export default class LadminAiAppointmentCalendar extends LightningElement{
 rows=[];error;loading=true;selected;action;date;slots=[];time;reason='';status='Confirmed';
 connectedCallback(){this.load();}
 get hasRows(){return this.rows.length>0;} get isReschedule(){return this.action==='reschedule';} get isCancel(){return this.action==='cancel';} get isStatus(){return this.action==='status';}
 get slotOptions(){return this.slots.map(s=>({label:`${s[0]} – ${s[1]}`,value:s[0]}));}
 get statusOptions(){return ['Booked','Confirmed','Checked In','In Progress','Arrived','Completed','No Show'].map(v=>({label:v,value:v}));}
 async load(){this.loading=true;this.error=null;try{this.rows=await getAppointments({startDate:null,endDate:null});}catch(e){this.error=e?.body?.message||'Appointments could not be loaded.';}finally{this.loading=false;}}
 open(e){this.selected=this.rows.find(r=>r.id===e.currentTarget.dataset.id);this.action=e.currentTarget.dataset.action;this.date=null;this.time=null;this.slots=[];}
 close(){this.action=null;this.selected=null;}
 async changeDate(e){this.date=e.target.value;this.slots=await getSlots({serviceResourceId:this.selected.resourceId,locationId:this.selected.locationId,targetDate:this.date});}
 change(e){this[e.target.name]=e.detail?.value??e.target.value;}
 async submit(){try{if(this.isReschedule)await reschedule({appointmentId:this.selected.id,targetDate:this.date,startTime:this.time});if(this.isCancel)await cancel({appointmentId:this.selected.id,reason:this.reason});if(this.isStatus)await updateStatus({appointmentId:this.selected.id,status:this.status});this.close();await this.load();}catch(e){this.error=e?.body?.message||e?.message||'The appointment could not be updated.';}}
}
