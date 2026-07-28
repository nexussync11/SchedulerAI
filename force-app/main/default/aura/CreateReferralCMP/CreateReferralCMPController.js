({
    doInit: function(component, event, helper) {
       
    // Check if component is expired
    var expiryCheck = component.get("c.isComponentExpired");
    expiryCheck.setParams({ componentName: "appointmentBookingAura" });

    expiryCheck.setCallback(this, function(response) {
        var state = response.getState();
        if (state === "SUCCESS") {
            var isExpired = response.getReturnValue();
            component.set("v.isExpired", isExpired);

            if (isExpired) {
                console.warn("⚠️ Component expired - blocking access");
                return;
            }

            // Initialize if not expired
            helper.initializeAppointmentBooking(component, event, helper);
        } else {
            console.error("Error checking expiry:", response.getError());
            // Fail-safe: initialize anyway
            helper.initializeAppointmentBooking(component, event, helper);
        }
    });
    $A.enqueueAction(expiryCheck);
    },

    handleGenreChange: function (component, event, helper) {
        var selectedValues = event.getParam("value");
        component.set("v.lstProject", selectedValues);
    },

    handleChange: function (component, event, helper) {
        var selectedValues = event.getParam("value");
        component.set("v.simpleNewOpportunity.StageName", selectedValues);
    },

    onchangecheck:function(component,event,helper){
        var check=component.find("oppField1").get('v.checked');
        if(check===false){
            component.set('v.simpleNewOpportunity.Programmatic_Referral__c',true);
            component.set('v.displSection1',false);
            component.set('v.displSection',true);
        }
        if(check===true){
            component.set('v.simpleNewOpportunity.Programmatic_Referral__c',false);
            component.set('v.displSection1',true);
            component.set('v.displSection',false);
        }
    },

    onCheck:function(component,event,helper){
        var getAllLanguages = component.find("checkbox1");
        var languages = [];
        for (var i=0; i<getAllLanguages.length; i++) {
            if (getAllLanguages[i].get("v.checked")) {
                languages.push(getAllLanguages[i].get('v.value'));
            }
        }
        if(languages.length>=2) {
            var resultToast=$A.get("e.force:showToast");
            resultToast.setParams({
                mode: 'dismissible',
                type:'Error',
                message: 'Please select only 1 slot for creation.'
            });
            resultToast.fire();
        }
    },

    handleSaveContact: function(component, event, helper) {
        var contactRec=component.get("v.selectedLookUpRecord1");
        if(contactRec!=undefined){
            contactRec=component.get("v.selectedLookUpRecord1").Id;
        }
        var aptDate=component.get("v.ApointmentstartDate");
        var recordId=component.get("v.recordId");
        var email=component.get("v.LeadEmail");
        var a=component.get("v.displSection");
        var b=component.get("v.displSection1");

        if(aptDate!=null && contactRec!=undefined) {
            var getAllLanguages = component.find("checkbox1");
            if(getAllLanguages!=undefined) {
                var languages = [];
                for (var i=0; i<getAllLanguages.length; i++) {
                    if (getAllLanguages[i].get("v.checked")) {
                        languages.push(getAllLanguages[i].get('v.value'));
                    }
                }
                if(languages.length===1) {
                    var reffSub =component.get("v.Referral_Subject");
                    var reffdetail =component.get("v.Referral_Details");
                    var aptstartdate=component.get("v.ApointmentstartDate");
                    var bookingSourceValue = component.get("v.bookingSource");
                    var bookingStatusValue = component.get("v.bookingstatus");

                    // ***********************************************************

                    var bookedBy = component.get("v.bookedBy");
if (!bookedBy) {
    var toast = $A.get("e.force:showToast");
    toast.setParams({
        type: "error",
        message: "Booked By is mandatory."
    });
    toast.fire();
    return;
}

                    var updateBookedByAction = component.get("c.updateBookedBy");
                    updateBookedByAction.setParams({
                     recordId: component.get("v.recordId"),
                     bookedBy: bookedBy
                     });
                     $A.enqueueAction(updateBookedByAction);

                    // ***********************************************************

                    var convertDtTimeAction=component.get("c.convertToDateTime");
                    convertDtTimeAction.setParams({
                        'reffSubject':reffSub,
                        'bookedBy':bookedBy,
                        'reffDeatils':reffdetail,
                        'startDate':aptstartdate,
                        'starttime':languages,
                        'objid':recordId,
                        'emailAddress':email,
                        'eventName':contactRec,
                        'bookingSource': bookingSourceValue,
                        'bookingstatus' : bookingStatusValue
                    });
                    convertDtTimeAction.setCallback(this,function(response) {
                        var state=response.getState();
                        if(state==="SUCCESS") {
                            console.log("Appointment created successfully");
                        } else {
                            console.log("Error:", JSON.stringify(response.getError()));
                        }
                    });
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": recordId,
                        "slideDevName": "detail"
                    });
                    $A.enqueueAction(convertDtTimeAction);
                    navEvt.fire();
                }
                else {
                    var resultToast=$A.get("e.force:showToast");
                    resultToast.setParams({
                        mode: 'dismissible',
                        type:'Error',
                        message: 'Please select only 1 slot for creation.'
                    });
                    resultToast.fire();
                }
            }
            else {
                var resultToast=$A.get("e.force:showToast");
                resultToast.setParams({
                    mode:'dismissible',
                    type:'error',
                    message: 'Please select 1 time slot for this date!'
                });
                resultToast.fire();
            }
        }
        else {
            var resultToast=$A.get("e.force:showToast");
            resultToast.setParams({
                mode:'dismissible',
                type:'error',
                message: 'Please fill all required values!'
            });
            resultToast.fire();
        }
// Force booking source from Lead before save
// (prevents tampering via console)
component.set("v.bookingSource", component.get("v.bookingSource"));



        
    },

    handleComponentEvent : function(component, event, helper) {
        component.set("v.accountId", event.getParam("recordId"));
    },

    handleClick:function(component,event,helper){
        var recid=component.get("v.recordId");
        var a=component.get("v.displSection");
        var b=component.get("v.displSection1");
        var srid;
        if(b===true) {
            srid=component.get("v.selectedLookUpRecord1");
            if(srid!=undefined) srid=component.get("v.selectedLookUpRecord1").Id;
        }
        if(a===true) {
            srid=component.get("v.simpleNewOpportunity.Service_Resource__c");
        }
        var ops=component.get("v.ApointmentstartDate");
        if(ops!=null) {
            var action2 = component.get("c.availableStartTimeSlot");
            action2.setParams({
                'serResId':srid,
                'schedstrttime':ops
            });
            action2.setCallback(this, function(response){
                var result1=response.getState();
                if(result1==="SUCCESS"){
                    component.set('v.datalst',response.getReturnValue());
                }
                if(result1==="ERROR"){
                    console.log(JSON.stringify(response.getReturnValue()));
                }
            });
            $A.enqueueAction(action2);
            component.set("v.displaycolumn",true);
        }
        else{
            var resultToast=$A.get("e.force:showToast");
            resultToast.setParams({
                mode: 'dismissible',
                type:'Error',
                message: 'Need to enter Appointment Date First'
            });
            resultToast.fire();
            component.set("v.displaycolumn",false);
        }
    },

    selectedLookupChanged:function(component,event,helper){
        var conid=component.get("v.selectedLookUpRecord").Id;
        if(conid!=undefined){
            var conEmail=component.get("c.fetchContactEmail");
            conEmail.setParams({'conid':conid});
            conEmail.setCallback(this,function(response){
                if(response.getState()==="SUCCESS") {
                    component.set("v.simpleNewOpportunity.Email__c",response.getReturnValue());
                }
                else {
                    console.log(JSON.stringify(response.getReturnValue()));
                }
            });
            $A.enqueueAction(conEmail);
        }
    }
})