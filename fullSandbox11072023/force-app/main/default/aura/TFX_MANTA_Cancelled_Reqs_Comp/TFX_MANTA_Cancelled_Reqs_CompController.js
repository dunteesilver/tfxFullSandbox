({
    myAction : function(component, event, helper) {


        
        var haccId = ''+component.get("v.selectedId"); 
        var regionName = component.get("v.regionName");
        
        if(haccId.length === 0){
            haccId += 'All';
        }
        if(regionName.length === 0){
            regionName += 'All';
        }


        var action = component.get("c.getAllOrSelHospCancelledReqs");
        action.setParams({'haccId' : haccId, 'regionName' : regionName});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.allCancelledReqsLst", response.getReturnValue());
                component.set("{!v.isLoading}", false); 
            } else {
                console.log("Failed with state: " + state);
            }
        });
        
        $A.enqueueAction(action);
    },
    
    srchOpenReqsForHosp : function (component, event, helper) {

        var haccId = ''+component.get("v.selectedId"); 
        var regionName = ''+component.get("v.regionName"); 
       
        if(haccId.length === 0){
            haccId += 'All';
        }
        if(regionName.length === 0){
            regionName += 'All';
        }
       
        var action = component.get("c.getAllOrSelHospCancelledReqs");
        action.setParams({
            'haccId' : haccId,
            'regionName' : regionName
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {                
                component.set("v.allCancelledReqsLst", response.getReturnValue());
            } else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
    }, 
    
    navigateToTFX_MANTA_Comp : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef: "c:TFX_MANTA_Comp"
            //componentAttributes :{ }
        });
        evt.fire();
    }
})