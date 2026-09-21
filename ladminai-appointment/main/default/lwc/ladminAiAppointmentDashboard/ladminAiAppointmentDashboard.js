import { LightningElement } from 'lwc';
import getSnapshot from '@salesforce/apex/LadminAIAppointmentAnalyticsService.getSnapshot';
import getDrilldown from '@salesforce/apex/LadminAIAppointmentAnalyticsService.getDrilldown';
import getSnapshotForRange from '@salesforce/apex/LadminAIAppointmentAnalyticsService.getSnapshotForRange';
import getDrilldownForRange from '@salesforce/apex/LadminAIAppointmentAnalyticsService.getDrilldownForRange';
export default class LadminAiAppointmentDashboard extends LightningElement {
    palette = ['#08a88a', '#1769e0', '#7c4dff', '#f59e0b', '#e94f64', '#06a6d7', '#84bd00', '#ed6a2c'];
    data; error; loading = true; detailLoading = false; detailError; detailRows = []; detailTitle = 'Appointment details'; page = 1; pageSize = 10; startDate; endDate;
    connectedCallback() { this.load(); }
    async load() {
        this.loading = true; this.error = null;
        try { this.data = this.startDate&&this.endDate ? await getSnapshotForRange({startDate:this.startDate,endDate:this.endDate}) : await getSnapshot(); }
        catch (error) { this.error = error?.body?.message || 'Analytics could not be loaded.'; }
        finally { this.loading = false; }
    }
    get statusRows() { return this.toRows(this.data?.statusMetrics); }
    get locationRows() { return this.toRows(this.data?.locationMetrics, 2); }
    get resourceRows() { return this.toRows(this.data?.resourceMetrics, 5); }
    get bookingUserRows() { return this.toRows(this.data?.bookingUserMetrics, 1); }
    get serviceRows() { return this.toRows(this.data?.serviceMetrics, 3); }
    get bookingSourceRows() { return this.toRows(this.data?.bookingSourceMetrics, 6); }
    get pagedRows() { const start=(this.page-1)*this.pageSize; return this.detailRows.slice(start,start+this.pageSize).map(row=>({...row,url:`/lightning/r/ServiceAppointment__c/${row.id}/view`})); }
    get totalPages() { return Math.max(1,Math.ceil(this.detailRows.length/this.pageSize)); }
    get pageLabel() { return `Page ${this.page} of ${this.totalPages}`; }
    get previousDisabled() { return this.page<=1; }
    get nextDisabled() { return this.page>=this.totalPages; }
    get hasDetails() { return this.detailRows.length>0; }
    async drilldown(event) {
        const {dimension,value,label}=event.currentTarget.dataset;
        this.detailLoading=true; this.detailError=null; this.page=1;
        try { this.detailRows=this.startDate&&this.endDate ? await getDrilldownForRange({dimension,value:value||null,startDate:this.startDate,endDate:this.endDate}) : await getDrilldown({dimension,value:value||null}); this.detailTitle=`${label} (${this.detailRows.length})`; }
        catch(error){ this.detailError=error?.body?.message||'Appointment details could not be loaded.'; this.detailRows=[]; }
        finally { this.detailLoading=false; requestAnimationFrame(()=>this.template.querySelector('.details')?.scrollIntoView({behavior:'smooth',block:'start'})); }
    }
    previousPage(){if(this.page>1)this.page-=1;}
    nextPage(){if(this.page<this.totalPages)this.page+=1;}
    changeDate(event){this[event.target.dataset.field]=event.target.value;}
    applyDates(){this.detailRows=[];this.page=1;this.load();}
    exportCsv(){if(!this.detailRows.length)return;const fields=['name','subject','customer','resource','location','service','bookedBy','source','startUtc','endUtc','status'];const quote=value=>`"${String(value??'').replaceAll('"','""')}"`;const csv=[fields.join(','),...this.detailRows.map(row=>fields.map(field=>quote(row[field])).join(','))].join('\r\n');const link=document.createElement('a');link.href=`data:text/csv;charset=utf-8,${encodeURIComponent(csv)}`;link.download='appointment-report.csv';link.click();}
    get exportDisabled(){return !this.detailRows.length;}
    get comparisonLabel(){const value=this.data?.periodChangePercent||0;return `${value>=0?'+':''}${value}% vs previous period`;}
    get statusTotal() { return this.statusRows.reduce((total, row) => total + row.value, 0); }
    get statusChartLabel() { return `Appointment status distribution. ${this.statusRows.map(row => `${row.label}: ${row.value}`).join(', ')}`; }
    get statusPieStyle() {
        const rows = this.statusRows;
        const total = this.statusTotal;
        if (!total) return 'background:conic-gradient(#dbe4ef 0deg 360deg)';
        let offset = 0;
        const segments = rows.map(row => {
            const start = offset;
            offset += (row.value / total) * 360;
            return `${row.color} ${start.toFixed(2)}deg ${offset.toFixed(2)}deg`;
        });
        return `background:conic-gradient(${segments.join(',')})`;
    }
    toRows(values, paletteOffset = 0) {
        const entries = Object.entries(values || {}).sort((a,b) => b[1] - a[1]);
        const max = Math.max(1, ...entries.map(([,value]) => value));
        return entries.map(([label,value], index) => {
            const color = this.palette[(index + paletteOffset) % this.palette.length];
            return { label, value, color, style: `width:${Math.max(4, Math.round(value * 100 / max))}%;background:${color}`, swatchStyle: `background:${color}` };
        });
    }
}
