({
    initializeAppointmentBooking: function(component, event, helper) {
        var recordId = component.get("v.recordId");
         var optionsLoaded = false;
         var valueLoaded = false;


        // Fetch user info
        var action = component.get("c.getUserName");
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                component.set("v.Prog_Referral_Rep", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);

        // Fetch lead email
        var action1 = component.get("c.getPiklistValues1");
        action1.setParams({ 'RecordId': recordId });
        action1.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                component.set("v.LeadEmail", response.getReturnValue());
            }
        });
        $A.enqueueAction(action1);

        // Fetch Lead Name & set Referral Subject
        var action3 = component.get("c.getLeadName");
        action3.setParams({ "leadId": recordId });
        action3.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var leadName = response.getReturnValue();
                component.set("v.leadName", leadName);
                if (leadName) {
                    component.set("v.Referral_Subject",  leadName + ": Harley Street Hair Clinic Consultation");
                }
            }
        });
        $A.enqueueAction(action3);

        // Reset values
        component.set("v.bookingSource", "");
        component.set("v.bookingstatus", "");
         component.set("v.Inhouse_Created_By", "");


        //  ********************  A C H STARTS ***************************

        // Fetch Booking Source from Lead (Inhouse_Created_By__c)
var bookingSourceAction = component.get("c.getInhouseCreatedBy");
bookingSourceAction.setParams({
    recordId: component.get("v.recordId")
});

bookingSourceAction.setCallback(this, function(response) {
    if (response.getState() === "SUCCESS") {
        component.set("v.bookingSource", response.getReturnValue());
    } else {
        console.error("Error fetching Booking Source:", response.getError());
    }
});

$A.enqueueAction(bookingSourceAction);


// 1️⃣ Fetch picklist options
    var picklistAction = component.get("c.getBookedByPicklistValues");
    picklistAction.setCallback(this, function(res) {
        if (res.getState() === "SUCCESS") {
            component.set("v.bookedByOptions", res.getReturnValue());
            optionsLoaded = true;

            if (valueLoaded) {
                component.set("v.isBookedByReady", true);
            }
        }
    });
    $A.enqueueAction(picklistAction);

    // 2️⃣ Fetch existing Lead value
    var valueAction = component.get("c.getBookedByValue");
    valueAction.setParams({ recordId: recordId });
    valueAction.setCallback(this, function(res) {
        if (res.getState() === "SUCCESS") {
            component.set("v.bookedBy", res.getReturnValue());
            valueLoaded = true;

            if (optionsLoaded) {
                component.set("v.isBookedByReady", true);
            }
        }
    });
    $A.enqueueAction(valueAction);

// ***********************************  A C H OVER *******************************
    }
})