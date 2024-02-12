/*********************************************************************
* Description      : Utility class to deal with methods related to Pricing Portal data & operations.
* Test Class       : PP_DataUtility_Test.apxc
* Author(s)        : Dunte'e Silver - duntee.silver@teleflex.com
* Date         	   : 02/09/2024
* Work Item		   : N/A
**********************************************************************/

public class PP_DataUtility {
    public PP_DataUtility() {

    }

    //Get all active Contract Customer records using a list of SAP Codes/Customer Codes/Account Numbers
    public List<Contract_Customer__c> contractCustomerList(List<String> sapNumList){
        List<Contract_Customer__c> ccList = new List<Contract_Customer__c>();
        ccList = [SELECT Id, Name, Sap_Code__c, Agreement_Number__c, Agreement__c, Condition__c, Condition_Rank__c, Active__c,
                Condition_Record__c, Customer_Group_Name__c, Customer_Group__c, Sales_Org__c, Distribution_Channel__c,
                Key__c, Valid_From__c, Valid_To__c, Agreement__r.Objective__c
                FROM Contract_Customer__c
                WHERE SAP_Code__c IN :sapNumList
                AND Active__c = TRUE];

        return ccList;
    }//end contractCustomerList

    //Get all active Contract Customer records besides rebates (Customer Service)
    //using a list of SAP Codes/Customer Codes/Account Numbers
    public List<Contract_Customer__c> contractCustomerNonRebateList(List<String> sapNumList){
        List<Contract_Customer__c> ccList = new List<Contract_Customer__c>();
        ccList = [SELECT Id, Name, Sap_Code__c, Agreement_Number__c, Agreement__c, Condition__c, Condition_Rank__c, Active__c,
                Condition_Record__c, Customer_Group_Name__c, Customer_Group__c, Sales_Org__c, Distribution_Channel__c,
                Key__c, Valid_From__c, Valid_To__c, Agreement__r.Objective__c
                FROM Contract_Customer__c
                WHERE SAP_Code__c IN :sapNumList
                AND Agreement__r.Objective__c != '06'
                AND Active__c = TRUE];

        return ccList;
    }//end contractCustomerList

    public Contract_Customer__c contractCustomerAgreeFiltList(List<String> sapNumList, List<String> agreeNums){
        Contract_Customer__c ccObj = new Contract_Customer__c();
        ccObj = [SELECT Id, Name, Sap_Code__c, Agreement_Number__c, Agreement__c, Condition__c, Condition_Rank__c, Active__c,
                Condition_Record__c, Customer_Group_Name__c, Customer_Group__c, Sales_Org__c, Distribution_Channel__c,
                Key__c, Valid_From__c, Valid_To__c, Agreement__r.Objective__c
                FROM Contract_Customer__c
                WHERE SAP_Code__c IN :sapNumList
                AND Agreement_Number__c IN :agreeNums
                AND Active__c = TRUE
                ORDER BY condition_rank__c
                LIMIT 1];

        return ccObj;
    }//end contractCustomerList

    //Get all active Contract Material records using a list of Agreement Numbers/Sales Deals numbers
    public List<Contract_Material__c> contractMaterialList(Product2 mcheck, List<String> agreeNums){
        List<Contract_Material__c> cmList = new List<Contract_Material__c>();
        cmList = [SELECT Active__c,Agreement_Number__c,Agreement__c,Condition_Record__c,Director_Price__c,Distribution_Channel__c,
                Division_Check__c,GPO_Contract_Ref__c,Id,Key_Temp__c,Level_Fix__c,Level__c,List_Price__c,Material_Division2__c,
                Material_Division__c,Material_Key__c,Material_Lookup_Key__c,Material_Name__c,Name,Price__c,Pricing_Tier_Access_Mismatch__c,
                Pricing_Tier__c,Process_Tier_Level_Mismatch__c,Product__c,Rep_Price__c,RSM_Price__c,Sales_Org__c,Tier_Level_Name__c,
                Valid_From__c,Valid_To__c,VP_Price__c, Agreement__r.Objective__c
                FROM Contract_Material__c
                WHERE Product__c = :mcheck.Id
                AND Agreement_Number__c IN :agreeNums
                AND Active__c = TRUE
                ORDER BY Price__c];

        return cmList;
    }//end contractCustomerList

}//end of PP_DataUtility class