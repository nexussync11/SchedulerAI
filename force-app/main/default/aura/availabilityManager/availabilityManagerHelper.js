({
    _pendingTimer: null,
    _pendingMap: {},
     _isSaving: false,

    loadResources: function(component) {
        const action = component.get("c.getAllServiceResources");
        action.setCallback(this, res => {
            if (res.getState() === "SUCCESS") {
                const data = res.getReturnValue();
                const options = data.map(r => ({ label: r.Name, value: r.Id }));
                component.set("v.resourceList", options);
            }
        });
        $A.enqueueAction(action);

        // try auto-get current user's resource
        const action2 = component.get("c.getMyServiceResource");
        action2.setCallback(this, res => {
            if (res.getState() === "SUCCESS") {
                const map = res.getReturnValue();
                if (map && map.Id) {
                    component.set("v.serviceResourceId", map.Id);
                    this.fetchAvailability(component);
                }
            }
        });
        $A.enqueueAction(action2);
    },

    fetchAvailability : function(component) {
        const resId = component.get("v.serviceResourceId");
        if (!resId) return;
        const action = component.get("c.getAvailability");
        action.setParams({ serviceResourceId: resId });
        action.setCallback(this, res => {
            if (res.getState() === "SUCCESS") {
                const existing = res.getReturnValue();
                let days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday']
                    .map(d => ({ label: d, start: '', end: '', breakStart: '', breakEnd: '', isActive: false }));

                existing.forEach(rec => {
                    const d = days.find(x => x.label === rec.Day_Of_Week__c);
                    if (d) {
                        d.start = rec.Start_Time__c || '';
                        d.end = rec.End_Time__c || '';
                        d.breakStart = rec.Break_Start__c || '';
                        d.breakEnd = rec.Break_End__c || '';
                        d.isActive = rec.Is_Active__c || false;
                        d.recordId = rec.Id;
                    }
                });
                component.set("v.dayOptions", days);
            } else {
                // ignore for now
            }
        });
        $A.enqueueAction(action);
    },

    updateDay : function(component, dayLabel, fieldName, value) {
        // queue change
        this._pendingMap[dayLabel + '::' + fieldName] = { dayLabel: dayLabel, fieldName: fieldName, value: value };
        // debounce apply
        if (this._pendingTimer) clearTimeout(this._pendingTimer);
        const self = this;
        this._pendingTimer = setTimeout($A.getCallback(function() {
            let days = component.get("v.dayOptions") || [];
            let newDays = days.map(d => Object.assign({}, d));
            for (let k in self._pendingMap) {
                if (!self._pendingMap.hasOwnProperty(k)) continue;
                const change = self._pendingMap[k];
                const d = newDays.find(x => x.label === change.dayLabel);
                if (d) {
                    if (change.fieldName === 'isActive') d.isActive = !!change.value;
                    else if (change.fieldName === 'start') d.start = change.value || '';
                    else if (change.fieldName === 'end') d.end = change.value || '';
                    else if (change.fieldName === 'breakStart') d.breakStart = change.value || '';
                    else if (change.fieldName === 'breakEnd') d.breakEnd = change.value || '';
                    else d[change.fieldName] = change.value;
                }
            }
            self._pendingMap = {};
            self._pendingTimer = null;
            component.set("v.dayOptions", newDays);
        }), 200);
    },

        saveAvailability : function(component) {
    if (component.get("v._isSaving")) return;
    component.set("v._isSaving", true);

    try {
        const resourceId = component.get("v.serviceResourceId");
        if (!resourceId) {
            $A.get("e.force:showToast").setParams({ title: "Error", message: "Select a Service Resource", type: "error" }).fire();
            component.set("v._isSaving", false);
            return;
        }

        const days = component.get("v.dayOptions") || [];
        const payload = days.map(d => ({
            Id: d.recordId || null,
            Day_Of_Week__c: d.label,
            Start_Time__c: d.start || null,
            End_Time__c: d.end || null,
            Break_Start__c: d.breakStart || null,
            Break_End__c: d.breakEnd || null,
            Is_Active__c: !!d.isActive
        }));

        // SAFE debug
        console.log('Saving availability for', resourceId, 'rows:', payload.length, 'sampleDay:', payload[0] && payload[0].Day_Of_Week__c);

        const action = component.get("c.saveAvailabilityV2"); // or your current method name
        if (!action) {
            console.error("Apex method saveAvailabilityV2 not found on controller.");
            component.set("v._isSaving", false);
            return;
        }

        // IMPORTANT: use key "dayRecords" to match Apex param name
        action.setParams({
            serviceResourceId: resourceId,
            dayRecords: payload    // <-- exact name must match Apex param
        });

        action.setCallback(this, function(response) {
            const state = response.getState();
            console.log('Apex state ->', state);
            if (state === 'SUCCESS') {
                const ret = response.getReturnValue();
                // if Apex returns a Map or Id, inspect it safely
                console.log('Apex return ->', ret);
                $A.get("e.force:showToast").setParams({ title: "Success", message: "Saved", type: "success" }).fire();
            } else if (state === 'ERROR') {
                const errs = response.getError();
                console.error('Apex error', errs);
                $A.get("e.force:showToast").setParams({ title: "Error", message: (errs && errs[0] && errs[0].message) || 'Error', type: "error" }).fire();
            }
            // reset saving flag
            window.setTimeout(() => component.set("v._isSaving", false), 200);
        });

        $A.enqueueAction(action);

    } catch (e) {
        console.error('saveAvailability exception', e);
        $A.get("e.force:showToast").setParams({ title: "JS Error", message: e.message || 'Unexpected', type: "error" }).fire();
        component.set("v._isSaving", false);
    }
}

})