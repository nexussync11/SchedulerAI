({
    doInit : function(component, event, helper) {
        // TEMPORARY DEBUG - Check what Apex methods are available
    console.log('=== CHECKING APEX METHODS ===');
    try {
        var action1 = component.get("c.getAllServiceResources");
        var action2 = component.get("c.getMyServiceResource");
        var action3 = component.get("c.getAvailability");
        var action4 = component.get("c.saveAvailability");
        
        console.log('getAllServiceResources:', action1);
        console.log('getMyServiceResource:', action2);
        console.log('getAvailability:', action3);
        console.log('saveAvailability:', action4);
        
        // Check if they're ClientAction or ServerAction
        console.log('saveAvailability type:', action4.toString());
    } catch(e) {
        console.error('Error checking actions:', e);
    }
        // set canonical days
        let days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday']
            .map(d => ({ label: d, start: '', end: '', breakStart: '', breakEnd: '', isActive: false }));
        component.set("v.dayOptions", days);

        // load dropdown & possibly user resource
        helper.loadResources(component);
    },

    handleResourceChange : function(component, event, helper) {
        const selectedId = event.getSource().get("v.value");
        component.set("v.serviceResourceId", selectedId);
        helper.fetchAvailability(component);
    },

    handleCheckboxChange : function(component, event, helper){
        const day = event.getSource().get("v.name");
        const value = event.getSource().get("v.checked");
        helper.updateDay(component, day, 'isActive', value);
    },

    handleTimeChange : function(component, event, helper){
        const day = event.getSource().get("v.name");
        const val = event.getSource().get("v.value");
        const localId = event.getSource().getLocalId();
        let field = 'start';
        if (localId === 'end') field = 'end';
        else if (localId === 'breakStart') field = 'breakStart';
        else if (localId === 'breakEnd') field = 'breakEnd';
        helper.updateDay(component, day, field, val);
    },

    saveAvailability : function(component, event, helper) {
        helper.saveAvailability(component);
    }
})