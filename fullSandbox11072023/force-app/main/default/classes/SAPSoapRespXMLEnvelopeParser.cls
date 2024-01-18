/*********************************************************************
* Description      : Controller class for SAP Connection and Send/Receive xml responses.
* Test Class       : SAPSoapStubControllerTest.apxc
* Author(s)        : Surya Arvan - surya.arvan@teleflex.com
* Date         	   : 04/25/2023
* Work Item		   : W-025980
**********************************************************************/
public class SAPSoapRespXMLEnvelopeParser {
    public static Map<Integer, Map<String, String>> genericXmlNodesParserAllEndpoints(String xmlRespStr){
        Integer numOfItemsInt = 200;
        Map<Integer, Map<String, String>> sapSOAPRespEnvMap = new Map<Integer, Map<String, String>>();
        Dom.Document doc = new Dom.Document();  
        doc.load(xmlRespStr);  
        Dom.XMLNode rootElement = doc.getRootElement();  
        for ( Dom.XMLNode childElement : rootElement.getChildElements() ) {
            //root elements of each array
            //system.debug(childElement.getName() + '-' + childElement.getText());
            for (Dom.XMLNode detailElement : childElement.getChildElements()){
                //childs elements of each array
                //system.debug(detailElement.getName() + '-' + detailElement.getText());
                for (Dom.XMLNode detailElement1 : detailElement.getChildElements()){
                    Map<String, String> internalServerErrMap = new Map<String, String>();
                    //system.debug('one elements --->'+detailElement1.getName() + '-' + detailElement1.getText());
                    if(detailElement1.getName().equals('faultcode')){
                    internalServerErrMap.put(detailElement1.getName(), detailElement1.getText());
                    sapSOAPRespEnvMap.put(500, internalServerErrMap);
                    }
                    //childs elements of each childs array
                    //system.debug(detailElement1.getName() + '-' + detailElement1.getText());
                    for (Dom.XMLNode detailElement2 : detailElement1.getChildElements()){
                        Map<String, String> responseXMLElemMap = new Map<String, String>();
                        //childs elements of each childs array
                        //system.debug(detailElement2.getName() + '-' + detailElement2.getText());
                        //check if node name is <item>
                        if(detailElement2.getName().equals('item')){
                            for (Dom.XMLNode detailElement3 : detailElement2.getChildElements()){
                                //childs elements of each childs array
                                //system.debug('three elements --->'+detailElement3.getName() + '-' + detailElement3.getText());
                                responseXMLElemMap.put(detailElement3.getName(), detailElement3.getText());
                                sapSOAPRespEnvMap.put(numOfItemsInt, responseXMLElemMap);
                            }
                        }
                        numOfItemsInt++;
                    }
                }
            } 
        }  
        return sapSOAPRespEnvMap;
    } 
}