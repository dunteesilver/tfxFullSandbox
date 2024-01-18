/*********************************************************************
* Description      : Implementation class for SAP Connections and Send/Receive xml responses.
* Test Class       : SAPSoapStubControllerTest.apxc
* Author(s)        : Surya Arvan - surya.arvan@teleflex.com
* Date         	   : 04/25/2023
* Work Item		   : W-025980
**********************************************************************/
public class SAPSoapConnectionsImpl {
/******************************************************************************************/
/**************************************SalesReLookup***************************************/
/******************************************************************************************/
    //Global Initilizations
    String endpoint_uri;
    //salesreplookup - this method will connect to sap hana endpoint using named credential basic authentication and get sales rep lookup info.
    //constructs xml envelope for request body.
    public static List<SAPSoapWrapperHub.SAPSalesRepInfoWrapper> getSalesRepInfoFromSAP(Map<String,String> prodInfoMap){
        //initializations
        String endpoint_uri = Label.SAP_SALESREP_ENDPOINT_NMD_CRED_ENV;
        Map<Integer, Map<String,String>> addNodesToWrapperMap;
        List<SAPSoapWrapperHub.SAPSalesRepInfoWrapper> salesrepinfoLst;
        String requestXMLBody;
        //add to prodInfoMap map with prod category and area codes plus user info sales org
        prodInfoMap = SAPSalesRepToolUtil.buildProdInfoMap(prodInfoMap);
        //generate request xml body for sales rep lookup api
        requestXMLBody = SAPReqXMLEnvelopeGenerator.getReqXMLForSalesRep(prodInfoMap);
        //http post connection with soap envelope body
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:'+endpoint_uri);
        System.debug('endpoint-->'+endpoint_uri);
        request.setMethod('POST');
        request.setBody(requestXMLBody);
        HttpResponse response = http.send(request);
        if (response.getStatusCode() != 201) {
            System.debug('The status code returned with sales rep lookup endpoint: ' +
                         response.getStatusCode() + ' ' + response.getStatus());
            System.debug(response.getBody());
            addNodesToWrapperMap = SAPSoapRespXMLEnvelopeParser.genericXmlNodesParserAllEndpoints(response.getBody());
            salesrepinfoLst = SAPSoapXml2POJOMapperCls.getSalesRepXMLNodesToWrapper(addNodesToWrapperMap);
            return salesrepinfoLst;
        } 
        else {
            return salesrepinfoLst;
        }
    }
/******************************************************************************************/
/***************************************OrderHistory***************************************/
/******************************************************************************************/    
    //orderhistory - this method will connect to sap hana endpoint using named credential basic authentication and get order history lookup info.
    //constructs xml envelope for request body.
    public static List<SAPSoapWrapperHub.SAPOrderHistoryWrapper> getOrderHistoryFromSAP(Map<String,String> orderReqMap){
        //initializations
        String endpoint_uri = Label.SAP_ORDHIST_ENDPOINT_NMD_CRED_ENV;
        Map<Integer, Map<String,String>> addNodesToWrapperMap;
        List<SAPSoapWrapperHub.SAPOrderHistoryWrapper> orderHistoryLst;
        String requestXMLBody;
        //modify map to fetch respective prod category and area codes
        orderReqMap = SAPSalesRepToolUtil.buildOrderReqMap(orderReqMap);
        //generate request xml body for sales rep lookup api
        requestXMLBody = SAPReqXMLEnvelopeGenerator.getReqXMLForOrderHistory(orderReqMap);
        //http post connection with soap envelope body
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:'+endpoint_uri);
        request.setMethod('POST');
        request.setBody(requestXMLBody);
        HttpResponse response = http.send(request);
        if (response.getStatusCode() != 201) {
            System.debug('The status code returned with order history endpoint: ' +
                         response.getStatusCode() + ' ' + response.getStatus());
            System.debug(response.getBody());
            addNodesToWrapperMap = SAPSoapRespXMLEnvelopeParser.genericXmlNodesParserAllEndpoints(response.getBody());
            orderHistoryLst = SAPSoapXml2POJOMapperCls.getOrdHistXMLNodesToWrapper(addNodesToWrapperMap);
            return orderHistoryLst;
        } else {
            return orderHistoryLst;
        }
    }
}