/*********************************************************************
* Description      : Class to construct xml for request.
* Test Class       : SAPSoapStubControllerTest.apxc
* Author(s)        : Surya Arvan - surya.arvan@teleflex.com
* Date         	   : 04/25/2023
* Work Item		   : W-025980
**********************************************************************/
public class SAPReqXMLEnvelopeGenerator {
/******************************************************************************************/
/***************************************SalesRepLookup***************************************/
/******************************************************************************************/
    //sales rep lookup request xml
    public static String getReqXMLForSalesRep(Map<String, String> prodInfoMap){
        System.debug('vals from prodInfoMap to build req payload=>'+prodInfoMap);
        String prod_category = prodInfoMap.get('prodCatVal')==null ? '<ProductCategory/>' : '<ProductCategory>'+prodInfoMap.get('prodCatVal')+'</ProductCategory>';
        String prod_area = prodInfoMap.get('prodAreaVal')==null ? '<ProductArea/>' : '<ProductArea>'+prodInfoMap.get('prodAreaVal')+'</ProductArea>';
        String sku = prodInfoMap.get('ItemNumber')==null ? '<Sku/>' : '<Sku>'+prodInfoMap.get('ItemNumber')+'</Sku>';
        String requestXMLBody = 
            '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'+
            '<soap:Header/>'+
            '<soap:Body>'+
            '<urn:ZofI443SalesRepLookup xmlns:urn="urn:sap-com:document:sap:soap:functions:mc-style">'+
            '<ISalesRepRequest>'+
            '<UserFname>'+prodInfoMap.get('UserFname')+'</UserFname>'+
            '<UserLname>'+prodInfoMap.get('UserLname')+'</UserLname>'+
            '<UserEmail>'+prodInfoMap.get('UserEmail')+'</UserEmail>'+
            '<Vkorg>'+prodInfoMap.get('salesOrg')+'</Vkorg>'+
            '<Vtweg>10</Vtweg>'+
            '<Spart>00</Spart>'+
            '<Kunag>'+prodInfoMap.get('accCustCode')+'</Kunag>'+
            '<Kunwe>'+prodInfoMap.get('accCustCode')+'</Kunwe>'+
            prod_category+
            prod_area+
            sku+
            '<Langu>EN</Langu>'+
            '<PageId>SFDC</PageId>'+
            '</ISalesRepRequest>'+
            '</urn:ZofI443SalesRepLookup>'+
            '</soap:Body>'+
            '</soap:Envelope>';
        System.debug('requestXMLBody===>'+requestXMLBody);
        return requestXMLBody;
    }
/******************************************************************************************/
/***************************************OrderHistory***************************************/
/******************************************************************************************/    
    //order history request xml
    public static String getReqXMLForOrderHistory(Map<String, String> orderReqMap){
        String requestXMLBody = '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:sap-com:document:sap:soap:functions:mc-style">'+
            '<SOAP-ENV:Header/>'+
            '<SOAP-ENV:Body>'+
            '<urn:ZofI420OrderHistEcomm xmlns:urn="urn:sap-com:document:sap:soap:functions:mc-style" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">'+
            '<ICommerce>'+
            '<Kunag>'+orderReqMap.get('Kunag')+'</Kunag>'+
            '<Audat>'+orderReqMap.get('Audat')+'</Audat>'+
            '<AudatBis>'+orderReqMap.get('AudatBis')+'</AudatBis>'+
            '<PageId>MYORDERS</PageId>'+
            '<Bstkd/>'+
            '<Vkorg>'+orderReqMap.get('Vkorg')+'</Vkorg>'+
            '<Vtweg>10</Vtweg>'+
            '<Spart>00</Spart>'+
            '<Langu>EN</Langu>'+
            '<MaxHits>100</MaxHits>'+
            '</ICommerce>'+
            '<TOrdHist/>'+
            '</urn:ZofI420OrderHistEcomm>'+
            '</SOAP-ENV:Body>'+
            '</SOAP-ENV:Envelope>';
        System.debug('requestXMLBody===>'+requestXMLBody);
        return requestXMLBody;
    }
}