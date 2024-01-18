@isTest
public class SAPMockHttpSoapStubTest implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        //Creating a fake response
        HttpResponse response=new HttpResponse();
        String responseXMLBody;
        //mock response body
        if(req.getEndpoint().contains('SAP_SOAP_SalesRepLookup')){
        responseXMLBody='<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'+
            +'<soap:Header/>'+
            +' <soap:Body>'+
            +'<n0:ZofI443SalesRepLookupResponse xmlns:n0="urn:sap-com:document:sap:soap:functions:mc-style" xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/">'+
            +'<EtMessage/>'+
            +'<EtSalesRepInfo>'+
            +'<item>'+
            +'<FirstName>Rob</FirstName>'+
            +'<LastName>Haffey</LastName>'+
            +'<Email>robert.haffey@teleflex.com</Email>'+
            +'<PhoneNumber>111-111-1111</PhoneNumber>'+
            +'<PhoneExt/>'+
            +'</item>'+
            +'</EtSalesRepInfo>'+
            +'</n0:ZofI443SalesRepLookupResponse>'+
            +'</soap:Body>'+
            +'</soap:Envelope>';
       
        } else if(req.getEndpoint().contains('SAP_SOAP_OrderHistory')){
            responseXMLBody='<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'+
            +'<soap:Header/>'+
            +'<soap:Body>'+
            +'<ns0:ZofI420OrderHistEcommResponse xmlns:ns0="urn:sap-com:document:sap:soap:functions:mc-style">'+
            +'<EtMessage/>'+
            +'<TOrdHist>'+
            +'<item>'+
            +'<Kunag>0000154368</Kunag>'+
            +'<Vbeln>9991380</Vbeln>'+
            +'<Bstkd>2101023148</Bstkd>'+
            +'<Audat>2023-03-20</Audat>'+
            +'<Status>Fully Shipped</Status>'+
            +'<Bname>Ryan Reichard</Bname>'+
            +'<Bsark>Fax</Bsark>'+
            +'<Auart>Standard Order</Auart>'+
            +'<Brtwr>31334.96</Brtwr>'+
            +'</item>'+
            +'<item>'+
            +'<Kunag>0000154368</Kunag>'+
            +'<Vbeln>10018104</Vbeln>'+
            +'<Bstkd>2101024289</Bstkd>'+
            +'<Audat>2023-03-27</Audat>'+
            +'<Status>In Progress</Status>'+
            +'<Bname/>'+
            +'<Bsark>EDI</Bsark>'+
            +'<Auart>Standard Order</Auart>'+
            +'<Brtwr>29339.03</Brtwr>'+
            +'</item>'+
            +'<item>'+
            +'<Kunag>0000154368</Kunag>'+
            +'<Vbeln>10004579</Vbeln>'+
            +'<Bstkd>2101023744</Bstkd>'+
            +'<Audat>2023-03-22</Audat>'+
            +'<Status>Fully Shipped</Status>'+
            +'<Bname/>'+
            +'<Bsark>EDI</Bsark>'+
            +'<Auart>Standard Order</Auart>'+
            +'<Brtwr>4626.72</Brtwr>'+
            +'</item>'+
            +'</TOrdHist>'+
            +'</ns0:ZofI420OrderHistEcommResponse>'+
            +'</soap:Body>'+
            +'</soap:Envelope>';
                   
        }
        
        response.setBody(responseXMLBody);
        response.setStatusCode(200);
        return response;
    }
  
}