/*********************************************************************
* Description      : mapping of response xml nodes to respective pojo classes.
* Test Class       : SAPSoapStubControllerTest.apxc
* Author(s)        : Surya Arvan - surya.arvan@teleflex.com
* Date         	   : 04/25/2023
* Work Item		   : W-025980
**********************************************************************/
public class SAPSoapXml2POJOMapperCls {
    //sales rep wrapper
    public static List<SAPSoapWrapperHub.SAPSalesRepInfoWrapper> getSalesRepXMLNodesToWrapper(Map<Integer, Map<String,String>> respItemsMap){
        Map<String,String> nodesMap = new Map<String,String>();
        List<SAPSoapWrapperHub.SAPSalesRepInfoWrapper> salesrepinfoLst = new List<SAPSoapWrapperHub.SAPSalesRepInfoWrapper>();
        for (Integer item : respItemsMap.keySet()) {
            SAPSoapWrapperHub.SAPSalesRepInfoWrapper salesRepInfoWrapperObj = new SAPSoapWrapperHub.SAPSalesRepInfoWrapper();
            nodesMap = respItemsMap.get(item);
            for(String nodeName : nodesMap.keySet()){
                if(nodeName == 'FirstName')salesRepInfoWrapperObj.fname = nodesMap.get(nodeName);
                if(nodeName == 'LastName')salesRepInfoWrapperObj.lname = nodesMap.get(nodeName);
                if(nodeName == 'Email')salesRepInfoWrapperObj.email = nodesMap.get(nodeName);
                if(nodeName == 'PhoneNumber')salesRepInfoWrapperObj.phone = nodesMap.get(nodeName);
                if(nodeName == 'PhoneExt')salesRepInfoWrapperObj.phoneExt = nodesMap.get(nodeName);
                if(nodeName == 'Message')salesRepInfoWrapperObj.message = nodesMap.get(nodeName);
                if(nodeName == 'faultcode')salesRepInfoWrapperObj.message = nodesMap.get(nodeName);
            }
            salesrepinfoLst.add(salesRepInfoWrapperObj);
        }
        return salesrepinfoLst;
    }
    //order history wrapper
    public static List<SAPSoapWrapperHub.SAPOrderHistoryWrapper> getOrdHistXMLNodesToWrapper(Map<Integer, Map<String,String>> respItemsMap){
        Map<String,String> nodesMap = new Map<String,String>();
        List<SAPSoapWrapperHub.SAPOrderHistoryWrapper> orderhistoryLst = new List<SAPSoapWrapperHub.SAPOrderHistoryWrapper>();
        for (Integer item : respItemsMap.keySet()) {
            SAPSoapWrapperHub.SAPOrderHistoryWrapper ordHistWrapperObj = new SAPSoapWrapperHub.SAPOrderHistoryWrapper();
            nodesMap = respItemsMap.get(item);
            for(String nodeName : nodesMap.keySet()){
                if(nodeName == 'Kunag')ordHistWrapperObj.sapcode = nodesMap.get(nodeName);
                if(nodeName == 'Vbeln')ordHistWrapperObj.vbeln = nodesMap.get(nodeName);
                if(nodeName == 'Bstkd')ordHistWrapperObj.bstkd = nodesMap.get(nodeName);
                if(nodeName == 'Audat')ordHistWrapperObj.audat = nodesMap.get(nodeName);
                if(nodeName == 'Status')ordHistWrapperObj.status = nodesMap.get(nodeName);
                if(nodeName == 'Bname')ordHistWrapperObj.bname = nodesMap.get(nodeName);
                if(nodeName == 'Bsark')ordHistWrapperObj.bsark = nodesMap.get(nodeName);
                if(nodeName == 'Auart')ordHistWrapperObj.auart = nodesMap.get(nodeName);
                if(nodeName == 'Brtwr')ordHistWrapperObj.brtwr = nodesMap.get(nodeName);
                if(nodeName == 'Message')ordHistWrapperObj.message = nodesMap.get(nodeName);
            }
            orderhistoryLst.add(ordHistWrapperObj);
        }
        return orderhistoryLst;
    }
}