({
searchHelper : function(component,event,getInputkeyWord) {
  // call the apex class method
     var action = component.get("c.fetchLookUpValues");
      // set param to method  
        action.setParams({
            'searchKeyWord': getInputkeyWord,
            'ObjectName' : component.get("v.objectAPIName"),
            'accRecord':component.get("v.recordId")
          });
      // set a callBack    
        action.setCallback(this, function(response) {
          $A.util.removeClass(component.find("mySpinner"), "slds-show");
            var state = response.getState();
            //alert(state);
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                console.log(storeResponse);
              // if storeResponse size is equal 0 ,display No Result Found... message on screen.      }
                if (response.getReturnValue()!=null) {
                    component.set("v.listOfSearchRecords", storeResponse);
                } else {
                    component.set("v.Message", '');
                  
                }
                // set searchResult list with return value from server.
                //alert(JSON.stringify(storeResponse));
              //  component.set("v.listOfSearchRecords", storeResponse);
            }
            else if(state === "ERROR")
            {
                console.log('error->'+response.getReturnValue());
}
        });
      // enqueue the Action  
        $A.enqueueAction(action);
    
},
})