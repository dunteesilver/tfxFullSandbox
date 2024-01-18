/*********************************************************************
* Description      : Controller class for SAP Connection and Send/Receive xml responses.
* Test Class       : SAPSoapStubControllerTest.apxc
* Author(s)        : Surya Arvan - surya.arvan@teleflex.com
* Date         	   : 04/25/2023
* Work Item		   : W-025980
**********************************************************************/
public class SAPSoapWrapperHub {  
    //sales rep wrapper
    public class SAPSalesRepInfoWrapper
    {
        @AuraEnabled public String fname { get; set; }
        @AuraEnabled public String lname { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String phone { get; set; }
        @AuraEnabled public String phoneExt { get; set; }
        @AuraEnabled public String message { get; set; }
    } 
    //order history wrapper
    public class SAPOrderHistoryWrapper
    {
        @AuraEnabled public String sapcode { get; set; }
        @AuraEnabled public String vbeln { get; set; }
        @AuraEnabled public String bstkd { get; set; }
        @AuraEnabled public String audat { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String bname { get; set; }
        @AuraEnabled public String bsark { get; set; }
        @AuraEnabled public String auart { get; set; }
        @AuraEnabled public String brtwr { get; set; }
        @AuraEnabled public String message { get; set; }
    }
}