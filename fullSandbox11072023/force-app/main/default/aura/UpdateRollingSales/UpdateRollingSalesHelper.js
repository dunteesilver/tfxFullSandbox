({
	getResponse : function(component, event, helper) {
        //call apex class method
        console.log('*** Starting getResponse UpdateRollingSalesHelper *** ' );
        var recordId = component.get("v.recordId");
        var action = component.get('c.updateRollingSales');
        console.log('*** recordId *** ' + recordId );
        action.setParams({
            "targetId": recordId
        });
        action.setCallback(this,function(response){
            //store state of response
            var state = response.getState();
            console.log('*** state *** ' + state );
            if (state === "SUCCESS") {
                var rollingSales12 = response.getReturnValue();
                console.log('*** rollingSales12 *** ' + JSON.stringify(rollingSales12) );
                component.set('v.rollingSales', rollingSales12);
                $A.get('e.force:refreshView').fire();
            }
        });
        $A.enqueueAction(action);
    },
})