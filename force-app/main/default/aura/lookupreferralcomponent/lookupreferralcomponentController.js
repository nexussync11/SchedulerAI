({
    handleChange: function(component, event, helper) {
        let selectedValue = component.get("v.value");

        //Send the recordId to "Example Component"
        let componentEvent = component.getEvent("lookupEvent");
        componentEvent.setParams({
            "recordId" : selectedValue[0]
        });
        componentEvent.fire();

        //Add to recent list
        if(component.get("v.addToRecent") === true) {
            if(selectedValue !== undefined) {
                if (selectedValue.length > 0 && selectedValue[0].length > 0) {
                    let action = component.get("c.setObjectToRecentItems");
                    action.setParams({
                        "recordId": selectedValue[0]
                    });
                    $A.enqueueAction(action);
                }
            }
        }

        //ReportValidity
        let lookupField = component.find("lookupField");
        lookupField.reportValidity();
    }
});