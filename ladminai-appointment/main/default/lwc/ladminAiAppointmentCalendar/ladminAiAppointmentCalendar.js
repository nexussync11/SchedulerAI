import { LightningElement } from 'lwc';
import getAppointments from '@salesforce/apex/LadminAIAppointmentCommandService.getAppointments';
import getSlots from '@salesforce/apex/LadminAIAppointmentAvailabilityService.getAvailableSlots';
import reschedule from '@salesforce/apex/LadminAIAppointmentCommandService.reschedule';
import cancel from '@salesforce/apex/LadminAIAppointmentCommandService.cancel';
import updateStatus from '@salesforce/apex/LadminAIAppointmentCommandService.updateStatus';
export default class LadminAiAppointmentCalendar extends LightningElement{
 rows=[];error;loading=true;selected;action;date;slots=[];time;reason='';status='Confirmed';searchTerm='';statusFilter='All';range='90';
 connectedCallback(){this.load();}
 get today(){return new Date().toISOString().slice(0,10);} get totalCount(){return this.rows.length;} get filteredCount(){return this.filteredRows.length;} get hasRows(){return this.filteredRows.length>0;} get isDetails(){return this.action==='details';} get isReschedule(){return this.action==='reschedule';} get isCancel(){return this.action==='cancel';} get isStatus(){return this.action==='status';} get hasSaveAction(){return !this.isDetails;} get dialogTitle(){return this.isDetails?'Appointment Details':this.isReschedule?'Reschedule Appointment':this.isCancel?'Cancel Appointment':'Update Appointment Status';}
 get saveDisabled(){return (this.isReschedule&&(!this.date||!this.time))||(this.isCancel&&!this.reason.trim());}
 get slotOptions(){return this.slots.map(s=>({label:`${s[0]} – ${s[1]}`,value:s[0]}));}
 get statusOptions(){return ['Booked','Confirmed','Checked In','In Progress','Arrived','Completed','No Show'].map(v=>({label:v,value:v}));}
 get filterStatusOptions(){return [{label:'All statuses',value:'All'},...this.statusOptions];} get rangeOptions(){return [{label:'Past and future 30 days',value:'30'},{label:'Past and future 90 days',value:'90'},{label:'All loaded appointments',value:'all'}];}
 get filteredRows(){const q=this.searchTerm.toLowerCase();const now=Date.now();const days=this.range==='all'?null:Number(this.range);return this.rows.filter(r=>(this.statusFilter==='All'||r.status===this.statusFilter)&&(!q||[r.subject,r.leadName,r.resourceName,r.locationName,r.status].some(v=>(v||'').toLowerCase().includes(q)))&&(!days||Math.abs(new Date(r.startUtc).getTime()-now)<=days*86400000));}
 async load(){this.loading=true;this.error=null;try{const data=await getAppointments({startDate:null,endDate:null});this.rows=data.map(r=>({...r,statusClass:`pill pill_${(r.status||'unknown').toLowerCase().replaceAll(' ','-')}`}));}catch(e){this.error=e?.body?.message||'Appointments could not be loaded.';}finally{this.loading=false;}}
 changeSearch(e){this.searchTerm=e.target.value||'';} changeStatusFilter(e){this.statusFilter=e.detail.value;} changeRange(e){this.range=e.detail.value;}
 open(e){this.openAction(e.currentTarget.dataset.id,e.currentTarget.dataset.action);} openMenu(e){this.openAction(e.currentTarget.dataset.id,e.detail.value);} openAction(id,action){this.selected=this.rows.find(r=>r.id===id);this.action=action;this.date=null;this.time=null;this.reason='';this.slots=[];}
 close(){this.action=null;this.selected=null;}
 async changeDate(e){this.date=e.target.value;this.slots=await getSlots({serviceResourceId:this.selected.resourceId,locationId:this.selected.locationId,targetDate:this.date});}
 change(e){this[e.target.name]=e.detail?.value??e.target.value;}
 async submit(){try{if(this.isReschedule)await reschedule({appointmentId:this.selected.id,targetDate:this.date,startTime:this.time});if(this.isCancel)await cancel({appointmentId:this.selected.id,reason:this.reason});if(this.isStatus)await updateStatus({appointmentId:this.selected.id,status:this.status});this.close();await this.load();}catch(e){this.error=e?.body?.message||e?.message||'The appointment could not be updated.';}}
}
