/*********************************************************************
* Description     : This class is used for handling Pricing Logic when
add line items from PP_Price_Quote Page.
* Author          : Dun Silver
* Test Class      : PP_SAP_Price_Test, PP_Global_Test_Class
**********************************************************************/
global without sharing class PP_SAP_Price {
    
    public string status{get;set;}
    Public Boolean userRoleBoolean {get;set;}
    public Map<String, String> cMap = new Map<String, String>();
    
    public static List<Sales_Orgs__c> soList;
    static{
        soList = [SELECT Id,Name, Sales_Org__c, Distribution_Channel__c, Pricing_Type__c, Active__c FROM Sales_Orgs__c WHERE Active__c = true];
    }
    
    //Variable used in pricing logic to determine list price
    Public Map<String,Sales_Orgs__c> soMap {get{
        Map<String,Sales_Orgs__c> soMapNew = new Map<String,Sales_Orgs__c>();
        system.debug('*** soList.size() *** ' + soList.size() );
        if(soList.size() > 0){
            for(Sales_Orgs__c curr : soList){
                soMapNew.put(curr.Name,curr);
            }//end for loop
        }//end if
        else{
            Sales_Orgs__c salesOrgUs = testDataFactoryPP.createSalesOrg('US6010',true,'All','US60','10');
            //insert salesOrgUs;
            soMapNew.put(salesOrgUs.name,salesOrgUs);
        }
        return soMapNew; 
    }set;}
    
    public string userRoleName{get;set;} //using to check role for EMEA
    //Start Constructor
    public PP_SAP_Price(){
        //Variable used in pricing logic to determine userType
        User u = [SELECT Id, UserRole.Name FROM User WHERE Id =:UserInfo.getUserId() LIMIT 1];
        String userRole = u.UserRole.Name;
        userRoleName = u.UserRole.Name; //added for logic for EMEA

        if(Test.isRunningTest() && userRole == NULL){
            userRole = 'Teleflex Global IT';
        }
        
        if(userRole.containsIgnoreCase('Customer Service') ){
            userRoleBoolean= TRUE;
        }
        else{
            userRoleBoolean= FALSE; 
        }
        
        //Map of Sales_Condition_Mapping__c to avoid repetitive SOQl Queries
        for(Sales_Condition_Mapping__c scm : [SELECT Name, Mapped_Value__c FROM Sales_Condition_Mapping__c]){
            cMap.put(scm.Name, scm.Mapped_Value__c);
        }
        system.debug('cMap ============== getSAPpriceBulk ' + cMap);
    }
    
    //method for Alt Care approval process routing
    Public void lineClassCheck(Id objId){
        Integer countClass = 0;
        String className = '';
        Set<String> checkSet = new Set<String>();
        List<Price_Quote__c> updQuote = new List<Price_Quote__c>();
        
        List<Price_Quote_Line_Item__c> lineItems = [Select Id, Material_Name__r.Class__c, Price_Quote__c, Price_Quote__r.BusinessUnit__c
                                                    FROM Price_Quote_Line_Item__c
                                                    WHERE Price_Quote__c = :objId];
        
        if(lineItems.size() > 0){
            for(Price_Quote_Line_Item__c curr : lineItems){
                checkSet.add(curr.Material_Name__r.Class__c);
            }
            
            //checkSet.addAll(lineItems);
            if(checkSet.contains('Anesthesia') && checkSet.contains('Respiratory')){
                countClass = 3;
            }
            else if(checkSet.contains('Anesthesia') && !checkSet.contains('Respiratory')){
                countClass = 1;
            }
            else if(!checkSet.contains('Anesthesia') && checkSet.contains('Respiratory')){
                countClass = 2;
            }
            else if(checkSet.contains('Chest Drainage') ){
                className = 'Chest Drainage';
            }
            else{
                countClass = 3;
                className = '';
            }
            
            Price_Quote__c pq = new Price_Quote__c(id=objId, Product_Class_Count__c = countClass, Line_Item_Class__c = className);
            updQuote.add(pq);
            if(updQuote.size()>0)
                update updQuote;
        }//end outter if
        else{
            
            List<PRF__c> updPrf = new List<PRF__c>();
            
            List<PRF_Line_Item__c> prflineItems = [Select Id, Material_Name__r.Class__c, PRF__c,Material_Name__r.Brand_Name__c
                                                   FROM PRF_Line_Item__c
                                                   WHERE PRF__c = :objId];
            
            if(prflineItems.size() > 0){
                for(PRF_Line_Item__c curr : prflineItems){
                    checkSet.add(curr.Material_Name__r.Class__c);
                }
                
                //system.debug('checkSet *** ' + checkSet);
                //checkSet.addAll(lineItems);
                if(checkSet.contains('Anesthesia') && checkSet.contains('Respiratory')){
                    countClass = 3;
                }
                else if(checkSet.contains('Anesthesia') && !checkSet.contains('Respiratory')){
                    countClass = 1;
                }
                else if(!checkSet.contains('Anesthesia') && checkSet.contains('Respiratory')){
                    countClass = 2;
                }
                else if(checkSet.contains('Chest Drainage') ){
                    className = 'Chest Drainage';
                }
                else{
                    countClass = 3;
                    className = '';
                }
                
                //System.debug('*** className *** ' + className);
                PRF__c prf = new PRF__c(id=objId, Product_Class_Count__c = countClass, Line_Item_Class__c = className);
                updPrf.add(prf);
                if(updPrf.size()>0)
                    update updPrf;
            }//end lineitem size check
            
        }//end else
        
    }//end of lineClassCheck
    
    //method for Anesthesia Approval routing
    Public void lineProdCheckAnes(Id objId){
        Integer countClass = 0;
        Set<String> checkSet = new Set<String>();
        Set<String> lmaCheckSet = new Set<String>();
        Set<String> checkSet2 = new Set<String>();
        Set<String> isoCheckSet = new Set<String>();
        List<Price_Quote__c> updQuote = new List<Price_Quote__c>();
        
        List<Price_Quote_Line_Item__c> lineItems = [Select Id, Material_Name__r.Class__c, Price_Quote__c, Material_Name__r.SubGroup__c, Material_Name__r.Brand_Name__c,
                                                    Material_Name__r.Description, Price_Quote__r.BusinessUnit__c FROM Price_Quote_Line_Item__c
                                                    WHERE Price_Quote__c = :objId];
        
        if(lineItems.size() > 0){
            String myDesc = '';
            for(Price_Quote_Line_Item__c curr : lineItems){
                if(curr.Material_Name__c!=null){
                    myDesc = curr.Material_Name__r.Description;
                    system.debug('curr.Material_Name__r.SubGroup__c *** ' + curr.Material_Name__r.SubGroup__c);
                    system.debug('curr.Material_Name__r.Brand_Name__c *** ' + curr.Material_Name__r.Brand_Name__c);
                    system.debug('myDesc *** ' + myDesc);
                    if(curr.Material_Name__r.SubGroup__c == 'LMA Atomizers'){
                        lmaCheckSet.add(curr.Material_Name__r.SubGroup__c);
                    }
                    else if(curr.Material_Name__r.Brand_Name__c == 'Hudson RCI' && (myDesc.contains('ISO-GARD') || myDesc.contains('ISO - GARD') ) ){
                        isoCheckSet.add(curr.Material_Name__r.Description);
                    }
                    else{
                        checkSet.add(curr.Material_Name__r.SubGroup__c);
                    }
                }
            }//end of for loop
            
            system.debug('checkSet *** ' + checkSet);
            system.debug('lmaCheckSet *** ' + lmaCheckSet);
            system.debug('isoCheckSet *** ' + isoCheckSet);
            //checkSet.addAll(lineItems);
            if(lmaCheckSet.IsEmpty() && isoCheckSet.IsEmpty() ){//if product is LMA Atomizers (check SubGroup__c)
                countClass = 1;
            }
            else if( (!lmaCheckSet.IsEmpty() || !isoCheckSet.IsEmpty() ) && checkSet.IsEmpty()){ //if product is Hudson RCI ISO-Gard (check Brand_Name__c for Hudson and Description for ISO-GARD)
                countClass = 2;
            }
            else if( (!lmaCheckSet.IsEmpty() || !isoCheckSet.IsEmpty() ) && !checkSet.IsEmpty() ){//if quote contains both
                countClass = 3;
            }
            else{//cover all bases
                countClass = 1;
            }
            
            Price_Quote__c pq = new Price_Quote__c(id=objId, Product_Class_Count__c = countClass);
            updQuote.add(pq);
            if(updQuote.size()>0)
                update updQuote;
        }//end outter if
        else{
            
            List<PRF__c> updPrf = new List<PRF__c>();
            
            List<PRF_Line_Item__c> prflineItems = [Select Id, Material_Name__r.Class__c, PRF__c, Material_Name__r.Description, Material_Name__r.SubGroup__c,Material_Name__r.Brand_Name__c
                                                   FROM PRF_Line_Item__c
                                                   WHERE PRF__c = :objId];
            
            if(prflineItems.size() > 0){
                String myDesc = '';
                for(PRF_Line_Item__c curr : prflineItems){
                    if(curr.Material_Name__c!=null){
                        myDesc = curr.Material_Name__r.Description;
                        if(curr.Material_Name__r.SubGroup__c == 'LMA Atomizers'){
                            lmaCheckSet.add(curr.Material_Name__r.SubGroup__c);
                        }
                        else if(curr.Material_Name__r.Brand_Name__c == 'Hudson RCI' && (myDesc.contains('ISO-GARD') || myDesc.contains('ISO - GARD') ) ){
                            isoCheckSet.add(curr.Material_Name__r.Description);
                        }
                        else{
                            checkSet.add(curr.Material_Name__r.SubGroup__c);
                        }
                    }
                }
                
                system.debug('checkSet *** ' + checkSet);
                system.debug('lmaCheckSet *** ' + lmaCheckSet);
                system.debug('isoCheckSet *** ' + isoCheckSet);
                //checkSet.addAll(lineItems);
                if(lmaCheckSet.IsEmpty() && isoCheckSet.IsEmpty() ){//if product is LMA Atomizers (check SubGroup__c)
                    countClass = 1;
                }
                else if( (!lmaCheckSet.IsEmpty() || !isoCheckSet.IsEmpty() ) && checkSet.IsEmpty()){ //if product is Hudson RCI ISO-Gard (check Brand_Name__c for Hudson and Description for ISO-GARD)
                    countClass = 2;
                }
                else if( (!lmaCheckSet.IsEmpty() || !isoCheckSet.IsEmpty() ) && !checkSet.IsEmpty() ){//if quote contains both
                    countClass = 3;
                }
                else{//cover all bases
                    countClass = 1;
                }
                
                PRF__c prf = new PRF__c(id=objId, Product_Class_Count__c = countClass);
                updPrf.add(prf);
                if(updPrf.size()>0)
                    update updPrf;
            }//end lineitem size check
            
        }//end else
        
    }//end of lineProdCheckAnes
    
    
    //Start Product Class check for Canada
    Public void lineProdCheckIcap(Id objId){
        
        Integer countClass = 0;
        Set<String> class2526 = new Set<String>();
        Set<String> class25 = new Set<String>();
        Set<String> class26 = new Set<String>();
        
        List<Price_Quote__c> updQuote = new List<Price_Quote__c>();
        
        List<Price_Quote_Line_Item__c> lineItems = [Select Id, Material_Name__r.Class__c, Price_Quote__c, Material_Name__r.SubGroup__c, Price_Quote__r.BusinessUnit__c,
                                                    Material_Name__r.Brand_Name__c, Material_Name__r.Description, Material_Name__r.Product_Class__c
                                                    FROM Price_Quote_Line_Item__c
                                                    WHERE Price_Quote__c = :objId];
        
        if(lineItems.size() > 0){
            String myDesc = '';
            for(Price_Quote_Line_Item__c curr : lineItems){
                if(curr.Material_Name__c!=null){
                    myDesc = curr.Material_Name__r.Description;
                    if(curr.Material_Name__r.Product_Class__c == '0025' ){
                        class25.add(curr.Material_Name__r.Product_Class__c);
                    }
                    else if(curr.Material_Name__r.Product_Class__c == '0026' ){
                        class26.add(curr.Material_Name__r.Product_Class__c);
                    }
                }
            }//end of for loop
            
            system.debug('class25 *** ' + class25);
            system.debug('class26 *** ' + class26);
            
            if(class25.size() > 0 ){
                countClass = 0025;
            }
            else if( class26.size() > 0 ){
                countClass = 0026;
            }
            else{
                countClass = 0;
            }
            
            Price_Quote__c pq = new Price_Quote__c(id=objId, Product_Class_Count__c = countClass);
            updQuote.add(pq);
            if(updQuote.size()>0)
                update updQuote;
        }//end outter if
        else{   //start of PRF product line check
            
            List<PRF__c> updPrf = new List<PRF__c>();
            
            List<PRF_Line_Item__c> prflineItems = [Select Id, Material_Name__r.Class__c, PRF__c, Material_Name__r.Description,
                                                   Material_Name__r.SubGroup__c,Material_Name__r.Brand_Name__c, Material_Name__r.Product_Class__c
                                                   FROM PRF_Line_Item__c
                                                   WHERE PRF__c = :objId];
            
            if(prflineItems.size() > 0){
                String myDesc = '';
                for(PRF_Line_Item__c curr : prflineItems){
                    if(curr.Material_Name__c!=null){
                        myDesc = curr.Material_Name__r.Description;
                        if(curr.Material_Name__r.Product_Class__c == '0025' || curr.Material_Name__r.Product_Class__c == '0026'){
                            class2526.add(curr.Material_Name__r.Product_Class__c);
                        }
                    }
                }//end of for loop
                
                system.debug('class2526 *** ' + class2526);
                
                if(class2526.size() > 0 ){//if product is LMA Atomizers (check SubGroup__c)
                    countClass = 2526;
                }
                else{
                    countClass = 0;
                }
                
                PRF__c prf = new PRF__c(id=objId, Product_Class_Count__c = countClass);
                updPrf.add(prf);
                if(updPrf.size()>0)
                    update updPrf;
            }//end lineitem size check
            
        }//end else
        //end
    }
    //End Product Class check for Canada
    
    public List<Contract_Partnership__c> getContractPartnership(String sapSold){
        List<Contract_Partnership__c> cp = [SELECT Sale_to__c, Ship_to__c
                                                  FROM Contract_Partnership__c
                                                  WHERE Ship_to__c =:sapSold
                                                  AND Disabled__c = FALSE]; 
        return cp;   
    }
    
    public List<Contract_Customer__c> getContractCustomer(List<String> cmList, List<String> cnlist){
        List<Contract_Customer__c> cc = [SELECT Agreement__r.Agreement_Number__c, Account__r.SAP_Sold_To__c, Condition__c
                                                           FROM Contract_Customer__c
                                                           WHERE Agreement__r.Agreement_Number__c IN :cmList
                                                           AND Account__r.SAP_Sold_To__c IN :cnlist
                                                           AND Active__c = TRUE
                                                           order by Condition_Rank__c Desc
                                                           LIMIT 1];
        return cc;
    }
    
    //Start New SAP Price Logic
    /*public void getSAPpriceBulkOld(List<String> materialStr,String quoteId){
        
        List<Price_Quote_Line_Item__c> lineItemList = new List<Price_Quote_Line_Item__c>();
        List<String> newMaterialStr = new List<String>();
        List<String> notInList = new List<String>();
        Set<String> str1 = new Set<String>();
        Set<String> str2 = new Set<String>();
        List<Product2> mcheck = new List<Product2>();
        String soldToType; //Variable to hold Sold To Price List Type
        String shipTo;
        
        str1.addAll(materialStr); //added 1st string to set for comparison later
        
        try{
            Price_Quote__c pq = [SELECT Account_Name__r.SAP_Sold_To__c, Account_Name__r.Account_Group__c, Sales_Org_Key__c, Line_Count__c,
                                 Owner_Business_Unit__c, Account_Name__r.Price_List_Type__c, BusinessUnit__c, CurrencyIsoCode, Type__c
                                 FROM Price_Quote__c
                                 WHERE Id =: quoteId LIMIT 1];
            system.debug('pq getSAPpriceBulk ====================== ' + pq);
            Decimal rowOrder = pq.Line_Count__c;
            
            shipTo = pq.Account_Name__r.Sap_Sold_To__c;
            //adding logic for ASK Agreements
            if(pq.Type__c == 'ASK Agreement'){
                mcheck = [SELECT Id, Name, Sales_Org__c, Distribution_Channel__c, Floor_Price__c,
                          List_Price__c, RSM_Price__c, Rep_Price__c, Director_Price__c, Description,
                          Product_Description_Custom__c, Material_Status_Numeric__c, Cost_Formula__c, Min_Order_Qty__c,
                          Distributor_List__c, Alt_Site_List__c, MRP_Group__c, SearchableProducts__c, CurrencyIsoCode
                          FROM Product2
                          WHERE Name IN :materialStr
                          AND Sales_Org_Key__c =: pq.Sales_Org_Key__c
                          AND Duplicate__c = FALSE AND ASK_Custom_Kit__c = TRUE];
            }
            else{
                mcheck = [SELECT Id, Name, Sales_Org__c, Distribution_Channel__c, Floor_Price__c,
                          List_Price__c, RSM_Price__c, Rep_Price__c, Director_Price__c, Description,
                          Product_Description_Custom__c, Material_Status_Numeric__c, Cost_Formula__c, Min_Order_Qty__c,
                          Distributor_List__c, Alt_Site_List__c, MRP_Group__c, SearchableProducts__c, CurrencyIsoCode
                          FROM Product2
                          WHERE Name IN :materialStr
                          AND Sales_Org_Key__c =: pq.Sales_Org_Key__c
                          AND Duplicate__c = FALSE AND SearchableProducts__c = TRUE];
            }
            //end of ASK Agreement logic
                
            //mcheck.remove(NULL);
            system.debug('mcheck.size() getSAPpriceBulk ====================== ' + mcheck.size() );
            
            // Create the Product Mapping
            map<String, Product2> prodmap = new map<String, Product2>();
            for(Product2 pmap : mcheck){
                prodmap.put(pmap.Name, pmap);
                newMaterialStr.add(pmap.Name);
            }
            //system.debug('prodmap getSAPpriceBulk: ' + prodmap);
            
            str2.addAll(newMaterialStr);
            
            for(String s : str1){
                if (!str2.contains(s)){System.debug('*** getSAPpriceBulk ERROR:  Does not contain the string ***');notInList.add(s);}
            }
            
            if(notInList.size() > 0){ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'The following product(s) where not added to the Price Quote: ' + notInList));}
            
            // Determine which SAP Number to use for Lookup
            string pcn = pq.Account_Name__r.SAP_Sold_To__c;
            if(pq.Account_Name__r.Account_Group__c == 'Z002'){
                for(Contract_Partnership__c cp : [SELECT Sale_to__c, Ship_to__c
                                                  FROM Contract_Partnership__c
                                                  WHERE Ship_to__c =:pq.Account_Name__r.SAP_Sold_To__c
                                                  AND Disabled__c = FALSE])
                {
                    pcn = cp.Sale_to__c;
                }
                //Query to get Price List Type of SAP Sold To Account
                soldToType = [SELECT Price_List_Type__c FROM Account WHERE SAP_Sold_To__c = :pcn LIMIT 1].Price_List_Type__c;
            }
            else{
                soldToType = pq.Account_Name__r.Price_List_Type__c;
            }
            // Start building the line items
            
            // Prospect Account Process (No SAP) #1
			if(pq.Account_Name__r.SAP_Sold_To__c == NULL){
                for(String ml : materialStr){
                    if(prodmap.get(ml) != NULL){
                        ++rowOrder;
                        Price_Quote_Line_Item__c  pqLineItem = new Price_Quote_Line_Item__c (
                            Price_Quote__c = pq.Id,
                            Material_Name__c = prodmap.get(ml).Id,
                            Quantity__c = 1,
                            RSM_Price__c = prodmap.get(ml).RSM_Price__c,
                            Rep_Price__c = prodmap.get(ml).Rep_Price__c,
                            Director_Price__c = prodmap.get(ml).Director_Price__c,
                            Floor_Price__c = prodmap.get(ml).Floor_Price__c,
                            Cost__c = prodmap.get(ml).Cost_Formula__c,
                            Material_Status__c = prodmap.get(ml).Material_Status_Numeric__c,
                            Row_Order__c = rowOrder,
                            MRP_Group__c = prodmap.get(ml).MRP_Group__c,
                            CurrencyIsoCode = pq.CurrencyIsoCode
                        );
                        
                        //logic to handle Hospital, Distributor, and Alt Site pricing
                        if( soMap.get(pq.Sales_Org_Key__c).Pricing_Type__c == 'All' ){
                               //Alt Site Accounts
                               if(soldToType == 'ZA'){
                                   if(prodmap.get(ml).Alt_Site_List__c != 0.00){
                                       pqLineItem.List_Price__c = prodmap.get(ml).Alt_Site_List__c;
                                       pqLineItem.Sales_Price__c = prodmap.get(ml).Alt_Site_List__c;
                                       pqLineItem.Eligible_Price__c = prodmap.get(ml).Alt_Site_List__c;
                                   }
                                   else{
                                       pqLineItem.List_Price__c = prodmap.get(ml).Alt_Site_List__c;
                                       pqLineItem.Sales_Price__c = 0.00;
                                       pqLineItem.Eligible_Price__c = prodmap.get(ml).Alt_Site_List__c;
                                   }
                               }
                               
                               //Distributor Accounts
                               if(soldToType == 'ZD'){
                                   if(prodmap.get(ml).Distributor_List__c != 0.00){
                                       pqLineItem.List_Price__c = prodmap.get(ml).Distributor_List__c;
                                       pqLineItem.Sales_Price__c = prodmap.get(ml).Distributor_List__c;
                                       pqLineItem.Eligible_Price__c = prodmap.get(ml).Distributor_List__c;
                                   }
                                   else{
                                       pqLineItem.List_Price__c = prodmap.get(ml).Distributor_List__c;
                                       pqLineItem.Sales_Price__c = 0.00;
                                       pqLineItem.Eligible_Price__c = prodmap.get(ml).Distributor_List__c;
                                   }
                               }
                               
                               //Hospital Accounts
                               if(soldToType == 'ZH' || soldToType == '' || soldToType == NULL){
                                   if(prodmap.get(ml).List_Price__c != 0.00){
                                       pqLineItem.List_Price__c = prodmap.get(ml).List_Price__c;
                                       pqLineItem.Sales_Price__c = prodmap.get(ml).List_Price__c;
                                       pqLineItem.Eligible_Price__c = prodmap.get(ml).List_Price__c;
                                   }
                                   else{
                                       pqLineItem.List_Price__c = prodmap.get(ml).List_Price__c;
                                       pqLineItem.Sales_Price__c = 0.00;
                                       pqLineItem.Eligible_Price__c = prodmap.get(ml).List_Price__c;
                                   }
                               }
                               //end of logic to handle Hospital, Distributor, and Alt Site pricing
                           }//end of if pq.Sales_Org_Key__c
                        else{
                            //Start of US6020 ZD Pricing Only
                            if( soMap.get(pq.Sales_Org_Key__c).Pricing_Type__c == 'Distributor List' ){
                                if(prodmap.get(ml).Distributor_List__c != 0.00){
                                    pqLineItem.List_Price__c = prodmap.get(ml).Distributor_List__c;
                                    pqLineItem.Sales_Price__c = prodmap.get(ml).Distributor_List__c;
                                    pqLineItem.Eligible_Price__c = prodmap.get(ml).Distributor_List__c;
                                }
                                else{
                                    pqLineItem.List_Price__c = prodmap.get(ml).Distributor_List__c;
                                    pqLineItem.Sales_Price__c = 0.00;
                                    pqLineItem.Eligible_Price__c = prodmap.get(ml).Distributor_List__c;
                                }
                            }
                        }//end of else pq.Sales_Org_Key__c
                        
                        // Check for custom product description. Was specifically for Surgical but now we have Cardiac as well.
                        if(prodmap.get(ml).Product_Description_Custom__c != NULL){
                            pqLineItem.Product_Description__c = prodmap.get(ml).Product_Description_Custom__c;
                        }
                        else{
                            pqLineItem.Product_Description__c = prodmap.get(ml).Description;
                        }
                        
                        lineItemList.add(pqLineItem);
                    }
                    else{
                        //Add line to miss list
                    }
                    
                }
                // DML - Insert Lines
                If(lineItemList.size() > 0){
                    //system.debug('lineItemList getSAPpriceBulk ======================= ' + lineItemList);
                    database.insert(lineItemList,false);
                }
            }//end of NO SAP Code Testing
            else{ // Customer Account Process #2
                system.debug('Starting getPrice with SAP');
                List<SAPRealPriceSet__x> sapList = new List<SAPRealPriceSet__x>();
                List<string> cnlist = new List<String>();
                cnlist.add(pq.Account_Name__r.SAP_Sold_To__c);
                
                system.debug('pcn (Primary Customer Number) getSAPpriceBulk ================ ' + pcn);
                system.debug('cnlist (Customer Number List) getSAPpriceBulk ================= ' + cnlist);
                
                Map<String, String> cMap = new Map<String, String>();
                for(Sales_Condition_Mapping__c scm : [SELECT Name, Mapped_Value__c FROM Sales_Condition_Mapping__c]){
                    cMap.put(scm.Name, scm.Mapped_Value__c);
                }
                system.debug('cMap ============== getSAPpriceBulk ' + cMap);
                
                Map<String, String> obMap = new Map<String, String>();
                obMap.put('01', 'Direct/Rebate');
                obMap.put('02', 'Direct');
                obMap.put('03', 'Distributor Netbill');
                obMap.put('04', 'Specialty Market');
                obMap.put('05', 'Strategic Accounts');
                obMap.put('06', 'Rebate Only');
                system.debug('obMap ============== getSAPpriceBulk ' + obMap);
              
                //Start getting SAP info
                for(String ml : materialStr)
                {
                    System.debug('*** IN for(String ml : materialStr) ***');
                    if(prodmap.get(ml) != NULL){
                        System.debug('*** IN if(prodmap.get(ml) != NULL) ***');
                        if(Test.isRunningTest()){
                            system.debug('Test Is Running ============== ' + Test.isRunningTest() );
                            if(pq.Account_Name__r.SAP_Sold_To__c == '999999'){
                                System.debug('*** Test Is Running and SAP Code 999999 ***');
                                SAPRealPriceSet__x testSAP = new SAPRealPriceSet__x(
                                    SalesDeal__c = '50009064',
                                    Price__c = 0.00,
                                    Material__c = prodmap.get(ml).name,
                                    MtrlStatus__c = '40',
                                    SalesMtrlStatus__c = '40',
                                    ValidFrom__c = Date.Today(),
                                    ValidTo__c = Date.Today() + 1000,
                                    AgrDesc__c = 'Duke University SURGR',
                                    Condition__c = 'XNAF',
                                    OwnerName__c = 'Duke Univ Health System',
                                    Owner__c = 'IDN-032',
                                    AgrObjective__c = '06',
                                    Customer__c  = '0000999999'
                                );
                                sapList.add(testSAP);
                            }//end if sap code check
                            else if(Test.isRunningTest() && pq.Account_Name__r.SAP_Sold_To__c != '999999'){
                                System.debug('*** Test Is Running and SAP Code != 999999 ***');
                                SAPRealPriceSet__x testSAP = new SAPRealPriceSet__x(
                                    SalesDeal__c = '50009064',
                                    Price__c = 123.00,
                                    Material__c = prodmap.get(ml).name,
                                    MtrlStatus__c = '40',
                                    SalesMtrlStatus__c = '40',
                                    ValidFrom__c = Date.Today(),
                                    ValidTo__c = Date.Today() + 1000,
                                    AgrDesc__c = 'Duke University SURGR',
                                    Condition__c = 'XNAF',
                                    OwnerName__c = 'Duke Univ Health System',
                                    Owner__c = 'IDN-032',
                                    AgrObjective__c = '06',
                                    Customer__c  = '0000'+pq.Account_Name__r.Sap_Sold_To__c
                                );
                                sapList.add(testSAP); 
                            }//end sap code check
                        }//end (Test.isRunningTest())
                        else{
                            System.debug('*** Test Is NOT Running ***');
                            sapList = [SELECT SalesDeal__c, Price__c, Material__c, MtrlStatus__c,
                                       ValidFrom__c, ValidTo__c, Agreement__c, AgrDesc__c, Condition__c,
                                       OwnerName__c, Owner__c, AgrObjective__c, Customer__c, SalesMtrlStatus__c,
                                       DistChnl__c, Currency__c, MatDesc__c, VAT__c
                                       FROM SAPRealPriceSet__x
                                       WHERE SalesOrg__c =:prodmap.get(ml).Sales_Org__c
                                       AND DistChnl__c =:prodmap.get(ml).Distribution_Channel__c
                                       AND Customer__c =:pcn
                                       AND ShipTo__c =:shipTo
                                       AND Material__c =:prodmap.get(ml).Name
                                       AND EffDate__c =:datetime.now()
                                      ];
                        }                       
                                        
                        if( sapList[0].AgrObjective__c == '06' && userRoleBoolean ){
                            System.debug('*** IN REBATE ONLY CHECK ***');
                            //SAP_1stPick = sapList[0].Agreement_Number__c.right(8);
                            list<String> ccaList = new list<String>();
                            for(Contract_Customer__c cc : [SELECT Agreement__r.Agreement_Number__c
                                                           FROM Contract_Customer__c
                                                           WHERE Account__r.SAP_Sold_To__c IN :cnlist
                                                           AND Active__c = TRUE])
                            {
                                ccaList.add(cc.Agreement__r.Agreement_Number__c);
                            }
                            //system.debug('ccalist getSAPpriceBulk:' + ccaList);
                            
                            // Contract Material List - Used to filter the Contract Customers
                            list<String> cmList = new list<String>();
                            // Material Map - Used to filter...
                            map<String, String> matMap = new map<String, String>();
                            for(Contract_Material__c cm : [SELECT Product__r.Name, Agreement__r.Agreement_Number__c, Agreement__r.Sales_Org__c
                                                           FROM Contract_Material__c
                                                           WHERE Product__r.Name IN :materialStr
                                                           AND Agreement_Number__c IN :ccaList
                                                           AND Active__c = TRUE
                                                           ORDER BY Price__c])
                            {
                                cmList.add(cm.Agreement__r.Agreement_Number__c);
                                matMap.put(cm.Agreement__r.Agreement_Number__c, cm.Product__r.Name);
                            }
                            //system.debug('cmList.size getSAPpriceBulk: ' + cmList.size());
                            
                            sapList.remove(0);
                            
                            //**************************** Start Contract Customer Lookup ************************************
                            for(Contract_Customer__c cc : [SELECT Agreement__r.Agreement_Number__c, Account__r.SAP_Sold_To__c, Condition__c
                                                           FROM Contract_Customer__c
                                                           WHERE Agreement__r.Agreement_Number__c IN :cmList
                                                           AND Account__r.SAP_Sold_To__c IN :cnlist
                                                           AND Active__c = TRUE
                                                           order by Condition_Rank__c
                                                           LIMIT 10])
                            {
                                sapList = [SELECT SalesDeal__c, Price__c, Material__c, MtrlStatus__c, ValidFrom__c,
                                           ValidTo__c, Agreement__c, AgrDesc__c, Condition__c,
                                           OwnerName__c, Owner__c, AgrObjective__c, Customer__c, SalesMtrlStatus__c,
                                           DistChnl__c, Currency__c, MatDesc__c, VAT__c
                                           FROM SAPRealPriceSet__x
                                           WHERE SalesOrg__c = :prodMap.get(ml).Sales_Org__c
                                           AND DistChnl__c = :prodMap.get(ml).Distribution_Channel__c
                                           AND Agreement__c = :cc.Agreement__r.Agreement_Number__c
                                           AND Customer__c = :cc.Account__r.SAP_Sold_To__c
                                           AND ShipTo__c =:shipTo 
                                           AND Material__c = :matMap.get(cc.Agreement__r.Agreement_Number__c)
                                           AND EffDate__c = :datetime.now()
                                           LIMIT 1 ];
                            }
                            //**************************** End Contract Customer Lookup ************************************
                        }//end of if( sapList[0].AgrObjective__c == '06' && userRoleBoolean )
                            
                        //re-populating sapList if test is running
                        if(Test.isRunningTest()){
                            if(pq.Account_Name__r.SAP_Sold_To__c == '999999'){
                                SAPRealPriceSet__x testSAP = new SAPRealPriceSet__x(
                                    SalesDeal__c = '50009064',
                                    Price__c = 0.00,
                                    Material__c = prodmap.get(ml).name,
                                    MtrlStatus__c = '40',
                                    SalesMtrlStatus__c = '40',
                                    ValidFrom__c = Date.Today(),
                                    ValidTo__c = Date.Today() + 1000,
                                    AgrDesc__c = 'Duke University SURGR',
                                    Condition__c = 'XNAF',
                                    OwnerName__c = 'Duke Univ Health System',
                                    Owner__c = 'IDN-032',
                                    AgrObjective__c = '06',
                                    Customer__c  = '0000999999'
                                );
                                sapList.add(testSAP);
                            }//end if sap code check
                            else{
                                SAPRealPriceSet__x testSAP = new SAPRealPriceSet__x(
                                    SalesDeal__c = '50009064',
                                    Price__c = 123.00,
                                    Material__c = prodmap.get(ml).name,
                                    MtrlStatus__c = '40',
                                    SalesMtrlStatus__c = '40',
                                    ValidFrom__c = Date.Today(),
                                    ValidTo__c = Date.Today() + 1000,
                                    AgrDesc__c = 'Duke University SURGR',
                                    Condition__c = 'XNAF',
                                    OwnerName__c = 'Duke Univ Health System',
                                    Owner__c = 'IDN-032',
                                    AgrObjective__c = '06',
                                    Customer__c  = '0000'+pq.Account_Name__r.Sap_Sold_To__c
                                );
                                sapList.add(testSAP); 
                            }//end sap code check
                            
                        }//end (Test.isRunningTest())
                        
						System.debug('*** sapList.size() getSapPriceBulk *** ' + sapList.size() );                            
                        //************************************* Start Rebate Only Check *******************************************
                        for(SAPRealPriceSet__x sap : sapList )
                        {
                            ++rowOrder;
                            //system.debug('sap getSAPpriceBulk: ' + sap);
                            
                            string conremap = sap.Condition__c;
                            if(cMap.get(sap.Condition__c) != NULL){
                                conremap = cMap.get(sap.Condition__c);
                            }
                            //system.debug('conditionMap getSAPpriceBulk: ' + cMap);
                            
                            String salesDeal;
                            if(sap.SalesDeal__c != NULL){
                                //System.debug('*** IN sap.SalesDeal__c != NULL getSAPpriceBulk *** ' + sap.SalesDeal__c);
                                if( sap.AgrObjective__c == '06' && userRoleBoolean ){
                                    //System.debug('*** IN sap.AgrObjective__c == 06 && userRole.containsIgnoreCase(Customer Service) getSAPpriceBulk *** ');
                                    salesDeal = 'No Contract';
                                }
                                else{
                                    //System.debug('*** IN sap.SalesDeal__c != NULL getSAPpriceBulk *** ' + sap.SalesDeal__c);
                                    salesDeal = sap.SalesDeal__c.right(8);
                                    //System.debug('*** In else of 06 check salesDeal getSAPpriceBulk *** ' + salesDeal);
                                }
                                
                            }
                            else{
                                //System.debug('*** salesDeal = No Contract getSAPpriceBulk *** ');
                                salesDeal = 'No Contract';
                            }
                            //system.debug('salesDeal getSAPpriceBulk ================ ' + salesDeal);
                            
                            String mstatus;
                            if(sap.SalesMtrlStatus__c != NULL){
                                mstatus = sap.SalesMtrlStatus__c;
                            }
                            else if(sap.MtrlStatus__c != NULL){
                                mstatus = sap.MtrlStatus__c;
                            }
                            
                            System.debug('*** Final salesDeal check getSAPpriceBulk *** ' + salesDeal);
                            
                            Price_Quote_Line_Item__c  li = new Price_Quote_Line_Item__c (
                                Price_Quote__c = pq.Id,
                                Material_Name__c = prodmap.get(ml).Id,
                                Material_Status__c = mstatus,
                                Quantity__c = 1,
                                CurrencyIsoCode = pq.CurrencyIsoCode,
                                //List_Price__c = prodmap.get(ml).List_Price__c,
                                RSM_Price__c = prodmap.get(ml).RSM_Price__c,
                                Rep_Price__c = prodmap.get(ml).Rep_Price__c,
                                Director_Price__c = prodmap.get(ml).Director_Price__c,
                                Floor_Price__c = prodmap.get(ml).Floor_Price__c,
                                Cost__c = prodmap.get(ml).Cost_Formula__c,
                                Condition__c = conremap,
                                //Sales_Deal_Description__c = sap.AgrDesc__c,
                                Sales_Number__c = salesDeal,
                                Row_Order__c = rowOrder,
                                Objective__c = sap.AgrObjective__c,
                                MRP_Group__c = prodmap.get(ml).MRP_Group__c,
                                Material_Description__c = sap.MatDesc__c,
                                Min_Order_Qty__c = prodmap.get(ml).Min_Order_Qty__c
                            );
                            
                            // Check for custom product description. Was specifically for Surgical but now we have Cardiac as well.
                            if(prodmap.get(ml).Product_Description_Custom__c != NULL){
                                li.Product_Description__c = prodmap.get(ml).Product_Description_Custom__c;
                            }
                            else{
                                li.Product_Description__c = prodmap.get(ml).Description;
                            }
                            
                            //adding check for VAT for EMEA
                            system.debug('****BU*****'+ pq.Businessunit__c);
                            if(pq.Businessunit__c == 'EMEA'){
                                li.Quantity__c = prodmap.get(ml).Min_Order_Qty__c;
                                system.debug('****VAT*****'+ li.VAT__c);
                                li.Material_Description__c=sap.MatDesc__c;
                                li.CurrencyIsoCode = sap.Currency__c;
                                if(sap.VAT__c == NULL){
                                    li.VAT__c = NULL;
                                }
                                 else{
                                    system.debug('****DESC*****'+ li.Material_Description__c);
                                    li.VAT__c = Decimal.Valueof(sap.Vat__c);
                                     }
                            }
                            else{
                                li.CurrencyIsoCode = pq.CurrencyIsoCode;
                            }

                            // Check for eligible price = 0
                            if(sap.Price__c != 0.00){
                                li.Sales_Price__c = sap.Price__c;
                                li.Eligible_Price__c = sap.Price__c;
                                
                                if(salesDeal == 'No Contract'){
                                    li.Sales_Deal_Description__c = NULL;
                                }
                                else{
                                    System.debug('*** sap.AgrDesc__c getSAPpriceBulk *** ' + sap.AgrDesc__c);
                                    li.Sales_Deal_Description__c = sap.AgrDesc__c;
                                }
                                
                                //start of check for Customer Service Rebate Only
                                
                                if(sap.AgrObjective__c == '06' && userRoleBoolean ){
                                    
                                    li.Sales_Price__c = prodMap.get(ml).List_Price__c;
                                    li.Eligible_Price__c = prodMap.get(ml).List_Price__c;
                                    
                                    if(salesDeal == 'No Contract'){
                                        li.Sales_Deal_Description__c = NULL;
                                    }
                                    else{
                                        System.debug('*** sap.AgrDesc__c getSAPpriceBulk *** ' + sap.AgrDesc__c);
                                        li.Sales_Deal_Description__c = sap.AgrDesc__c;
                                    }
                                    
                                    
                                    if(soldToType == 'ZA'){
                                        System.debug('*** In Alt Site List Pricing for if sap.Price__c != 0.00 getSAPpriceBulk ***');
                                        li.List_Price__c = prodMap.get(ml).Alt_Site_List__c;
                                        li.Sales_Price__c = prodMap.get(ml).Alt_Site_List__c;
                                        li.Eligible_Price__c = prodMap.get(ml).Alt_Site_List__c;
                                    }
                                    
                                    //Distributor Accounts
                                    if(soldToType == 'ZD'){
                                        System.debug('*** In Distributor List Pricing for if sap.Price__c != 0.00 getSAPpriceBulk ***');
                                        li.List_Price__c = prodMap.get(ml).Distributor_List__c;
                                        li.Sales_Price__c = prodMap.get(ml).Distributor_List__c;
                                        li.Eligible_Price__c = prodMap.get(ml).Distributor_List__c;
                                    }
                                    
                                    //Hospital Accounts
                                    if(soldToType == 'ZH' || soldToType == '' || soldToType == NULL){
                                        System.debug('*** In Hospital List Pricing for if sap.Price__c != 0.00 getSAPpriceBulk ***');
                                        li.List_Price__c = prodMap.get(ml).List_Price__c;
                                        li.Sales_Price__c = prodMap.get(ml).List_Price__c;
                                        li.Eligible_Price__c = prodMap.get(ml).List_Price__c;
                                    }
                                }
                                //end of check for Customer Service Rebate Only
                                System.debug('*** pq.Sales_Org_Key__c getSapPriceBulk *** ' + pq.Sales_Org_Key__c);
                                //logic to handle Hospital, Distributor, and Alt Site pricing
                                if( soMap.get(pq.Sales_Org_Key__c).Pricing_Type__c == 'All' ){
                                       //Alt Site Accounts
                                       if(pq.Account_Name__r.Price_List_Type__c == 'ZA'){
                                           li.List_Price__c = prodmap.get(ml).Alt_Site_List__c;
                                       }
                                       
                                       //Distributor Accounts
                                       if(pq.Account_Name__r.Price_List_Type__c == 'ZD'){
                                           li.List_Price__c = prodmap.get(ml).Distributor_List__c;
                                       }
                                       
                                       //Hospital Accounts
                                       if(soldToType == 'ZH' || soldToType == '' || soldToType == NULL){
                                           li.List_Price__c = prodmap.get(ml).List_Price__c;
                                       }
                                       //end of logic to handle Hospital, Distributor, and Alt Site pricing
                                   }//end of if pq.Sales_Org_Key__c
                                else{
                                    if( soMap.get(pq.Sales_Org_Key__c).Pricing_Type__c == 'Distributor List' ){
                                        li.List_Price__c = prodmap.get(ml).Distributor_List__c;
                                        li.Sales_Price__c = prodmap.get(ml).Distributor_List__c;
                                        li.Eligible_Price__c = prodmap.get(ml).Distributor_List__c;
                                    }
                                    else{
                                        li.List_Price__c = prodmap.get(ml).List_Price__c;
                                    } 
                                }//end of else pq.Sales_Org_Key__c
                                
                            }//if(sap.Price__c != 0.00)
                            else{
                                //logic to handle Hospital, Distributor, and Alt Site pricing
                                System.debug('*** soldToType getSapPriceBulk *** ' + soldToType);
                                if( soMap.get(pq.Sales_Org_Key__c).Pricing_Type__c == 'All' ){
                                       //Alt Site Accounts
                                       if(soldToType == 'ZA'){
                                           if(prodmap.get(ml).Alt_Site_List__c != 0.00){
                                               li.List_Price__c = prodmap.get(ml).Alt_Site_List__c;
                                               li.Sales_Price__c = prodmap.get(ml).Alt_Site_List__c;
                                               li.Eligible_Price__c = prodmap.get(ml).Alt_Site_List__c;
                                           }
                                           else{
                                               li.List_Price__c = prodmap.get(ml).Alt_Site_List__c;
                                               li.Sales_Price__c = 0.00;
                                               li.Eligible_Price__c = prodmap.get(ml).Alt_Site_List__c;
                                           }
                                       }
                                       
                                       //Distributor Accounts
                                       if(soldToType == 'ZD'){
                                           if(prodmap.get(ml).Distributor_List__c != 0.00){
                                               li.List_Price__c = prodmap.get(ml).Distributor_List__c;
                                               li.Sales_Price__c = prodmap.get(ml).Distributor_List__c;
                                               li.Eligible_Price__c = prodmap.get(ml).Distributor_List__c;
                                           }
                                           else{
                                               li.List_Price__c = prodmap.get(ml).Distributor_List__c;
                                               li.Sales_Price__c = 0.00;
                                               li.Eligible_Price__c = prodmap.get(ml).Distributor_List__c;
                                           }
                                       }
                                       
                                       //Hospital Accounts
                                       if(soldToType == 'ZH' || soldToType == '' || soldToType == NULL){
                                           if(prodmap.get(ml).List_Price__c != 0.00){
                                               li.List_Price__c = prodmap.get(ml).List_Price__c;
                                               li.Sales_Price__c = prodmap.get(ml).List_Price__c;
                                               li.Eligible_Price__c = prodmap.get(ml).List_Price__c;
                                           }
                                           else{
                                               li.List_Price__c = prodmap.get(ml).List_Price__c;
                                               li.Sales_Price__c = 0.00;
                                               li.Eligible_Price__c = prodmap.get(ml).List_Price__c;
                                           }
                                       }
                                       //end of logic to handle Hospital, Distributor, and Alt Site pricing
                                   }//end of if pq.Sales_Org_Key__c
                                else{
                                    //Start of US6020 ZD Pricing Only
                                    if( soMap.get(pq.Sales_Org_Key__c).Pricing_Type__c == 'Distributor List' ){
                                        li.List_Price__c = prodmap.get(ml).Distributor_List__c;
                                        li.Sales_Price__c = prodmap.get(ml).Distributor_List__c;
                                        li.Eligible_Price__c = prodmap.get(ml).Distributor_List__c;
                                    }
                                   
                                }//end of else pq.Sales_Org_Key__c
                                
                            }//end of else
                            
                            //add object to list
                            lineItemList.add(li);
                            system.debug('lineItemList ======================== ' + lineItemList);
                        }
                    }
                    else{
                        // Add Material to 'Miss' list
                    }
                }
                
                // DML - Insert Lines
                If(lineItemList.size() > 0){
                    system.debug('lineItemList ======================= ' + lineItemList);
                    database.insert(lineItemList,false);
                    
                    //conditions below helps with Price Quote and PRF Approval Matrix Routing
                    if(pq.BusinessUnit__c == 'Alternate Care'){
                        lineClassCheck(quoteId);
                    }
                    
                    if(pq.BusinessUnit__c == 'Anesthesia'){
                        lineProdCheckAnes(quoteId);
                    }
                    
                    if(pq.BusinessUnit__c == 'Interventional Capital' || pq.BusinessUnit__c == 'Cardiac'){
                        lineProdCheckIcap(quoteId);
                    }
                    
                    if(pq.BusinessUnit__c == 'Surgical Instruments'){
                        lineClassCheck(quoteId);
                    }
                }
            }
            
            
            
        }
        catch(Exception e){
            System.debug('=== e === ' + e);
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,''+'Error detected: ' + e));
        }
        
    }
    //End New SAP Price Logic
    */
    
    //Start New SAP Price Logic w/Cross Reference
    public void getCrossBulk(List<String> crossRef,String quoteId){
        
        //system.debug('userRoleBoolean getCrossBulk ======================= ' + userRoleBoolean);
        Map<String,String> crossMap = new  Map<String,String>();
        List<Cross_Reference__c> prodsCross = new List<Cross_Reference__c>();
        List<String> materialStr = new List<String>();
        List<Product2> mcheck = new List<Product2>();
        String soldToType; //Variable to hold Sold To Price List Type
        
        prodsCross = [SELECT Id, Name, Product__r.Name, Competitor_Product_Code__c, Competitor_Product_Description__c, Product__r.Floor_Price__c,
                      TFX_Product__c, Product__c,Competitor_Name__c, Percent_Match__c, Product__r.List_Price__c, Product__r.Director_Price__c,
                      Product__r.Rep_Price__c,Product__r.RSM_price__c,Product__r.Sales_Org__c, Product__r.Distribution_Channel__c, Product__r.Cost_Formula__c,
                      Product__r.Distributor_List__c, Product__r.Alt_Site_List__c
                      FROM Cross_Reference__c
                      WHERE Competitor_Product_Code__c IN :crossRef];
        
        for(Cross_Reference__c curr : prodsCross) {
            materialStr.add(curr.TFX_Product__c);
            crossMap.put(curr.Product__r.Name,curr.Id);
        }
        
        system.debug('Quote Id ====================== ' + quoteId);
        system.debug('materialStr =======================  ' + materialStr);
        system.debug('crossMap =======================  ' + crossMap);
        
        list<Price_Quote_Line_Item__c> lineItemList = new list<Price_Quote_Line_Item__c>();
        //list<Price_Quote_Line_Item__c> list2 = new list<Price_Quote_Line_Item__c>();
        list<Price_Quote_Line_Item__c> finalList = new list<Price_Quote_Line_Item__c>();
        
        try{
            Price_Quote__c pq = [SELECT Account_Name__r.SAP_Sold_To__c, Account_Name__r.Account_Group__c, Sales_Org_Key__c,
                                 Line_Count__c, Account_Name__r.Price_List_Type__c, CurrencyIsoCode, Type__c, BusinessUnit__c,
                                 Owner_Business_Unit__c
                                 FROM Price_Quote__c
                                 WHERE Id =: quoteId LIMIT 1];
            system.debug('pq ====================== ' + pq);
            Decimal rowOrder = pq.Line_Count__c;
            
            //adding logic for ASK Agreements
            if(pq.Type__c == 'ASK Agreement'){
                mcheck = [SELECT Id, Name, Sales_Org__c, Distribution_Channel__c, Cost_Formula__c, Floor_Price__c,
                      List_Price__c, RSM_Price__c, Rep_Price__c, Description, Product_Description_Custom__c,
                      Distributor_List__c, Alt_Site_List__c, Director_Price__c, MRP_Group__c, SearchableProducts__c
                      FROM Product2
                      WHERE Name IN :materialStr
                      AND Sales_Org_Key__c =: pq.Sales_Org_Key__c
                      AND Duplicate__c = FALSE AND ASK_Custom_Kit__c = TRUE];
            }
            else{
                mcheck = [SELECT Id, Name, Sales_Org__c, Distribution_Channel__c, Cost_Formula__c, Floor_Price__c,
                      List_Price__c, RSM_Price__c, Rep_Price__c, Description, Product_Description_Custom__c,
                      Distributor_List__c, Alt_Site_List__c, Director_Price__c, MRP_Group__c, SearchableProducts__c
                      FROM Product2
                      WHERE Name IN :materialStr
                      AND Sales_Org_Key__c =: pq.Sales_Org_Key__c
                      AND Duplicate__c = FALSE AND SearchableProducts__c = TRUE];
            }
            //end of ASK Agreement logic

            system.debug('mcheck ====================== ' + mcheck);
            for(Product2 curr :mcheck){
               system.debug('curr.Description ====================== ' + curr.Description);
               system.debug('curr.Product_Description_Custom__c ====================== ' + curr.Product_Description_Custom__c); 
            }
            
            // Create the Product Mapping
            map<String, Product2> prodmap = new map<String, Product2>();
            for(Product2 pmap : mcheck){
                prodmap.put(pmap.Name, pmap);
            }
            system.debug('prodmap: ' + prodmap);
            
            // Determine which SAP Number to use for Lookup
            string pcn = pq.Account_Name__r.SAP_Sold_To__c;
            if(pq.Account_Name__c!=null && pq.Account_Name__r.Account_Group__c == 'Z002'){
                for(Contract_Partnership__c cp : getContractPartnership(pq.Account_Name__r.SAP_Sold_To__c))
                {
                    pcn = cp.Sale_to__c;
                }
                
                //Query to get Price List Type of SAP Sold To Account
                soldToType = [SELECT Price_List_Type__c FROM Account WHERE SAP_Sold_To__c = :pcn LIMIT 1].Price_List_Type__c;
            }
            else{
                soldToType = pq.Account_Name__r.Price_List_Type__c;
            }
            
            system.debug('pcn (Primary Customer Number) ================ ' + pcn);
            // Start building the line items
            
            // Prospect Account Process (No SAP) #1
            if(pq.Account_Name__r.SAP_Sold_To__c == NULL){
                system.debug('Starting getPrice without SAP');
                
                for(String ml : materialStr){
                    system.debug('*** ml *** ' + ml);
                    system.debug('*** prodmap.get(ml) getCrossBulk No SAP *** ' + prodmap.get(ml));
                    if(prodmap.get(ml) != NULL){
                        ++rowOrder;
                        Price_Quote_Line_Item__c  pqLineItem = new Price_Quote_Line_Item__c (
                            Price_Quote__c = pq.Id,
                            Material_Name__c = prodmap.get(ml).Id,
                            Product_Description__c = prodmap.get(ml).Description,
                            Quantity__c = 1,
                            RSM_Price__c = prodmap.get(ml).RSM_Price__c,
                            Rep_Price__c = prodmap.get(ml).Rep_Price__c,
                            Director_Price__c = prodmap.get(ml).Director_Price__c,
                            Floor_Price__c = prodmap.get(ml).Floor_Price__c,
                            Cost__c = prodmap.get(ml).Cost_Formula__c,
                            Material_Status__c = '40',
                            Row_Order__c = rowOrder,
                            Competetive_Product__c = crossMap.get(ml),
                            MRP_Group__c = prodmap.get(ml).MRP_Group__c,
                            CurrencyIsoCode = pq.CurrencyIsoCode 
                        );
                        
                        // Check for custom product description. Was specifically for Surgical but now we have Cardiac as well.
                        system.debug('prodmap.get(ml).Product_Description_Custom__c ================ ' + prodmap.get(ml).Product_Description_Custom__c);
                        //system.debug('pcn (Primary Customer Number) ================ ' + pcn);
                        if(prodmap.get(ml).Product_Description_Custom__c != NULL){
                            pqLineItem.Product_Description__c = prodmap.get(ml).Product_Description_Custom__c;
                        }
                        else{
                            pqLineItem.Product_Description__c = prodmap.get(ml).Description;
                        }
                        
                        //logic to handle Hospital, Distributor, and Alt Site pricing
                        
                        if( soMap.get(pq.Sales_Org_Key__c).Pricing_Type__c == 'All' ){
                               //Alt Site Accounts
                               if(soldToType == 'ZA'){
                                   if(prodmap.get(ml).Alt_Site_List__c != 0.00){
                                       pqLineItem.List_Price__c = prodmap.get(ml).Alt_Site_List__c;
                                       pqLineItem.Sales_Price__c = prodmap.get(ml).Alt_Site_List__c;
                                       pqLineItem.Eligible_Price__c = prodmap.get(ml).Alt_Site_List__c;
                                   }
                                   else{
                                       pqLineItem.List_Price__c = prodmap.get(ml).Alt_Site_List__c;
                                       pqLineItem.Sales_Price__c = 0.00;
                                       pqLineItem.Eligible_Price__c = prodmap.get(ml).Alt_Site_List__c;
                                   }
                               }
                               
                               //Distributor Accounts
                               if(soldToType == 'ZD'){
                                   if(prodmap.get(ml).Distributor_List__c != 0.00){
                                       pqLineItem.List_Price__c = prodmap.get(ml).Distributor_List__c;
                                       pqLineItem.Sales_Price__c = prodmap.get(ml).Distributor_List__c;
                                       pqLineItem.Eligible_Price__c = prodmap.get(ml).Distributor_List__c;
                                   }
                                   else{
                                       pqLineItem.List_Price__c = prodmap.get(ml).Distributor_List__c;
                                       pqLineItem.Sales_Price__c = 0.00;
                                       pqLineItem.Eligible_Price__c = prodmap.get(ml).Distributor_List__c;
                                   }
                               }
                               
                               //Hospital Accounts
                               if(soldToType == 'ZH' || soldToType == '' || soldToType == NULL){
                                   if(prodmap.get(ml).List_Price__c != 0.00){
                                       pqLineItem.List_Price__c = prodmap.get(ml).List_Price__c;
                                       pqLineItem.Sales_Price__c = prodmap.get(ml).List_Price__c;
                                       pqLineItem.Eligible_Price__c = prodmap.get(ml).List_Price__c;
                                   }
                                   else{
                                       pqLineItem.List_Price__c = prodmap.get(ml).List_Price__c;
                                       pqLineItem.Sales_Price__c = 0.00;
                                       pqLineItem.Eligible_Price__c = prodmap.get(ml).List_Price__c;
                                   }
                               }
                               //end of logic to handle Hospital, Distributor, and Alt Site pricing
                           }//end of if pq.Sales_Org__c
                        else{
                            //Start of US6020 ZD Pricing Only
                            if( soMap.get(pq.Sales_Org_Key__c).Pricing_Type__c == 'Distributor List' ){
                                pqLineItem.List_Price__c = prodmap.get(ml).Distributor_List__c;
                                pqLineItem.Sales_Price__c = prodmap.get(ml).Distributor_List__c;
                                pqLineItem.Eligible_Price__c = prodmap.get(ml).Distributor_List__c;
                            }
                            
                        }//end of else pq.Sales_Org_Key__c
                        
                        
                        lineItemList.add(pqLineItem);
                        //list2.add(pqLineItem);
                    }
                    
                }//end of for loop
            }
            else{ // Customer Account Process #2
                system.debug('Starting getPrice with SAP');
                
                if (Test.isRunningTest()){
                    list<Sales_Condition_Mapping__c> condMapList = new list<Sales_Condition_Mapping__c>();
                    Sales_Condition_Mapping__c condMap1 = new Sales_Condition_Mapping__c(
                        Name = 'ND', Mapped_Value__c = 'XNAF'
                    );
                    condMapList.add(condMap1);
                    
                    Sales_Condition_Mapping__c condMap2 = new Sales_Condition_Mapping__c(
                        Name = 'PR', Mapped_Value__c = 'XPRI'
                    );
                    condMapList.add(condMap2);
                    
                    Sales_Condition_Mapping__c condMap3 = new Sales_Condition_Mapping__c(
                        Name = 'SE', Mapped_Value__c = 'XSEC'
                    );
                    condMapList.add(condMap3);
                    
                    insert condMapList;
                    
                    //Move this to Constructor to avoid repetitive SOQl Query
                    /*Map<String, String> cMap = new Map<String, String>();
                    for(Sales_Condition_Mapping__c scm : [SELECT Name, Mapped_Value__c FROM Sales_Condition_Mapping__c]){
                        cMap.put(scm.Name, scm.Mapped_Value__c);
                    }*/
                }//end of test running to create condition map
                
                //Move this to Constructor to avoid repetitive SOQl Query
                /*Map<String, String> cMap = new Map<String, String>();
                for(Sales_Condition_Mapping__c scm : [SELECT Name, Mapped_Value__c FROM Sales_Condition_Mapping__c]){
                    cMap.put(scm.Name, scm.Mapped_Value__c);
                }
                system.debug('cMap ============== ' + cMap);*/
                
                //Start getting SAP info
                for(String ml : materialStr)
                {
                    if(prodmap.get(ml) != NULL){
                        list<SAPRealPriceSet__x> sapList = new list<SAPRealPriceSet__x>();
                        if (Test.isRunningTest()) {
                            SAPRealPriceSet__x testSAP = new SAPRealPriceSet__x(
                                SalesDeal__c = '50000000',
                                Price__c = 0.00,
                                Material__c = 'AA-10511-1',
                                MtrlStatus__c = '40',
                                SalesMtrlStatus__c = '40',
                                ValidFrom__c = Date.Today(),
                                ValidTo__c = Date.Today() + 1000,
                                AgrDesc__c = 'Duke University SURGR',
                                Condition__c = 'XNAF',
                                OwnerName__c = 'Duke Univ Health System',
                                Owner__c = 'IDN-032',
                                AgrObjective__c = 'Direct',
                                Customer__c  = '000SAPcode101'
                            );
                            sapList.add(testSAP);
                        }//end if(!Test.isRunningTest())
                        else{
                            sapList = [SELECT SalesDeal__c, Price__c, Material__c, MtrlStatus__c,
                                       ValidFrom__c, ValidTo__c, Agreement__c, AgrDesc__c, Condition__c,
                                       OwnerName__c, Owner__c, AgrObjective__c, Customer__c, SalesMtrlStatus__c,
                                       DistChnl__c
                                       FROM SAPRealPriceSet__x
                                       WHERE SalesOrg__c =:prodmap.get(ml).Sales_Org__c
                                       AND DistChnl__c =:prodmap.get(ml).Distribution_Channel__c
                                       AND Customer__c =:pcn
                                       AND Material__c =:prodmap.get(ml).Name
                                       AND EffDate__c =:datetime.now()
                                      ];
                        }
                        
                        for(SAPRealPriceSet__x sap : sapList )
                        {
                            ++rowOrder;
                            system.debug('sap: ' + sap);
                            
                            string conremap = sap.Condition__c;
                            if(cMap.size()>0 && cMap.containsKey(sap.Condition__c) && cMap.get(sap.Condition__c) != NULL){
                                conremap = cMap.get(sap.Condition__c);
                            }
                            
                            string salesDeal;
                            if(sap.SalesDeal__c != NULL){
                                salesDeal = sap.SalesDeal__c.right(8);
                            }
                            
                            string mstatus;
                            if(sap.SalesMtrlStatus__c != NULL){
                                mstatus = sap.SalesMtrlStatus__c;
                            }
                            else if(sap.MtrlStatus__c != NULL){
                                mstatus = sap.MtrlStatus__c;
                            }
                            
                            Price_Quote_Line_Item__c  li = new Price_Quote_Line_Item__c (
                                Price_Quote__c = pq.Id,
                                Material_Name__c = prodmap.get(ml).Id,
                                Product_Description__c = prodmap.get(ml).Description,
                                Material_Status__c = mstatus,
                                Quantity__c = 1,
                                //List_Price__c = prodmap.get(ml).List_Price__c,
                                RSM_Price__c = prodmap.get(ml).RSM_Price__c,
                                Rep_Price__c = prodmap.get(ml).Rep_Price__c,
                                Director_Price__c = prodmap.get(ml).Director_Price__c,
                                Floor_Price__c = prodmap.get(ml).Floor_Price__c,
                                Cost__c = prodmap.get(ml).Cost_Formula__c,
                                Condition__c = conremap,
                                Sales_Deal_Description__c = sap.AgrDesc__c,
                                Sales_Number__c = salesDeal,
                                Row_Order__c = rowOrder,
                                Objective__c = sap.AgrObjective__c,
                                Competetive_Product__c = crossMap.get(ml),
                                MRP_Group__c = prodmap.get(ml).MRP_Group__c,
                                CurrencyIsoCode = pq.CurrencyIsoCode
                            );
                            
                            // Check for custom product description. Was specifically for Surgical but now we have Cardiac as well.
                            if(prodmap.get(ml).Product_Description_Custom__c != NULL){
                                li.Product_Description__c = prodmap.get(ml).Product_Description_Custom__c;
                            }
                            else{
                                li.Product_Description__c = prodmap.get(ml).Description;
                            }
                            
                            //check for eligible price = 0
                            if(sap.Price__c != 0.00){
                                li.Sales_Price__c = sap.Price__c;
                                li.Eligible_Price__c = sap.Price__c;
                            }
                            else{
                                //logic to handle Hospital, Distributor, and Alt Site pricing
                                
                                if( soMap.get(pq.Sales_Org_Key__c).Pricing_Type__c == 'All' ){
                                       //Alt Site Accounts
                                       if(soldToType == 'ZA'){
                                           if(prodmap.get(ml).Alt_Site_List__c != 0.00){
                                               li.List_Price__c = prodmap.get(ml).Alt_Site_List__c;
                                               li.Sales_Price__c = prodmap.get(ml).Alt_Site_List__c;
                                               li.Eligible_Price__c = prodmap.get(ml).Alt_Site_List__c;
                                           }
                                           else{
                                               li.List_Price__c = prodmap.get(ml).Alt_Site_List__c;
                                               li.Sales_Price__c = 0.00;
                                               li.Eligible_Price__c = prodmap.get(ml).Alt_Site_List__c;
                                           }
                                       }
                                       
                                       //Distributor Accounts
                                       if(soldToType == 'ZD'){
                                           if(prodmap.get(ml).Distributor_List__c != 0.00){
                                               li.List_Price__c = prodmap.get(ml).Distributor_List__c;
                                               li.Sales_Price__c = prodmap.get(ml).Distributor_List__c;
                                               li.Eligible_Price__c = prodmap.get(ml).Distributor_List__c;
                                           }
                                           else{
                                               li.List_Price__c = prodmap.get(ml).Distributor_List__c;
                                               li.Sales_Price__c = 0.00;
                                               li.Eligible_Price__c = prodmap.get(ml).Distributor_List__c;
                                           }
                                       }
                                       
                                       //Hospital Accounts
                                       if(soldToType == 'ZH' || soldToType == '' || soldToType == NULL){
                                           if(prodmap.get(ml).List_Price__c != 0.00){
                                               li.List_Price__c = prodmap.get(ml).List_Price__c;
                                               li.Sales_Price__c = prodmap.get(ml).List_Price__c;
                                               li.Eligible_Price__c = prodmap.get(ml).List_Price__c;
                                           }
                                           else{
                                               li.List_Price__c = prodmap.get(ml).List_Price__c;
                                               li.Sales_Price__c = 0.00;
                                               li.Eligible_Price__c = prodmap.get(ml).List_Price__c;
                                           }
                                       }
                                       //end of logic to handle Hospital, Distributor, and Alt Site pricing
                                   }//end of if pq.Sales_Org_Key__c
                                else{
                                    //Start of US6020 ZD Pricing Only
                                    if( soMap.get(pq.Sales_Org_Key__c).Pricing_Type__c == 'Distributor List' ){
                                        li.List_Price__c = prodmap.get(ml).Distributor_List__c;
                                        li.Sales_Price__c = prodmap.get(ml).Distributor_List__c;
                                        li.Eligible_Price__c = prodmap.get(ml).Distributor_List__c;
                                    }
                                    else{
                                        //All other Sales Orgs
                                        if(prodmap.get(ml).List_Price__c != 0.00){
                                            li.List_Price__c = prodmap.get(ml).List_Price__c;
                                            li.Sales_Price__c = prodmap.get(ml).List_Price__c;
                                            li.Eligible_Price__c = prodmap.get(ml).List_Price__c;
                                        }
                                        else{
                                            li.List_Price__c = prodmap.get(ml).List_Price__c;
                                            li.Sales_Price__c = 0.00;
                                            li.Eligible_Price__c = prodmap.get(ml).List_Price__c;
                                        }
                                    }//end else for pq.Sales_org_Key__c = US6020
                                }//end else to US103010,US610,CA1010 if
                                
                            }//end of outter else
                            
                            lineItemList.add(li);
                            //list2.add(li);
                            system.debug('lineItemList ======================== ' + lineItemList);
                        }//end of for loop
                    }
                    
                }
                
                // DML - Insert Lines
                If(lineItemList.size() > 0){
                    system.debug('lineItemList ======================= ' + lineItemList);
                    database.insert(lineItemList,false);
                    //conditions below helps with Price Quote and PRF Approval Matrix Routing
                    if(pq.BusinessUnit__c == 'Alternate Care'){
                        lineClassCheck(quoteId);
                    }
                    
                    if(pq.BusinessUnit__c == 'Anesthesia'){
                        lineProdCheckAnes(quoteId);
                    }
                    
                    if(pq.BusinessUnit__c == 'Interventional Capital' || pq.BusinessUnit__c == 'Cardiac'){
                        lineProdCheckIcap(quoteId);
                    }
                    
                    if(pq.Owner_Business_Unit__c == 'Surgical Instruments'){
                        lineClassCheck(quoteId);
                    }
                }
            }
            
        }
        catch(Exception e){
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,''+'Error detected: ' + e));
        }
        
    }//End New SAP Price Logic w/Cross Reference
    
        
    //End New SAP Price Logic
    /**********SIVA-Copy of new method LOGIC for EMEA materials-05-12-2023****************/
    public void getSAPpriceBulk(List<String> materialStr,String quoteId){
        List<Price_Quote_Line_Item__c> lineItemList = new List<Price_Quote_Line_Item__c>();
        List<String> newMaterialStr = new List<String>();
        List<String> notInList = new List<String>();
        Set<String> str1 = new Set<String>();
        Set<String> str2 = new Set<String>();
        List<Product2> mcheckList = new List<Product2>();
        Set<Id> mcheckSet = new Set<Id>();
        Boolean sapPriceNotAvailable = false;
        str1.addAll(materialStr); //added 1st string to set for comparison later
        
        try{
            Price_Quote__c pq = [SELECT Id, Name, Opportunity__r.Name, Opportunity__c, Price_Quote_Name__c, Status__c, Shipping__c, Product_Class_Count__c, Discounted_Total__c,
                                 Commit_Date__c, CreatedDate, LastModifiedDate, Grand_Total__c, Customer_comments__c, Tax__c, Current_Approver__c, Account_Name__r.Price_List_Type__c,
                                 Internal_Comments_Only__c, Account_Name__r.Name,Account_Name__c, Account_Name__r.Id, Account_Name__r.BillingStreet, Account_Name__r.BillingCity,
                                 Account_Name__r.BillingState, Account_Name__r.BillingPostalCode, Account_Name__r.BillingCountry, Account_Name__r.SAP_Sold_To__c, Account_Name__r.ERP_Active__c,
                                 Account_Name__r.Account_Group__c, Quote_Description__c, No_Opp__c, Expiration_Date__c, Owner_ID__c, Owner_Full_Name__c, Stationary__c, Discount_Type__c,
                                 Owner_Cell__c, Owner_Phone__c, Owner_Approval_Role__c, Workflow_Owner_Approval_Level__c, Courtesy_Pricing__c, Courtesy_Pricing_Type__c, Quote_Template__c, Discount__c,
                                 Owner_Email__c, Contact_Name__r.Name, Business_Unit__c, Contact_Name__r.id, Contact_Name__r.Phone, Contact_Name__r.Email, LastModifiedById, Material_Status_Check__c,
                                 CreatedById, InApproval__c, Territory__r.Territory_Name__c, Territory__r.Territory_Number__c,Approval_Flag_Rollup__c, CurrencyIsoCode, How_Created__c,
                                 Owner_Business_Unit__c, Sales_Org_Key__c,Line_Count__c,One_Time_Purchase__c,PRF__c, IsActive__c, Opportunity_Closed__c, Account_Name__r.Customer_Group__c,
                                 RsmRepToggle__c, BusinessUnit__c, OwnerId, Owner.Name, Type__c,Sold_To__c, Sold_To_Price_List_Type__c, Pricing_Tier_Level__c, EMEA_Approval_Level__c, EMEA_Approval_Flag_Rollup__c,
                                 Account_Name__r.Account_Name_2__c, Account_Name__r.Language__c,
                                 (SELECT Id, Name,Quantity__c, Price_Quote__r.BusinessUnit__c, Exception__c FROM Price_Quote_Line_Items__r)
                                 FROM Price_Quote__c
                                 WHERE Id =: quoteId LIMIT 1];
            system.debug('pq getSAPpriceBulk ====================== ' + pq);
            Decimal rowOrder = pq.Line_Count__c;
            
            //adding logic for ASK Agreements
            if(pq.Type__c == 'ASK Agreement'){
                mcheckList = [SELECT Id, Name, Sales_Org__c, Distribution_Channel__c,Brand_Name__c, Cost__c,
                              List_Price__c, RSM_Price__c, Rep_Price__c, Director_Price__c, Floor_Price__c,
                              Product_Description_Custom__c, Material_Status_Numeric__c, Description, Cost_Formula__c,
                              Distributor_List__c, Alt_Site_List__c, MRP_Group__c, SearchableProducts__c, Min_Order_Qty__c
                              FROM Product2
                              WHERE Name IN :materialStr
                              AND Sales_Org_Key__c =: pq.Sales_Org_Key__c
                              AND Duplicate__c = FALSE AND ASK_Custom_Kit__c = TRUE];
            }
            else{
                mcheckList = [SELECT Id, Name, Sales_Org__c, Distribution_Channel__c,Brand_Name__c, Cost__c,
                              List_Price__c, RSM_Price__c, Rep_Price__c, Director_Price__c, Floor_Price__c,
                              Product_Description_Custom__c, Material_Status_Numeric__c, Description, Cost_Formula__c,
                              Distributor_List__c, Alt_Site_List__c, MRP_Group__c, SearchableProducts__c, Min_Order_Qty__c
                              FROM Product2
                              WHERE Name IN :materialStr
                              AND Sales_Org_Key__c =: pq.Sales_Org_Key__c
                              AND Duplicate__c = FALSE AND SearchableProducts__c = TRUE];
            }
            //end of ASK Agreement logic
            
            //mcheck.remove(NULL);
            system.debug('mcheck.size() getSAPpriceBulk ====================== ' + mcheckList.size() );
            
            // Create the Product Mapping
            map<String, Product2> prodmap = new map<String, Product2>();
            for(Product2 pmap : mcheckList){
                mcheckSet.add(pmap.Id);
                prodmap.put(pmap.Name, pmap);
                newMaterialStr.add(pmap.Name);
            }
            //system.debug('prodmap getSAPpriceBulk: ' + prodmap);
            
            str2.addAll(newMaterialStr);
            
            for(String s : str1){
                if (!str2.contains(s)){System.debug('*** getSAPpriceBulk ERROR:  Does not contain the string ***');notInList.add(s);}
            }
            
            if(notInList.size() > 0){ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'The following product(s) where not added to the Price Quote: ' + notInList));}
            
            // Prospect Account Process (No SAP) #1
            if(pq.Account_Name__c != null && pq.Account_Name__r.SAP_Sold_To__c != NULL){
                String SAP_1stPick = '00000000';
                system.debug('*** Starting getPrice with SAP ***');
                List<string> cnlist = new List<String>();
                string pcn = '';
                String shipTo = '';
                
                cnlist.add(pq.Account_Name__r.SAP_Sold_To__c);
                pcn = pq.Account_Name__r.SAP_Sold_To__c;
                
                if(pq.Account_Name__r.Account_Group__c == 'Z002'){
                    for(Contract_Partnership__c cp : getContractPartnership(pq.Account_Name__r.SAP_Sold_To__c))
                    {
                        cnlist.add(cp.Sale_to__c);
                        pcn = cp.Sale_to__c;
                    }
                    shipTo = pcn; 
                    
                }
                else{
                    shipTo = pq.Account_Name__r?.SAP_Sold_To__c;
                }
                
                //Query to get Price List Type of SAP Sold To Account
                String soldToType = [SELECT Price_List_Type__c FROM Account WHERE SAP_Sold_To__c = :pcn LIMIT 1].Price_List_Type__c;
                system.debug('*** pcn (Primary Customer Number) ================ ' + pcn);
                system.debug('*** cnlist (Customer Number List) ================= ' + cnlist);
                system.debug('*** pcn b4 SAP============== ' + pcn);
                datetime datenew = datetime.now();
                
                list<String> ccaList = new list<String>();
                if(cnlist.size()>0){
                    for(Contract_Customer__c cc : [SELECT Agreement__r.Agreement_Number__c
                                                   FROM Contract_Customer__c
                                                   WHERE Account__r.SAP_Sold_To__c IN :cnlist
                                                   AND Active__c = TRUE])
                    {
                        ccaList.add(cc.Agreement__r.Agreement_Number__c);
                    }
                }
                System.debug('*** ccalist:' + ccaList);
                System.debug('*** ccalist 2:' + ccaList);
                // Material Map - Used to filter...
                map<String, String> matMap = new map<String, String>();
                map<Id, Contract_Material__c> prodCmMap = new map<Id, Contract_Material__c>();
                for(Contract_Material__c cm : [SELECT Product__r.Name, Agreement__r.Agreement_Number__c, Agreement__r.Description__c, Agreement__r.Sales_Org__c,
                                               RSM_Price__c, Rep_Price__c, Director_Price__c, List_Price__c, Price__c, Agreement__r.Objective_Name__c, Agreement_Number__c
                                               FROM Contract_Material__c
                                               WHERE Product__r.Id IN: mcheckSet
                                               AND Agreement_Number__c IN :ccaList
                                               AND Active__c = TRUE
                                               ORDER BY Price__c Desc])
                {
                    prodCmMap.put(cm.Product__r.Id, cm);
                    matMap.put(cm.Agreement__r.Agreement_Number__c, cm.Product__r.Name);
                }
                System.debug('*** prodCmMap.size: ' + prodCmMap.size());
                System.debug('*** prodCmMap *** ' + prodCmMap );
                
                for(String ml : materialStr)
                {
                    System.debug('*** IN for(String ml : materialStr) ***');
                    Product2 prod = prodmap.get(ml);
                    if(prod != NULL){
                        System.debug('*** IN if(prod != NULL) ***');
                        system.debug('*** prod.Sales_Org__c b4 SAP ============== ' + prod.Sales_Org__c);
                        system.debug('*** prod.Distribution_Channel__c b4 SAP============== ' + prod.Distribution_Channel__c);
                        system.debug('*** prod.Name b4 SAP============== ' + prod.Name);
                        List<SAPRealPriceSet__x> sapList = new List<SAPRealPriceSet__x>();
                        Contract_Material__c cmRec = prodCmMap.get(prod.Id);
                        if(Test.isRunningTest()) {
                            for(Integer i = 0; i < 3; i++){
                                Decimal testPrice = i == 2 ? 0.00 : 123.00;
                                SAPRealPriceSet__x testSAP = new SAPRealPriceSet__x(
                                    SalesDeal__c = '50009064',
                                    Price__c = testPrice,
                                    Material__c = '353535',
                                    MtrlStatus__c = '40',
                                    SalesMtrlStatus__c = '40',
                                    ValidFrom__c = Date.Today(),
                                    ValidTo__c = Date.Today() + 1000,
                                    AgrDesc__c = 'Duke University SURGR',
                                    Condition__c = 'XNAF',
                                    OwnerName__c = 'Duke Univ Health System',
                                    Owner__c = 'IDN-032',
                                    AgrObjective__c = '06',
                                    Customer__c  = '0000102059'
                                );
                                sapList.add(testSAP);
                            }
                        }//end if(!Test.isRunningTest())
                        else{  
                            try {
                                sapList = [SELECT SalesDeal__c, Price__c, Material__c, MtrlStatus__c,
                                           ValidFrom__c, ValidTo__c, Agreement__c, AgrDesc__c, Condition__c,
                                           OwnerName__c, Owner__c, AgrObjective__c, Customer__c, SalesMtrlStatus__c,
                                           DistChnl__c,MatDesc__c,vat__c,Currency__c,ShipTo__c
                                           FROM SAPRealPriceSet__x
                                           WHERE SalesOrg__c = :prod.Sales_Org__c
                                           AND DistChnl__c = :prod.Distribution_Channel__c
                                           AND Customer__c = :pcn
                                           AND Material__c = :prod.Name
                                           AND ShipTo__c = :shipTo
                                           AND EffDate__c = :datetime.now()
                                          ];
                            }
                            catch(Exception ex){
                                sapList = null;
                            }
                        }
                        //************************************* Start Rebate Only Check *******************************************
                        //System.debug('*** userRole crossBulk *** ' + userRole);
                        
                        if(sapList!=null && sapList.size()>0){
                            System.debug('*** sapList[0].AgrObjective__c *** ' + sapList[0].AgrObjective__c);
                            System.debug('*** sapList[0].SalesDeal__c *** ' + sapList[0].SalesDeal__c);
                            String compDeal = sapList[0].SalesDeal__c;
                            
                            if(sapList[0].AgrObjective__c == '06' && userRoleBoolean ){
                                System.debug('*** IN REBATE ONLY CHECK ***');
                                //SAP_1stPick = sapList[0].Agreement_Number__c.right(8);
                                
                                sapList.remove(0);
                                List<Contract_Customer__c> cc = getContractCustomer(new list<String> { cmRec.Agreement_Number__c }, cnlist);
                                if(cc != null && cc.size() > 0){
                                    sapList = [SELECT SalesDeal__c, Price__c, Material__c, MtrlStatus__c, ValidFrom__c,
                                               ValidTo__c, Agreement__c, AgrDesc__c, Condition__c,
                                               OwnerName__c, Owner__c, AgrObjective__c, Customer__c, SalesMtrlStatus__c,
                                               DistChnl__c,MatDesc__c,vat__c,Currency__c,ShipTo__c
                                               FROM SAPRealPriceSet__x
                                               WHERE SalesOrg__c = :prod.Sales_Org__c
                                               AND DistChnl__c = :prod.Distribution_Channel__c
                                               AND Agreement__c = :cc[0].Agreement__r.Agreement_Number__c
                                               AND Customer__c = :cc[0].Account__r.SAP_Sold_To__c
                                               AND Material__c = :matMap.get(cc[0].Agreement__r.Agreement_Number__c)
                                               AND ShipTo__c = :shipTo
                                               AND EffDate__c = :datetime.now()
                                               LIMIT 1 ];
                                    System.debug('*** sapList *** ' + sapList );
                                }
                                //**************************** End Contract Customer Lookup ************************************
                            }
                            //************************************* Start Rebate Only Check *******************************************
                            
                            
                            for(SAPRealPriceSet__x sap : sapList)
                            {
                                //SAPRealPriceSet__x sap = newSAP;
                                
                                system.debug('*** in SAP for loop ================== ');
                                system.debug('*** sap ================== ' + sap);
                                //system.debug('*** sap.Price__c ================== ' + sap.Price__c);
                                string objname;
                                string mstatus;
                                ++rowOrder;
                                
                                string conremap = sap.Condition__c;
                                if(cMap.size()>0 && cMap.containsKey(sap.Condition__c) && cMap.get(sap.Condition__c) != NULL){
                                    conremap = cMap.get(sap.Condition__c);
                                }
                                
                                if(sap.SalesDeal__c != NULL){
                                    if(sap.AgrObjective__c !=NULL && sap.AgrObjective__c == '06' && userRoleBoolean ){
                                        SAP_1stPick = 'No Contract';
                                    }
                                    else{
                                        SAP_1stPick = sap.SalesDeal__c.right(8);
                                    }    
                                }
                                else{
                                    SAP_1stPick = 'No Contract';
                                }
                                system.debug('*** SAP_1stPick ================ ' + SAP_1stPick);
                                
                                String cnum2;
                                // Strip the leading zero's - 06Jul2016 ESC
                                if(sap.Customer__c != NULL){
                                    cnum2 = sap.Customer__c.replaceAll('^0+', '');
                                }
                                // Checks to see if the Sales Material Status Exists and if it does we use that, otherwise we default
                                // to the standard Material Status. - 06Jul2016 ESC
                                if(sap.SalesMtrlStatus__c != NULL){
                                    mstatus = sap.SalesMtrlStatus__c;
                                }
                                else if(sap.MtrlStatus__c != NULL){
                                    mstatus = sap.MtrlStatus__c;
                                }
                                
                                Price_Quote_Line_Item__c prodQuoteLineItem1 = new Price_Quote_Line_Item__c(
                                    Price_Quote__c = pq.Id,
                                    Material_Name__c = prod.Id,
                                    Material_Status__c = mstatus,
                                    RSM_Price__c = prod.RSM_Price__c,
                                    Rep_Price__c = prod.Rep_Price__c,
                                    Director_Price__c = prod.Director_Price__c,
                                    Floor_Price__c = prod.Floor_Price__c,
                                    Cost__c = prod.Cost_Formula__c,
                                    Objective__c = sap.AgrObjective__c,
                                    MRP_Group__c = prod.MRP_Group__c,
                                    Min_Order_Qty__c = ((pq.BusinessUnit__c == 'EMEA' || userRoleName.containsIgnoreCase('EMEA')) && prod.Min_Order_Qty__c != NULL && prod.Min_Order_Qty__c != 0) ? prod.Min_Order_Qty__c : 1,
                                    Quantity__c = ((pq.BusinessUnit__c == 'EMEA' || userRoleName.containsIgnoreCase('EMEA')) && prod.Min_Order_Qty__c != NULL && prod.Min_Order_Qty__c != 0) ? prod.Min_Order_Qty__c : 1,
                                    Material_Description__c = (pq.Businessunit__c == 'EMEA') ? sap.MatDesc__c : NULL,
                                    CurrencyIsoCode = (pq.Businessunit__c == 'EMEA') ? sap.Currency__c : pq.CurrencyIsoCode,
                                    VAT__c = (pq.Businessunit__c == 'EMEA' && sap.VAT__c == NULL) ? NULL : ((sap.VAT__c == NULL)? NULL : Decimal.Valueof(sap.Vat__c))
                                );
                                
                                //check for surgical custom product description
                                prodQuoteLineItem1.Product_Description__c = (prod.Product_Description_Custom__c != NULL) ? prod.Product_Description_Custom__c : prod.Description;
                                
                                prodQuoteLineItem1.Row_Order__c = pq.Line_Count__c;
                                
                                //check for eligible price = 0
                                if(sap.Price__c != NULL && sap.Price__c != 0.00){
                                    System.debug('*** sap.Price__c != 0.00 *** ');
                                    prodQuoteLineItem1.Sales_Price__c = sap.Price__c;
                                    system.debug('******TROUBLESHOOT******' +  sap.Price__c);
                                    prodQuoteLineItem1.Eligible_Price__c = sap.Price__c;
                                    
                                    //logic to handle Hospital, Distributor, and Alt Site pricing
                                    
                                    //start of check for Customer Service Rebate Only
                                    if(sapList[0].AgrObjective__c!=NULL && sapList[0].AgrObjective__c == '06' && userRoleBoolean ){
                                        populatePriceProductToPQLIBySoldToType(pq, prod, prodQuoteLineItem1, soldToType);
                                    }
                                    //end of check for Customer Service Rebate Only
                                    System.debug('*** soMap.get(pq.Sales_Org_Key__c) *** ' + soMap.get(pq.Sales_Org_Key__c));
                                    System.debug('*** soMap.get(pq.Sales_Org_Key__c)..Pricing_Type__c *** ' + soMap.get(pq.Sales_Org_Key__c).Pricing_Type__c );
                                    if( soMap.get(pq.Sales_Org_Key__c).Pricing_Type__c == 'All' ){ 
                                        //add Canada
                                        System.debug('*** In if pq.Sales_Org_Key__c == US103010 OR CA1010 *** ');
                                        System.debug('*** soldToType *** ' + soldToType);
                                        //Alt Site Accounts
                                        if(soldToType == 'ZA'){
                                            System.debug('*** In Alt Site List Pricing for if sap.Price__c != 0.00 ***');
                                            prodQuoteLineItem1.List_Price__c = prod.Alt_Site_List__c;
                                        }
                                        
                                        //Distributor Accounts
                                        if(soldToType == 'ZD'){
                                            System.debug('*** In Distributor List Pricing for if sap.Price__c != 0.00 ***');
                                            prodQuoteLineItem1.List_Price__c = prod.Distributor_List__c;
                                        }
                                        
                                        //Hospital Accounts
                                        if(soldToType == 'ZH' || soldToType == '' || soldToType == NULL){
                                            System.debug('*** In Hospital List Pricing for if sap.Price__c != 0.00 ***');
                                            prodQuoteLineItem1.List_Price__c = prod.List_Price__c;
                                        }
                                        //end of logic to handle Hospital, Distributor, and Alt Site pricing
                                    }//end of if pq.Sales_Org_Key__c
                                    else{
                                        System.debug('*** In Hospital List Pricing for non US/CA Accounts after if sap.Price__c != 0.00 ***');
                                        if( soMap.get(pq.Sales_Org_Key__c).Pricing_Type__c == 'Distributor List' ){
                                            prodQuoteLineItem1.List_Price__c = prod.Distributor_List__c;
                                        }
                                        else{
                                            prodQuoteLineItem1.List_Price__c = prod.List_Price__c;
                                        }
                                    }//end of else of pq.Sales_Org_Key__c
                                    
                                }//end of if sap.price__c != 0.00
                                else{
                                    System.debug('*** Else after If sap.price__c != 0.00 ***');
                                    //logic to handle Hospital, Distributor, and Alt Site pricing
                                    System.debug('*** if(!refresh) *** ');
                                    if( soMap.get(pq.Sales_Org_Key__c).Pricing_Type__c == 'All' ){
                                        System.debug('*** IN All LOGIC Pricing_Type__c !refresh ***');
                                        populatePriceProductToPQLIBySoldToType(pq, prod, prodQuoteLineItem1, soldToType);
                                        //end of logic to handle Hospital, Distributor, and Alt Site pricing
                                    }//end of if pq.Sales_Org_Key__c
                                    else{
                                        populatePriceProductToPQLI(pq, prod, prodQuoteLineItem1);
                                    }//end of else pq.Sales_Org_Key__c
                                }
                                
                                //check for SAP Agreement null or blank value
                                
                                prodQuoteLineItem1.Sales_Number__c = SAP_1stPick;
                                IF(SAP_1stPick != null){
                                    System.debug('*** SAP_1stPick != null sapList[0].AgrObjective__c *** ' + sapList[0].AgrObjective__c);
                                    //customer service rebate only check
                                    if(sapList[0].AgrObjective__c!=NULL && sapList[0].AgrObjective__c == '06' && userRoleBoolean ){
                                        System.debug('*** Customer Service Rebate Only Sales Deal Description ***');
                                        prodQuoteLineItem1.Sales_deal_Description__c = NULL;
                                    }
                                    else{
                                        prodQuoteLineItem1.Sales_deal_Description__c = sap.AgrDesc__c;
                                    }
                                    
                                }
                                else{
                                    prodQuoteLineItem1.Sales_deal_Description__c = 'No Contract';
                                }
                                
                                system.debug('*** prodQuoteLineItem1.Sales_Number__c: ' + prodQuoteLineItem1.Sales_Number__c);
                                system.debug('*** prodQuoteLineItem1.Sales_deal_Description__c: ' + prodQuoteLineItem1.Sales_deal_Description__c);
                                
                                prodQuoteLineItem1.Condition__c = conremap;
                                
                                lineItemList.add(prodQuoteLineItem1);
                                system.debug('*** prodQuoteLineItem1 ======================== ' + prodQuoteLineItem1);
                            }
                        } // End of SAP for(SAPRealPriceSet__x sap : sapList)
                        else if(cmRec != null) {
                            sapPriceNotAvailable = true;
                            subGetPriceFromContactMaterial(pq, prod, cmRec, null, null, null, rowOrder, lineItemList);
                        }
                        else {
                            sapPriceNotAvailable = true;
                            subGetPriceFromProduct(pq, prod, null, null, rowOrder, lineItemList);
                        }
                        if(sapPriceNotAvailable){
                            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Cannot retrieve SAP Price for some of the products, using Contract Material/SF Product Price instead!'));
                        }
                    }
                }
            }
            else {
                for(String ml : materialStr)
                {
                    System.debug('*** IN for(String ml : materialStr) ***');
                    Product2 prod = prodmap.get(ml);
                    if(prod != NULL){
                        subGetPriceFromProduct(pq, prod, null, null, rowOrder, lineItemList);
                    }
                }
            }
            
            If(lineItemList.size() > 0){
                subAddProcessedLiToPriceQuote(pq, lineItemList, null);
            }
        }
        //system.debug
        catch(Exception e){
            System.debug('=== e === ' + e);
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,''+'Error detected: ' + e));
        }
    }
    
    //This overlaoded method is to support other classes calling the old signature of getSapPrice
	global void getSAPprice(List<String> materialStr,String crossStr,String lineItemId, Id pqId){
        Price_Quote__c pq = [SELECT Id, Name, Opportunity__r.Name, Opportunity__c, Price_Quote_Name__c, Status__c, Shipping__c, Product_Class_Count__c, Discounted_Total__c,
                              Commit_Date__c, CreatedDate, LastModifiedDate, Grand_Total__c, Customer_comments__c, Tax__c, Current_Approver__c, Account_Name__r.Price_List_Type__c,
                              Internal_Comments_Only__c, Account_Name__r.Name,Account_Name__c, Account_Name__r.Id, Account_Name__r.BillingStreet, Account_Name__r.BillingCity,
                              Account_Name__r.BillingState, Account_Name__r.BillingPostalCode, Account_Name__r.BillingCountry, Account_Name__r.SAP_Sold_To__c, Account_Name__r.ERP_Active__c,
                              Account_Name__r.Account_Group__c, Quote_Description__c, No_Opp__c, Expiration_Date__c, Owner_ID__c, Owner_Full_Name__c, Stationary__c, Discount_Type__c,
                              Owner_Cell__c, Owner_Phone__c, Owner_Approval_Role__c, Workflow_Owner_Approval_Level__c, Courtesy_Pricing__c, Courtesy_Pricing_Type__c, Quote_Template__c, Discount__c,
                              Owner_Email__c, Contact_Name__r.Name, Business_Unit__c, Contact_Name__r.id, Contact_Name__r.Phone, Contact_Name__r.Email, LastModifiedById, Material_Status_Check__c,
                              CreatedById, InApproval__c, Territory__r.Territory_Name__c, Territory__r.Territory_Number__c,Approval_Flag_Rollup__c, CurrencyIsoCode, How_Created__c,
                              Owner_Business_Unit__c, Sales_Org_Key__c,Line_Count__c,One_Time_Purchase__c,PRF__c, IsActive__c, Opportunity_Closed__c, Account_Name__r.Customer_Group__c,
                              RsmRepToggle__c, BusinessUnit__c, OwnerId, Owner.Name, Type__c,Sold_To__c, Sold_To_Price_List_Type__c, Pricing_Tier_Level__c, EMEA_Approval_Level__c, EMEA_Approval_Flag_Rollup__c,
                              Account_Name__r.Account_Name_2__c, Account_Name__r.Language__c,
                              (SELECT Id, Name,Quantity__c, Price_Quote__r.BusinessUnit__c, Exception__c FROM Price_Quote_Line_Items__r)
                              FROM Price_Quote__c
                              WHERE Id=:pqId limit 1];
        
        List<Product2> mchecks = [SELECT Id, Name, Sales_Org__c, Distribution_Channel__c,Brand_Name__c, Cost__c,
                              List_Price__c, RSM_Price__c, Rep_Price__c, Director_Price__c, Floor_Price__c,
                              Product_Description_Custom__c, Material_Status_Numeric__c, Description, Cost_Formula__c,
                              Distributor_List__c, Alt_Site_List__c, MRP_Group__c, SearchableProducts__c, Min_Order_Qty__c
                              FROM Product2
                              WHERE Name IN :materialStr AND Sales_Org_Key__c =: pq.Sales_Org_Key__c
                              AND Duplicate__c = FALSE
                              LIMIT 1];
        String cpSoldToAcct;
        if(pq.Account_Name__r.Account_Group__c == 'Z002' && pq.Account_Name__c != null && pq.Account_Name__r.SAP_Sold_To__c != null){
        cpSoldToAcct = [SELECT Sale_to__c, Ship_to__c
                              FROM Contract_Partnership__c
                              WHERE Ship_to__c =:pq.Account_Name__r.SAP_Sold_To__c
                              AND Disabled__c = FALSE][0].Sale_to__c;
        }
        else {
            cpSoldToAcct = null;
        }
        
        String soldToAcctType = [SELECT Price_List_Type__c
                                 FROM Account
                                 WHERE SAP_Sold_To__c =:cpSoldToAcct][0].Price_List_Type__c;
        
        if(mchecks!=null && mchecks.size()>0){
            if(pq.Sales_Org_Key__c == NULL){
                pq.Sales_Org_Key__c = 'US6010';
            }
            
            iF(pq.InApproval__c){
                Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,''+'Cannot add Material to an Approved Quote, please create a new quote and then try again or click Revise/Clone and try again.'));
            }
            else{
            	getSAPprice(mchecks[0],crossStr,lineItemId, pq, cpSoldToAcct, soldToAcctType);
            }
        }
        
    }
    
	//Gets the price from SAP, if execption or SAP Sold to is Null, gets price from SF Product
    global void getSAPprice(Product2 mcheck,String crossStr,String lineItemId, Price_Quote__c pq, String cpSoldToAcct, String plt){
        // Initiatal Values
        system.debug('*** getSAPprice quoteId ======================= ' + pq.Id);
        Decimal rowOrder = pq.Line_Count__c; //remove parameter... available on pq record
        
        //add logic to turn off Sap Price callout to use SF Contract Pricing (subGetPriceFromContactMaterial)
        try{
            List<Price_Quote_Line_Item__c> qLineItem = new List<Price_Quote_Line_Item__c>();
            //end of ASK Agreement logic
            system.debug('*** mcheck ====================== getSAPprice 1' + mcheck);
            
            subGetPriceFromSAP(pq, mcheck, new List<String> {mcheck.Name}, crossStr,lineItemId, rowOrder, cpSoldToAcct, plt, qLineItem);
            
            If(qLineItem.size() > 0){
                subAddProcessedLiToPriceQuote(pq, qLineItem, lineItemId);
            }
            
        }//end of outtermost try after IF(pq.InApproval__c)
        catch(Exception e){
            System.debug('*** e getSapPrice *** ' + e);
            //Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,''+'Error detected: ' + e));
        }
        
    }//End New SAP Price Logic
    
    private void subGetPriceFromSAP(Price_Quote__c pq, Product2 mcheck, List<String> materialStr, String crossStr, String lineItemId, Decimal rowOrder, String cpSoldToAcct, String plt, List<Price_Quote_Line_Item__c> qLineItem){
        String SAP_1stPick = '00000000';
        boolean refresh = FALSE;
        if(!String.isBlank(crossStr) && crossStr == 'refresh'){
            refresh = TRUE;
        }
        system.debug('*** Starting getPrice with SAP ***');
        List<string> cnlist = new List<String>();
        string pcn = '';
        String shipTo = '';
        
        //Account has SAP Code
        if(pq.Account_Name__c != null && pq.Account_Name__r.SAP_Sold_To__c != NULL){
            cnlist.add(pq.Account_Name__r.SAP_Sold_To__c);
            pcn = pq.Account_Name__r.SAP_Sold_To__c;
            
            cnlist.add(cpSoldToAcct);
            pcn = cpSoldToAcct;
            if(cpSoldToAcct != null){
            	shipTo = pcn; 
            }
            else{
                shipTo = pq.Account_Name__r?.SAP_Sold_To__c;
            }
            
            //Query to get Price List Type of SAP Sold To Account
            String soldToType = plt;
            system.debug('*** pcn (Primary Customer Number) ================ ' + pcn);
            system.debug('*** cnlist (Customer Number List) ================= ' + cnlist);
            system.debug('*** mcheck.Sales_Org__c b4 SAP ============== ' + mcheck.Sales_Org__c);
            system.debug('*** mcheck.Distribution_Channel__c b4 SAP============== ' + mcheck.Distribution_Channel__c);
            //system.debug('*** pcn b4 SAP============== ' + pcn);
            system.debug('*** mcheck.Name b4 SAP============== ' + mcheck.Name);
            datetime datenew = datetime.now();
            
            List<SAPRealPriceSet__x> sapList = new List<SAPRealPriceSet__x>();//List or object???
            if(Test.isRunningTest()) {
                for(Integer i = 0; i < 3; i++){
                    Decimal testPrice = i == 2 ? 0.00 : 123.00;
                    SAPRealPriceSet__x testSAP = new SAPRealPriceSet__x(
                        SalesDeal__c = '50009064',
                        Price__c = testPrice,
                        Material__c = '353535',
                        MtrlStatus__c = '40',
                        SalesMtrlStatus__c = '40',
                        ValidFrom__c = Date.Today(),
                        ValidTo__c = Date.Today() + 1000,
                        AgrDesc__c = 'Duke University SURGR',
                        Condition__c = 'XNAF',
                        OwnerName__c = 'Duke Univ Health System',
                        Owner__c = 'IDN-032',
                        AgrObjective__c = '06',
                        Customer__c  = '0000102059'
                    );
                    sapList.add(testSAP);
                }
            }//end if(!Test.isRunningTest())
            else{  
                try {
                    sapList = [SELECT SalesDeal__c, Price__c, Material__c, MtrlStatus__c,
                               ValidFrom__c, ValidTo__c, Agreement__c, AgrDesc__c, Condition__c,
                               OwnerName__c, Owner__c, AgrObjective__c, Customer__c, SalesMtrlStatus__c,
                               DistChnl__c,MatDesc__c,vat__c,Currency__c,ShipTo__c
                               FROM SAPRealPriceSet__x
                               WHERE SalesOrg__c = :mcheck.Sales_Org__c
                               AND DistChnl__c = :mcheck.Distribution_Channel__c
                               AND Customer__c = :pcn
                               AND Material__c = :mcheck.Name
                               AND ShipTo__c = :shipTo
                               AND EffDate__c = :datetime.now()
                              ];
                }
                catch(Exception ex){
                    sapList = null;
                }
            }
            //************************************* Start Rebate Only Check *******************************************
            //System.debug('*** userRole crossBulk *** ' + userRole);
            
            if(sapList!=null && sapList.size()>0){//Sap returned data
                System.debug('*** sapList[0].AgrObjective__c *** ' + sapList[0].AgrObjective__c);
                System.debug('*** sapList[0].SalesDeal__c *** ' + sapList[0].SalesDeal__c);
                String compDeal = sapList[0].SalesDeal__c;
            
                if(sapList[0].AgrObjective__c == '06' && userRoleBoolean ){//customer service logic
                    System.debug('*** IN REBATE ONLY CHECK ***');
                    //SAP_1stPick = sapList[0].Agreement_Number__c.right(8);
                    
                    sapList.remove(0);
                    list<String> ccaList = new list<String>();
                    if(cnlist.size()>0){
                        for(Contract_Customer__c cc : [SELECT Agreement__r.Agreement_Number__c
                                                       FROM Contract_Customer__c
                                                       WHERE Account__r.SAP_Sold_To__c IN :cnlist
                                                       AND Active__c = TRUE])
                        {
                            ccaList.add(cc.Agreement__r.Agreement_Number__c);
                        }
                    }
                    System.debug('*** ccalist:' + ccaList);
                    System.debug('*** ccalist 2:' + ccaList);
                    // Contract Material List - Used to filter the Contract Customers
                    list<String> cmList = new list<String>();
                    // Material Map - Used to filter...
                    map<String, String> matMap = new map<String, String>();
                    for(Contract_Material__c cm : [SELECT Product__r.Name, Agreement__r.Agreement_Number__c, Agreement__r.Description__c, Agreement__r.Sales_Org__c,
                                                   RSM_Price__c, Rep_Price__c, Director_Price__c, List_Price__c, Price__c, Agreement__r.Objective_Name__c
                                                   FROM Contract_Material__c
                                                   WHERE Product__r.Id =: mcheck.Id
                                                   AND Agreement_Number__c IN :ccaList
                                                   AND Active__c = TRUE
                                                   ORDER BY Price__c
                                                   LIMIT 1])
                    {
                        cmList.add(cm.Agreement__r.Agreement_Number__c);
                        matMap.put(cm.Agreement__r.Agreement_Number__c, cm.Product__r.Name);
                    }
                    System.debug('*** cmList.size: ' + cmList.size());
                    System.debug('*** cmList *** ' + cmList );
                    List<Contract_Customer__c> cc = getContractCustomer(cmList, cnlist);
                    if(cc !=null && cc.Size() > 0){
                        sapList = [SELECT SalesDeal__c, Price__c, Material__c, MtrlStatus__c, ValidFrom__c,
                                   ValidTo__c, Agreement__c, AgrDesc__c, Condition__c,
                                   OwnerName__c, Owner__c, AgrObjective__c, Customer__c, SalesMtrlStatus__c,
                                   DistChnl__c,MatDesc__c,vat__c,Currency__c,ShipTo__c
                                   FROM SAPRealPriceSet__x
                                   WHERE SalesOrg__c = :mcheck.Sales_Org__c
                                   AND DistChnl__c = :mcheck.Distribution_Channel__c
                                   AND Agreement__c = :cc[0].Agreement__r.Agreement_Number__c
                                   AND Customer__c = :cc[0].Account__r.SAP_Sold_To__c
                                   AND Material__c = :matMap.get(cc[0].Agreement__r.Agreement_Number__c)
                                   AND ShipTo__c = :shipTo
                                   AND EffDate__c = :datetime.now()
                                   LIMIT 1 ];
                        System.debug('*** sapList *** ' + sapList );
                    }
                    //**************************** End Contract Customer Lookup ************************************
                }
                //************************************* Start Rebate Only Check *******************************************
                
                
                for(SAPRealPriceSet__x sap : sapList)
                {
                    //SAPRealPriceSet__x sap = newSAP;
                    
                    system.debug('*** in SAP for loop ================== ');
                    system.debug('*** sap ================== ' + sap);
                    //system.debug('*** sap.Price__c ================== ' + sap.Price__c);
                    string objname;
                    string mstatus;
                    ++rowOrder;
                    
                    string conremap = sap.Condition__c;
                    if(cMap.size()>0 && cMap.containsKey(sap.Condition__c) && cMap.get(sap.Condition__c) != NULL){
                        conremap = cMap.get(sap.Condition__c);
                    }
                    
                    if(sap.SalesDeal__c != NULL){
                        if(sap.AgrObjective__c !=NULL && sap.AgrObjective__c == '06' && userRoleBoolean ){
                            SAP_1stPick = 'No Contract';
                        }
                        else{
                            SAP_1stPick = sap.SalesDeal__c.right(8);
                        }    
                    }
                    else{
                        SAP_1stPick = 'No Contract';
                    }
                    system.debug('*** SAP_1stPick ================ ' + SAP_1stPick);
                    
                    String cnum2;
                    // Strip the leading zero's - 06Jul2016 ESC
                    if(sap.Customer__c != NULL){
                        cnum2 = sap.Customer__c.replaceAll('^0+', '');
                    }
                    // Checks to see if the Sales Material Status Exists and if it does we use that, otherwise we default
                    // to the standard Material Status. - 06Jul2016 ESC
                    if(sap.SalesMtrlStatus__c != NULL){
                        mstatus = sap.SalesMtrlStatus__c;
                    }
                    else if(sap.MtrlStatus__c != NULL){
                        mstatus = sap.MtrlStatus__c;
                    }
                    
                    Price_Quote_Line_Item__c prodQuoteLineItem1 = new Price_Quote_Line_Item__c(
                        Price_Quote__c = pq.Id,
                        Material_Name__c = mcheck.Id,
                        Material_Status__c = mstatus,
                        RSM_Price__c = mcheck.RSM_Price__c,
                        Rep_Price__c = mcheck.Rep_Price__c,
                        Director_Price__c = mcheck.Director_Price__c,
                        Floor_Price__c = mcheck.Floor_Price__c,
                        Cost__c = mcheck.Cost_Formula__c,
                        Objective__c = sap.AgrObjective__c,
                        MRP_Group__c = mcheck.MRP_Group__c,
                        Min_Order_Qty__c = ((pq.BusinessUnit__c == 'EMEA' || userRoleName.containsIgnoreCase('EMEA')) && mcheck.Min_Order_Qty__c != NULL && mcheck.Min_Order_Qty__c != 0) ? mcheck.Min_Order_Qty__c : 1,
                        Quantity__c = ((pq.BusinessUnit__c == 'EMEA' || userRoleName.containsIgnoreCase('EMEA')) && mcheck.Min_Order_Qty__c != NULL && mcheck.Min_Order_Qty__c != 0) ? mcheck.Min_Order_Qty__c : 1,
                        Material_Description__c = (pq.Businessunit__c == 'EMEA') ? sap.MatDesc__c : NULL,
                        CurrencyIsoCode = (pq.Businessunit__c == 'EMEA') ? sap.Currency__c : pq.CurrencyIsoCode,
                        VAT__c = (pq.Businessunit__c == 'EMEA' && sap.VAT__c == NULL) ? NULL : ((sap.VAT__c == NULL)? NULL : Decimal.Valueof(sap.Vat__c))
                    );
                    
                    if(lineItemId == NULL){
                        //check for surgical custom product description
                        prodQuoteLineItem1.Product_Description__c = (mcheck.Product_Description_Custom__c != NULL) ? mcheck.Product_Description_Custom__c : mcheck.Description;
                        
                        prodQuoteLineItem1.Row_Order__c = pq.Line_Count__c;
                    }
                    else{
                        prodQuoteLineItem1.Id = lineItemId;
                        prodQuoteLineItem1.Hide_Crossreference__c = false;
                    }
                    
                    //check for eligible price = 0
                    if(sap.Price__c != NULL && sap.Price__c != 0.00){
                        System.debug('*** sap.Price__c != 0.00 *** ');
                        if(!refresh){
                            System.debug('*** if(!refresh) sap.Price__c != 0.00 *** ');
                            prodQuoteLineItem1.Sales_Price__c = sap.Price__c;
                            system.debug('******TROUBLESHOOT******' +  sap.Price__c);
                        }
                        prodQuoteLineItem1.Eligible_Price__c = sap.Price__c;
                        
                        //logic to handle Hospital, Distributor, and Alt Site pricing
                        
                        //start of check for Customer Service Rebate Only
                        if(sapList[0].AgrObjective__c!=NULL && sapList[0].AgrObjective__c == '06' && userRoleBoolean ){
                            populatePriceProductToPQLIBySoldToType(pq, mcheck, prodQuoteLineItem1, soldToType);
                        }
                        //end of check for Customer Service Rebate Only
                        System.debug('*** soMap.get(pq.Sales_Org_Key__c) *** ' + soMap.get(pq.Sales_Org_Key__c));
                        System.debug('*** soMap.get(pq.Sales_Org_Key__c)..Pricing_Type__c *** ' + soMap.get(pq.Sales_Org_Key__c).Pricing_Type__c );
                        if( soMap.get(pq.Sales_Org_Key__c).Pricing_Type__c == 'All' ){ 
                            populatePriceProductToPQLIBySoldToType(pq, mcheck, prodQuoteLineItem1, soldToType);
                        }//end of if pq.Sales_Org_Key__c
                        else{
                            System.debug('*** In Hospital List Pricing for non US/CA Accounts after if sap.Price__c != 0.00 ***');
                            if( soMap.get(pq.Sales_Org_Key__c).Pricing_Type__c == 'Distributor List' ){
                                prodQuoteLineItem1.List_Price__c = mcheck.Distributor_List__c;
                            }
                            else{
                                prodQuoteLineItem1.List_Price__c = mcheck.List_Price__c;
                            }
                        }//end of else of pq.Sales_Org_Key__c
                        
                    }//end of if sap.price__c != 0.00
                    else{
                        System.debug('*** Else after If sap.price__c != 0.00 ***');
                        if(!refresh){
                            //logic to handle Hospital, Distributor, and Alt Site pricing
                            System.debug('*** if(!refresh) *** ');
                            if( soMap.get(pq.Sales_Org_Key__c).Pricing_Type__c == 'All' ){
                                System.debug('*** IN All LOGIC Pricing_Type__c !refresh ***');
                                populatePriceProductToPQLIBySoldToType(pq, mcheck, prodQuoteLineItem1, soldToType);
                                //end of logic to handle Hospital, Distributor, and Alt Site pricing
                            }//end of if pq.Sales_Org_Key__c
                            else{
                                populatePriceProductToPQLI(pq, mcheck, prodQuoteLineItem1);
                            }//end of else pq.Sales_Org_Key__c
                        }//end of if(!refresh)
                        else{//after if(!refresh)
                            //start of refresh
                            System.debug('*** if(!refresh) else *** ');
                            if(soMap.containsKey(pq.Sales_Org_Key__c) && soMap.get(pq.Sales_Org_Key__c).Pricing_Type__c == 'All' ){
                                System.debug('*** IN All LOGIC Pricing_Type__c refresh ***');
                                populatePriceProductToPQLIBySoldToType(pq, mcheck, prodQuoteLineItem1, soldToType);
                                //end of logic to handle Hospital, Distributor, and Alt Site pricing
                            }//end of if pq.Sales_Org_Key__c
                            else{
                                populatePriceProductToPQLI(pq, mcheck, prodQuoteLineItem1);
                            }//end of else pq.Sales_Org_Key__c
                            //end of refresh
                        }
                        //prodQuoteLineItem1.Eligible_Price__c = mcheck.List_Price__c;
                    }
                    
                    //check for SAP Agreement null or blank value
                    
                    prodQuoteLineItem1.Sales_Number__c = SAP_1stPick;
                    IF(SAP_1stPick != null){
                        System.debug('*** SAP_1stPick != null sapList[0].AgrObjective__c *** ' + sapList[0].AgrObjective__c);
                        //customer service rebate only check
                        if(sapList[0].AgrObjective__c!=NULL && sapList[0].AgrObjective__c == '06' && userRoleBoolean ){
                            System.debug('*** Customer Service Rebate Only Sales Deal Description ***');
                            prodQuoteLineItem1.Sales_deal_Description__c = NULL;
                        }
                        else{
                            prodQuoteLineItem1.Sales_deal_Description__c = sap.AgrDesc__c;
                        }
                        
                    }
                    else{
                        prodQuoteLineItem1.Sales_deal_Description__c = 'No Contract';
                    }
                    
                    //cross reference check
                    If(crossStr != null && crossStr != 'refresh'){
                        prodQuoteLineItem1.Competetive_Product__c = crossStr;
                    }
                    
                    system.debug('*** prodQuoteLineItem1.Sales_Number__c: ' + prodQuoteLineItem1.Sales_Number__c);
                    system.debug('*** prodQuoteLineItem1.Sales_deal_Description__c: ' + prodQuoteLineItem1.Sales_deal_Description__c);
                    
                    prodQuoteLineItem1.Condition__c = conremap;
                    
                    qLineItem.add(prodQuoteLineItem1);
                    system.debug('*** qLineItem ======================== ' + qLineItem);
                }
            } // End of SAP for(SAPRealPriceSet__x sap : sapList)
            else if(cnlist.size()>0) {
                subGetPriceFromContactMaterial(pq, mcheck, null, cnlist, crossStr, lineItemId, rowOrder, qLineItem);
				Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,''+' Cannot retrieve SAP Price, using the Contract Material Price instead!'));
            }
            else {
                subGetPriceFromProduct(pq, mcheck, crossStr, lineItemId, rowOrder, qLineItem);
				Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,''+' Cannot retrieve SAP Price/Contract Material Price, using the SF Product Price instead!'));
            }
        }
        else {
            	subGetPriceFromProduct(pq, mcheck, crossStr, lineItemId, rowOrder, qLineItem);
        }
        
    } 
    
    private void subGetPriceFromProduct(Price_Quote__c pq, Product2 mcheck, String crossStr, String lineItemId, Decimal rowOrder, List<Price_Quote_Line_Item__c> qLineItem){
        system.debug('*** Starting getPrice without SAP --> subGetPriceFromProduct()***');
        
        ++rowOrder;
        
        Price_Quote_Line_Item__c prodQuoteLineItem1 = new Price_Quote_Line_Item__c(
            Price_Quote__c = pq.Id,
            Material_Name__c = mcheck.Id,
            RSM_Price__c = mcheck.RSM_Price__c,
            Rep_Price__c = mcheck.Rep_Price__c,
            Director_Price__c = mcheck.Director_Price__c,
            Floor_Price__c = mcheck.Floor_Price__c,
            Cost__c = mcheck.Cost_Formula__c,
            Material_Status__c = mcheck.Material_Status_Numeric__c,
            Row_Order__c = rowOrder,
            MRP_Group__c = mcheck.MRP_Group__c,
            CurrencyIsoCode = pq.CurrencyIsoCode,
            Min_Order_Qty__c = ((pq.BusinessUnit__c == 'EMEA' || userRoleName.containsIgnoreCase('EMEA')) && mcheck.Min_Order_Qty__c != NULL && mcheck.Min_Order_Qty__c != 0) ? mcheck.Min_Order_Qty__c : 1,
            Quantity__c = ((pq.BusinessUnit__c == 'EMEA' || userRoleName.containsIgnoreCase('EMEA')) && mcheck.Min_Order_Qty__c != NULL && mcheck.Min_Order_Qty__c != 0) ? mcheck.Min_Order_Qty__c : 1
        );
        
        if(lineItemId == NULL){
            //check for surgical custom product description
            prodQuoteLineItem1.Product_Description__c = (mcheck.Product_Description_Custom__c != NULL) ? mcheck.Product_Description_Custom__c : mcheck.Description;
            
            prodQuoteLineItem1.Row_Order__c = pq.Line_Count__c;
            
            //logic to handle Hospital, Distributor, and Alt Site pricing
            if(pq.Account_Name__c!=null && soMap.get(pq.Sales_Org_Key__c).Pricing_Type__c == 'All' && pq.Sales_Org_Key__c != 'US6020'){
                populatePriceProductToPQLIBySoldToType(pq, mcheck, prodQuoteLineItem1, pq.Account_Name__r.Price_List_Type__c);
            }
            else{
                prodQuoteLineItem1.List_Price__c = mcheck.Distributor_List__c;
                prodQuoteLineItem1.Sales_Price__c = mcheck.Distributor_List__c;
                prodQuoteLineItem1.Eligible_Price__c = mcheck.Distributor_List__c;
            }
        }
        else{
            prodQuoteLineItem1.Id = lineItemId;
            prodQuoteLineItem1.Hide_Crossreference__c = false;
        }
        
        //cross reference check
        If(crossStr != null && crossStr != 'refresh'){
            prodQuoteLineItem1.Competetive_Product__c = crossStr;
        }
        
        //add object to list
        qLineItem.add(prodQuoteLineItem1);
        
        system.debug('*** qLineItem ======================== ' + qLineItem);
    }
    
    private void subGetPriceFromContactMaterial(Price_Quote__c pq, Product2 mcheck, Contract_Material__c cm, List<string> cnlist, String crossStr, String lineItemId, Decimal rowOrder, List<Price_Quote_Line_Item__c> qLineItem){
        system.debug('*** Starting getPrice without SAP --> subGetPriceFromContactMaterial()***');
        list<String> ccaList = new list<String>();
        Contract_Material__c cmRec;
        if(cm != null){
            cmRec = cm;
        }
        else if(cnlist.size()>0){
            for(Contract_Customer__c cc : [SELECT Agreement__r.Agreement_Number__c
                                           FROM Contract_Customer__c
                                           WHERE Account__r.SAP_Sold_To__c IN :cnlist
                                           AND Active__c = TRUE])
            {
                ccaList.add(cc.Agreement__r.Agreement_Number__c);
            }
            System.debug('*** ccalist:' + ccaList);
            // Material Map - Used to filter...
            cmRec = [SELECT Product__r.Name, Agreement__r.Agreement_Number__c, Agreement__r.Description__c, Agreement__r.Sales_Org__c,
                     RSM_Price__c, Rep_Price__c, Director_Price__c, List_Price__c, Price__c, Agreement__r.Objective_Name__c
                     FROM Contract_Material__c
                     WHERE Product__r.Id =: mcheck.Id
                     AND Agreement_Number__c IN :ccaList
                     AND Active__c = TRUE
                     ORDER BY Price__c
                     LIMIT 1];
        }
        System.debug('*** cmRec:' + cmRec);
        
        if(cmRec != null){
            ++rowOrder;
            
            Price_Quote_Line_Item__c prodQuoteLineItem1 = new Price_Quote_Line_Item__c(
                Price_Quote__c = pq.Id,
                Material_Name__c = mcheck.Id,
                RSM_Price__c = cmRec.RSM_Price__c,
                Rep_Price__c = cmRec.Rep_Price__c,
                Director_Price__c = cmRec.Director_Price__c,
                Floor_Price__c = mcheck.Floor_Price__c,
                Cost__c = mcheck.Cost_Formula__c,
                Material_Status__c = mcheck.Material_Status_Numeric__c,
                Row_Order__c = rowOrder,
                MRP_Group__c = mcheck.MRP_Group__c,
                CurrencyIsoCode = pq.CurrencyIsoCode,
                Sales_Number__c = cmRec.Agreement__r.Agreement_Number__c,
                Sales_Deal_Description__c = cmRec.Agreement__r.Description__c,
                Condition__c = cmRec.Agreement__r.Objective_Name__c,
                Min_Order_Qty__c = ((pq.BusinessUnit__c == 'EMEA' || userRoleName.containsIgnoreCase('EMEA')) && mcheck.Min_Order_Qty__c != NULL && mcheck.Min_Order_Qty__c != 0) ? mcheck.Min_Order_Qty__c : 1,
                Quantity__c = ((pq.BusinessUnit__c == 'EMEA' || userRoleName.containsIgnoreCase('EMEA')) && mcheck.Min_Order_Qty__c != NULL && mcheck.Min_Order_Qty__c != 0) ? mcheck.Min_Order_Qty__c : 1,
                List_Price__c = cmRec.List_Price__c,
                Sales_Price__c = cmRec.Price__c
            );
            
            if(lineItemId == NULL){
                //check for surgical custom product description
                prodQuoteLineItem1.Product_Description__c = (mcheck.Product_Description_Custom__c != NULL) ? mcheck.Product_Description_Custom__c : mcheck.Description;
                
                prodQuoteLineItem1.Row_Order__c = pq.Line_Count__c;
                
                //prodQuoteLineItem1.List_Price__c = cmRec.List_Price__c;
                if(prodQuoteLineItem1.Sales_Price__c < 1){
                    prodQuoteLineItem1.Sales_Price__c = cmRec.List_Price__c;
                    prodQuoteLineItem1.Eligible_Price__c = cmRec.List_Price__c;
                }
            }
            else{
                prodQuoteLineItem1.Id = lineItemId;
                prodQuoteLineItem1.Hide_Crossreference__c = false;
            }
            
            //cross reference check
            If(crossStr != null && crossStr != 'refresh'){
                prodQuoteLineItem1.Competetive_Product__c = crossStr;
            }
            
            //add object to list
            qLineItem.add(prodQuoteLineItem1);
            
            system.debug('*** qLineItem ======================== ' + qLineItem);
        }
    }
    
    private void populatePriceProductToPQLIBySoldToType(Price_Quote__c pq, Product2 mcheck, Price_Quote_Line_Item__c prodQuoteLineItem1, String soldToType){
        //logic to handle Hospital, Distributor, and Alt Site pricing
        //Alt Site Accounts
        if(soldToType == 'ZA'){
            System.debug('*** In Alt Site List Pricing ***');
            prodQuoteLineItem1.List_Price__c = mcheck.Alt_Site_List__c;
            prodQuoteLineItem1.Sales_Price__c = (mcheck.Alt_Site_List__c != 0.00) ? mcheck.Alt_Site_List__c : 0.00;
            prodQuoteLineItem1.Eligible_Price__c = mcheck.Alt_Site_List__c;
        }
        //Distributor Accounts
        if(soldToType == 'ZD'){
            System.debug('*** In Distributor List Pricing ***');
            prodQuoteLineItem1.List_Price__c = mcheck.Distributor_List__c;
            prodQuoteLineItem1.Sales_Price__c = (mcheck.Distributor_List__c != 0.00) ? mcheck.Distributor_List__c : 0.00;
            prodQuoteLineItem1.Eligible_Price__c = mcheck.Distributor_List__c;
        }
        //Hospital Accounts
        if(soldToType == 'ZH' || soldToType == '' || soldToType == NULL){
            System.debug('*** In Hospital List Pricing ***');
            prodQuoteLineItem1.List_Price__c = mcheck.List_Price__c;
            prodQuoteLineItem1.Sales_Price__c = (mcheck.List_Price__c != 0.00) ? mcheck.List_Price__c : 0.00;
            prodQuoteLineItem1.Eligible_Price__c = mcheck.List_Price__c;
        }
        //end of logic to handle Hospital, Distributor, and Alt Site pricing
    }
    
    private void populatePriceProductToPQLI(Price_Quote__c pq, Product2 mcheck, Price_Quote_Line_Item__c prodQuoteLineItem1){
        System.debug('*** Else after If pq.Sales_Org_Key__c == US103010 || pq.Sales_Org_Key__c == US6010 || pq.Sales_Org_Key__c == CA1010 ***');
        //Start of US6020 ZD Pricing Only
        if(soMap.containsKey(pq.Sales_Org_Key__c) && soMap.get(pq.Sales_Org_Key__c).Pricing_Type__c == 'Distributor List' ){
            System.debug('*** IN Distributor List LOGIC Pricing_Type__c !refresh ***');
            prodQuoteLineItem1.List_Price__c = mcheck.Distributor_List__c;
            prodQuoteLineItem1.Sales_Price__c = (mcheck.Distributor_List__c != 0.00) ? mcheck.Distributor_List__c : 0.00;
            prodQuoteLineItem1.Eligible_Price__c = mcheck.Distributor_List__c;
        }
        else{
            //All other Sales Orgs
            prodQuoteLineItem1.List_Price__c = mcheck.List_Price__c;
            prodQuoteLineItem1.Sales_Price__c = (mcheck.List_Price__c != 0.00) ? mcheck.List_Price__c : 0.00;
            prodQuoteLineItem1.Eligible_Price__c = mcheck.List_Price__c;
        }//end else for pq.Sales_org_Key__c = US6020
    }
    
    private void subAddProcessedLiToPriceQuote(Price_Quote__c pq, List<Price_Quote_Line_Item__c> qLineItem, String lineItemId){
        system.debug('*** qLineItem ======================= ' + qLineItem);
        
        if(lineItemId == NULL){
            database.insert(qLineItem,false);
        }
        else{
            database.update(qLineItem,false);
        }
        
        //conditions below helps with Price Quote and PRF Approval Matrix Routing
        if(pq.BusinessUnit__c == 'Alternate Care'){
            lineClassCheck(pq.Id);
        }
        
        if(pq.BusinessUnit__c == 'Anesthesia'){
            lineProdCheckAnes(pq.Id);
        }
        
        if(pq.BusinessUnit__c == 'Interventional Capital' || pq.BusinessUnit__c == 'Cardiac'){
            lineProdCheckIcap(pq.Id);
        }
        
        if(pq.BusinessUnit__c == 'Surgical Instruments'){
            lineClassCheck(pq.Id);
        }
    }
    
    
    //Gets the price from SAP, if execption or SAP Sold to is Null, gets price from SF Product
    global void getSAPpriceNew(Product2 mcheck,String crossStr,String lineItemId, Price_Quote__c pq, String cpSoldToAcct, String plt){

        Boolean sapDownCheck = true; //switch to custom setting later
        Decimal rowOrder = pq.Line_Count__c;
        List<Price_Quote_Line_Item__c> qLineItem = new List<Price_Quote_Line_Item__c>();
        if(sapDownCheck == true){
            try{
                
                //end of ASK Agreement logic
                system.debug('*** mcheck ====================== getSAPprice 1' + mcheck);
                
                //pass vales to sub method for sap callout
                subGetPriceFromSapNew(pq, mcheck, new List<String> {mcheck.Name}, crossStr,lineItemId, rowOrder, cpSoldToAcct, plt, qLineItem);

                system.debug('*** qLineItem.size() in getSAPpriceNew PP_SAP_Price.cls *** ' + qLineItem.size() );

                If(qLineItem.size() > 0){
                    subAddProcessedLiToPriceQuote(pq, qLineItem, lineItemId);
                }
                
            }//end of outtermost try after IF(pq.InApproval__c)
            catch(Exception e){
                System.debug('*** e getSapPrice *** ' + e);
                //Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,''+'Error detected: ' + e));
            }
        }else{
            //run SF Contract Price Logic
            subGetPriceFromContactMaterial(pq, mcheck, null, null, crossStr, lineItemId, rowOrder, qLineItem);

            If(qLineItem.size() > 0){
                subAddProcessedLiToPriceQuote(pq, qLineItem, lineItemId);
            }
        }
    }//end getSapPriceNew

    private void subGetPriceFromSapNew(Price_Quote__c pq, Product2 mcheck, List<String> materialStr, String crossStr, String lineItemId, Decimal rowOrder, String cpSoldToAcct, String soldToAcctType, List<Price_Quote_Line_Item__c> qLineItem){
        system.debug('*** Starting getPrice with SAP ***');
        system.debug('*** pq *** ' + pq);
        system.debug('*** mcheck *** ' + mcheck);
        system.debug('*** materialStr.size() *** ' + materialStr.size() );
        system.debug('*** lineItemId *** ' + lineItemId);
        system.debug('*** rowOrder *** ' + rowOrder);
        system.debug('*** cpSoldToAcct *** ' + cpSoldToAcct);
        system.debug('*** soldToAcctType *** ' + soldToAcctType);
        system.debug('*** qLineItem.size() *** ' + qLineItem.size() );

        String SAP_1stPick = '00000000';
        boolean refresh = FALSE;
        if(!String.isBlank(crossStr) && crossStr == 'refresh'){
            refresh = TRUE;
        }//end if
        system.debug('*** crossStr *** ' + crossStr);
        system.debug('*** crossStr refresh*** ' + refresh);
        
        List<string> cnlist = new List<String>();
        String shipTo = pq.Account_Name__r.SAP_Sold_To__c;
        
        //Account has SAP Code
        //if(pq.Account_Name__c != null && pq.Account_Name__r.SAP_Sold_To__c != NULL){//remove check
        cnlist.add(shipTo);
        cnlist.add(cpSoldToAcct);
            
        //Query to get Price List Type of SAP Sold To Account
        //String soldToType = plt;
        system.debug('*** cnlist (Customer Number List) ================= ' + cnlist);
        system.debug('*** mcheck.Sales_Org__c b4 SAP ============== ' + mcheck.Sales_Org__c);
        system.debug('*** mcheck.Distribution_Channel__c b4 SAP============== ' + mcheck.Distribution_Channel__c);
        system.debug('*** mcheck.Name b4 SAP============== ' + mcheck.Name);
        
        datetime datenew = datetime.now(); //set datetime for sap query
            
        List<SAPRealPriceSet__x> sapList = new List<SAPRealPriceSet__x>();//List or object???
        if(Test.isRunningTest()) {
            for(Integer i = 0; i < 3; i++){
                Decimal testPrice = i == 2 ? 0.00 : 123.00;
                SAPRealPriceSet__x testSAP = new SAPRealPriceSet__x(
                    SalesDeal__c = '50009064',
                    Price__c = testPrice,
                    Material__c = '353535',
                    MtrlStatus__c = '40',
                    SalesMtrlStatus__c = '40',
                    ValidFrom__c = Date.Today(),
                    ValidTo__c = Date.Today() + 1000,
                    AgrDesc__c = 'Duke University SURGR',
                    Condition__c = 'XNAF',
                    OwnerName__c = 'Duke Univ Health System',
                    Owner__c = 'IDN-032',
                    AgrObjective__c = '06',
                    Customer__c  = '0000102059',
                    ListPrice__c = testPrice
                );
                sapList.add(testSAP);
            }
        }//end if(!Test.isRunningTest())
        else{  
            try {
                sapList = [SELECT SalesDeal__c, Price__c, Material__c, MtrlStatus__c,
                            ValidFrom__c, ValidTo__c, Agreement__c, AgrDesc__c, Condition__c,
                            OwnerName__c, Owner__c, AgrObjective__c, Customer__c, SalesMtrlStatus__c,
                            DistChnl__c,MatDesc__c,vat__c,Currency__c,ShipTo__c, ListPrice__c
                            FROM SAPRealPriceSet__x
                            WHERE SalesOrg__c = :mcheck.Sales_Org__c
                            AND DistChnl__c = :mcheck.Distribution_Channel__c
                            AND Customer__c = :cpSoldToAcct
                            AND Material__c = :mcheck.Name
                            AND ShipTo__c = :shipTo
                            AND EffDate__c = :datetime.now()
                            ];
            }
            catch(Exception ex){
                sapList = null;
            }
        }
        //************************************* Start Rebate Only Check *******************************************
        //System.debug('*** userRole crossBulk *** ' + userRole);
            
            //Sap check
            if(sapList!=null && sapList.size() > 0 ){ //Sap always returns data unless out of service
                System.debug('*** sapList[0].AgrObjective__c *** ' + sapList[0].AgrObjective__c);
                System.debug('*** sapList[0].SalesDeal__c *** ' + sapList[0].SalesDeal__c);
                String compDeal = sapList[0].SalesDeal__c;       
                
                system.debug('*** sapList[0] ================== ' + sapList[0]);
                //system.debug('*** sapList[0].Price__c ================== ' + sapList[0].Price__c);
                string objname;
                string mstatus;
                ++rowOrder;
                string conremap = sapList[0].Condition__c;

                //start Customer Service check for rebate contract
                if(sapList[0].AgrObjective__c == '06' && userRoleBoolean){
                    System.debug('*** Customer Service in PP_SAP_Price.cls subGetPriceFromSapNew ***');
                    //String cnum = shipTo;
                    //String pnum = mcheck.name;
                    //PP_Price_Lookup pl = new PP_Price_Lookup();

                    //PageReference priceLookup = New Pagereference('/apex/PP_Price_Lookup?cid=' + cnum + '&pid='+ pnum);
                    //priceLookup.setRedirect(true);
                    //getCustServPrice(Price_Quote__c pq, String cnum, String pnum, List<Price_Quote_Line_Item__c> qLineItem)
                    Price_Quote_Line_Item__c pqliObj = getCustServPrice(mcheck, crossStr, lineItemId, pq, cpSoldToAcct, soldToAcctType, qLineItem);
                    system.debug('*** Finished getCustServPrice and now adding to list qLineItem');
                    qLineItem.add(pqliObj);
                }else{
                    System.debug('*** NOT Customer Service in PP_SAP_Price.cls subGetPriceFromSapNew ***');
                    if(cMap.size()>0 && cMap.containsKey(sapList[0].Condition__c) && cMap.get(sapList[0].Condition__c) != NULL){
                        conremap = cMap.get(sapList[0].Condition__c);
                    }
                    system.debug('*** conremap *** ' + conremap);

                    if(sapList[0].SalesDeal__c != NULL){
                        SAP_1stPick = sapList[0].SalesDeal__c.right(8);
                    }
                    else{
                        SAP_1stPick = 'No Contract';
                    }
                    system.debug('*** SAP_1stPick ================ ' + SAP_1stPick);
                    system.debug('*** sapList[0].SalesDeal__c ================ ' + sapList[0].SalesDeal__c);
                    String cnum2;

                    //below here
                    // Strip the leading zero's - 06Jul2016 ESC
                    if(sapList[0].Customer__c != NULL){
                        cnum2 = sapList[0].Customer__c.replaceAll('^0+', '');
                    }
                    // Checks to see if the Sales Material Status Exists and if it does we use that, otherwise we default
                    // to the standard Material Status. - 06Jul2016 ESC
                    if(sapList[0].SalesMtrlStatus__c != NULL){
                        mstatus = sapList[0].SalesMtrlStatus__c;
                    }
                    else if(sapList[0].MtrlStatus__c != NULL){
                        mstatus = sapList[0].MtrlStatus__c;
                    }
                    
                    Price_Quote_Line_Item__c prodQuoteLineItem1 = new Price_Quote_Line_Item__c(
                        Price_Quote__c = pq.Id,
                        Material_Name__c = mcheck.Id,
                        Material_Status__c = mstatus,
                        RSM_Price__c = mcheck.RSM_Price__c,
                        Rep_Price__c = mcheck.Rep_Price__c,
                        Director_Price__c = mcheck.Director_Price__c,
                        Floor_Price__c = mcheck.Floor_Price__c,
                        Cost__c = mcheck.Cost_Formula__c,
                        Objective__c = sapList[0].AgrObjective__c,
                        MRP_Group__c = mcheck.MRP_Group__c,
                        //Sales_Price__c = sapList[0].Price__c,
                        Sales_Number__c = SAP_1stPick,
                        Sales_deal_Description__c = sapList[0].AgrDesc__c,
                        Eligible_Price__c = sapList[0].Price__c,
                        List_Price__c = sapList[0].ListPrice__c,
                        Min_Order_Qty__c = ((pq.BusinessUnit__c == 'EMEA' || userRoleName.containsIgnoreCase('EMEA')) && mcheck.Min_Order_Qty__c != NULL && mcheck.Min_Order_Qty__c != 0) ? mcheck.Min_Order_Qty__c : 1,
                        Quantity__c = ((pq.BusinessUnit__c == 'EMEA' || userRoleName.containsIgnoreCase('EMEA')) && mcheck.Min_Order_Qty__c != NULL && mcheck.Min_Order_Qty__c != 0) ? mcheck.Min_Order_Qty__c : 1,
                        Material_Description__c = (pq.Businessunit__c == 'EMEA') ? sapList[0].MatDesc__c : NULL,
                        CurrencyIsoCode = (pq.Businessunit__c == 'EMEA') ? sapList[0].Currency__c : pq.CurrencyIsoCode,
                        VAT__c = (pq.Businessunit__c == 'EMEA' && sapList[0].VAT__c == NULL) ? NULL : ((sapList[0].VAT__c == NULL)? NULL : Decimal.Valueof(sapList[0].Vat__c))
                    );
                    
                    //if statement handles blank line functionality???
                    if(lineItemId == NULL){
                        //check for surgical custom product description
                        prodQuoteLineItem1.Product_Description__c = (mcheck.Product_Description_Custom__c != NULL) ? mcheck.Product_Description_Custom__c : mcheck.Description;
                        
                        prodQuoteLineItem1.Row_Order__c = pq.Line_Count__c;
                    }
                    else{
                        prodQuoteLineItem1.Id = lineItemId;
                        prodQuoteLineItem1.Hide_Crossreference__c = false;
                    }
                    
                    //check for eligible price = 0
                    if(sapList[0].Price__c > 0){
                        System.debug('*** sapList[0].Price__c != 0.00 *** ');
                        if(!refresh){
                            System.debug('*** if(!refresh) sapList[0].Price__c > 0 *** ');
                            system.debug('******TROUBLESHOOT HAS SAP PRICE IF******' +  sapList[0].Price__c);
                            prodQuoteLineItem1.Sales_Price__c = sapList[0].Price__c;
                            prodQuoteLineItem1.Eligible_Price__c = sapList[0].Price__c;
                        }else{
                            system.debug('******TROUBLESHOOT HAS SAP PRICE ELSE******' +  sapList[0].Price__c);
                            prodQuoteLineItem1.Eligible_Price__c = sapList[0].Price__c;
                            prodQuoteLineItem1.Sales_Price__c = prodQuoteLineItem1.Sales_Price__c;
                        }

                    }//end of if sap.price__c != 0.00
                    else{
                        //Price__c == 0 we should use ListPrice__c field from SAP
                        //prodQuoteLineItem1.Sales_deal_Description__c = 'No Contract'; //set to No Contract if Price__c == 0

                        System.debug('*** Else after If sap.price__c > 0.00 ***');
                        if(!refresh){
                            //logic to handle Hospital, Distributor, and Alt Site pricing
                            system.debug('******TROUBLESHOOT NO SAP PRICE IF******' +  sapList[0].ListPrice__c);
                            prodQuoteLineItem1.Sales_Price__c = sapList[0].ListPrice__c;
                            prodQuoteLineItem1.Eligible_Price__c = sapList[0].ListPrice__c;
                        }//end of if(!refresh)
                        else{//after if(!refresh)
                            system.debug('******TROUBLESHOOT NO SAP PRICE ELSE******' +  sapList[0].ListPrice__c);
                            //start of refresh
                            prodQuoteLineItem1.Eligible_Price__c = sapList[0].ListPrice__c;
                            prodQuoteLineItem1.Sales_Price__c = prodQuoteLineItem1.Sales_Price__c;
                        }
                        //prodQuoteLineItem1.Eligible_Price__c = mcheck.List_Price__c;
                    }

                    //cross reference check
                    If(crossStr != null && crossStr != 'refresh'){
                        prodQuoteLineItem1.Competetive_Product__c = crossStr;
                    }
                    
                    system.debug('*** prodQuoteLineItem1.Sales_Number__c: ' + prodQuoteLineItem1.Sales_Number__c);
                    system.debug('*** prodQuoteLineItem1.Sales_deal_Description__c: ' + prodQuoteLineItem1.Sales_deal_Description__c);
                    
                    prodQuoteLineItem1.Condition__c = conremap;

                    qLineItem.add(prodQuoteLineItem1);
                }//end of else Customer Service check
                //above here

            } // End of SAP for(SAPRealPriceSet__x sap : sapList)
            else if(cnlist.size()>0) {
                subGetPriceFromContactMaterial(pq, mcheck, null, cnlist, crossStr, lineItemId, rowOrder, qLineItem);
				Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,''+' Cannot retrieve SAP Price, using the Contract Material Price instead!'));
            }
            else {
                subGetPriceFromProduct(pq, mcheck, crossStr, lineItemId, rowOrder, qLineItem);
				Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,''+' Cannot retrieve SAP Price/Contract Material Price, using the SF Product Price instead!'));
            }
        //}
        //else {
            	//subGetPriceFromProduct(pq, mcheck, crossStr, lineItemId, rowOrder, qLineItem);
        //}
        
    }//end sub get sap price

    //start of Customer Service fix

    public Price_Quote_Line_Item__c getCustServPrice(Product2 mcheck,String crossStr,String lineItemId, Price_Quote__c pq, String cpSoldToAcct, String soldToAcctType, List<Price_Quote_Line_Item__c> qLineItem){
        system.debug('*** Starting getCustServPrice in PP_SAP_Price.cls ***');
        List<SAPRealPriceSet__x> listSAP = new List<SAPRealPriceSet__x>();
        SAPRealPriceSet__x sap = new SAPRealPriceSet__x();
        Decimal rowOrder = pq.Line_Count__c;
        // Step 1
        // a. Set up our Variables
        //string sapSoldTo = ApexPages.currentPage().getParameters().get('cid');
        //shipTo = ApexPages.currentPage().getParameters().get('cid');
        //string searchMaterials = ApexPages.currentPage().getParameters().get('pid');
        String salesOrg;
        String SAP_1stPick = '00000000';
     
        String shipTo = pq.Account_Name__r.SAP_Sold_To__c;
        String matName = mcheck.Name;
     
        // Used to return the Text Status. Example: 40 = Saleable (40)
        PP_General_Helper_Class ghc = new PP_General_Helper_Class();
        map<String, String> mstatMap = ghc.mstatus();
     
        // Used to create a Objective Mapping in english instead of numbers
        Map<String, String> obMap = new Map<String, String>();
        obMap.put('01', 'Direct/Rebate');
        obMap.put('02', 'Direct');
        obMap.put('03', 'Distributor Netbill');
        obMap.put('04', 'Specialty Market');
        obMap.put('05', 'Strategic Accounts');
        obMap.put('06', 'Rebate Only');
     
        // c. Create our list of Sold-to/Ship-to relationships
        system.debug('Starting getPrice');
        //holds list of sap codes to filter Contract Customer records... added shipTo & soldTo values
        list<string> sapNumList = new list<String>{pq.Account_Name__r.SAP_Sold_To__c, cpSoldToAcct}; 
        Set<String> sapNumSet = new Set<String>(); //set for unique sap codes
        //sapNumList.add(pq.Account_Name__r.SAP_Sold_To__c); //add shipTo sap code
        //sapNumList.add(cpSoldToAcct); //add soldTo sap code
     
        // Primary Customer Number (pcn) to the current account and if we are a 'Ship-To' account and there is a valid
        // 'Sold-to' relationship in the 'Contract Partnership' table then we reset that to the Last Sold-to in the table.
        // There is supposed to be only one to one but you can have as many as 3-4 hits on rare occasion.
        // Customer Number List (cnlist) is the list of Customer numbers we will use to generate our list of 'Contract Customers'
     
        //Create instance of Pricing Portal data utility class to get list of Contract Customer records to loop through
        //to retreive the Agreement Numbers in a list to use to pull Contract Material Records
        PP_DataUtility ppduClass = new PP_DataUtility();
        List<Contract_Customer__c> ccList = ppduClass.contractCustomerNonRebateList(sapNumList);
        system.debug('*** ccList.size() *** ' + ccList.size() );
     
        List<String> agreeNums = new List<String>(); //holds list of agreement numbers to filter Contract Materials
     
        //loop to create string list of agreement numbers
        for(Contract_Customer__c cc : ccList)
        {
            agreeNums.add(cc.Agreement_Number__c);
        }
        system.debug('*** agreeNums.size() *** ' + agreeNums.size() );
     
        //retreive Contract Material records using Pricing Portal data utility class
        List<Contract_Material__c> cmList = ppduClass.contractMaterialList(mcheck,agreeNums);
        system.debug('*** cmList.size() *** ' + cmList.size() );
     
        List<String> agreeNumList = new List<String>(); //holds list of agreement numbers from Contract Customers
        Map<String, String> matMap = new Map<String, String>();
     
        //loop to get list of agreement numbers from Contract Materials... create a map of agreement number & material name
        for(Contract_Material__c cm : cmList)
        {
            agreeNumList.add(cm.Agreement_Number__c);
            matMap.put(cm.Agreement_Number__c, cm.Material_Name__c);
        }
        system.debug('cmList.size: ' + cmList.size());
     
        //pass sap code list and agreement number list to PP data utility to return one contract customer record
        Contract_Customer__c ccObj = ppduClass.contractCustomerAgreeFiltList(sapNumList,agreeNumList);
        system.debug('*** ccObj *** ' + ccObj );
     
        sap = [SELECT SalesDeal__c, Price__c, Material__c, MtrlStatus__c, ValidFrom__c,
               ValidTo__c, Agreement__c, AgrDesc__c, Condition__c, ListPrice__c,
               OwnerName__c, Owner__c, AgrObjective__c, Customer__c, SalesMtrlStatus__c,
               DistChnl__c,MatDesc__c,vat__c,Currency__c,ShipTo__c
               FROM SAPRealPriceSet__x
               WHERE SalesOrg__c = :mcheck.Sales_Org__c
               AND DistChnl__c = :mcheck.Distribution_Channel__c
               AND Agreement__c = :ccObj.Agreement_Number__c
               AND Customer__c = :ccObj.Sap_Code__c
               AND Material__c = :matMap.get(ccObj.Agreement_Number__c)
               AND ShipTo__c = :shipTo
               AND EffDate__c = :datetime.now()
               LIMIT 1 ];
     
        system.debug('*** sap *** ' + sap );
        string objname;
        string mstatus;
        string cnum2;
        string ostr;
     
        if(obMap.get(sap.AgrObjective__c) != NULL){
            objname = obMap.get(sap.AgrObjective__c);
        }
        else{
            objname = sap.AgrObjective__c;
        }
     
        string conremap = sap.Condition__c;
        if(cMap.get(sap.Condition__c) != NULL){
            conremap = cMap.get(sap.Condition__c);
        }
        system.debug('*** conditionMap *** ' + cMap);
     
     
        if(sap.SalesMtrlStatus__c != NULL){
            mstatus = sap.SalesMtrlStatus__c;
        }
        else if(sap.MtrlStatus__c != NULL){
            mstatus = sap.MtrlStatus__c;
        }
        else{
            mstatus = '';
        }
        // Strip the leading zero's
        system.debug('*** sap.Customer__c *** ' + sap.Customer__c);
        if(sap.Customer__c != NULL){
            cnum2 = sap.Customer__c.replaceAll('^0+', '');
        }
        if(sap.Owner__c != NULL){
            ostr = sap.Owner__c.replaceAll('^0+', '');
        }
     
        /*
        SAPRealPriceSet__x newSAP = new SAPRealPriceSet__x(
            SalesDeal__c = sap.SalesDeal__c,
            Price__c = sap.Price__c,
            Material__c = sap.Material__c,
            MtrlStatus__c = mstatus,
            ValidFrom__c = sap.ValidFrom__c,
            ValidTo__c = sap.ValidTo__c,
            AgrDesc__c = sap.AgrDesc__c,
            Condition__c = conremap,
            OwnerName__c = sap.OwnerName__c,
            Owner__c = ostr,
            AgrObjective__c = objname,
            Customer__c  = cnum2,
            SalesMtrlStatus__c = sap.SalesMtrlStatus__c,
            Currency__c = sap.Currency__c
        );
        */
     
        if(sap.SalesDeal__c != NULL){
            SAP_1stPick = sap.SalesDeal__c.replaceAll('^0+', '');
        }
     
        // This is now in the helper class so that we can use this across objects if needed.
        // Also fixes the test coverage issue. - 05Jul2016 ESC
        if(mstatMap.get(mstatus) != NULL){
            status = mstatMap.get(mstatus);
        }
        else{
            status = 'None';
        }
     
        System.debug('*** Creating pqliObj in getCustServPrice PP_SAP_Price.cls ***');
        Price_Quote_Line_Item__c pqliObj = new Price_Quote_Line_Item__c(
            Price_Quote__c = pq.Id,
            Material_Name__c = mcheck.Id,
            Material_Status__c = mstatus,
            RSM_Price__c = mcheck.RSM_Price__c,
            Rep_Price__c = mcheck.Rep_Price__c,
            Director_Price__c = mcheck.Director_Price__c,
            Floor_Price__c = mcheck.Floor_Price__c,
            Cost__c = mcheck.Cost_Formula__c,
            Objective__c = sap.AgrObjective__c,
            MRP_Group__c = mcheck.MRP_Group__c,
            Sales_Price__c = sap.Price__c,
            Sales_Number__c = SAP_1stPick,
            Sales_deal_Description__c = sap.AgrDesc__c,
            Eligible_Price__c = sap.Price__c,
            List_Price__c = sap.ListPrice__c,
            Min_Order_Qty__c = ((pq.BusinessUnit__c == 'EMEA' || userRoleName.containsIgnoreCase('EMEA')) && mcheck.Min_Order_Qty__c != NULL && mcheck.Min_Order_Qty__c != 0) ? mcheck.Min_Order_Qty__c : 1,
            Quantity__c = ((pq.BusinessUnit__c == 'EMEA' || userRoleName.containsIgnoreCase('EMEA')) && mcheck.Min_Order_Qty__c != NULL && mcheck.Min_Order_Qty__c != 0) ? mcheck.Min_Order_Qty__c : 1,
            Material_Description__c = (pq.Businessunit__c == 'EMEA') ? sap.MatDesc__c : NULL,
            CurrencyIsoCode = (pq.Businessunit__c == 'EMEA') ? sap.Currency__c : pq.CurrencyIsoCode,
            VAT__c = (pq.Businessunit__c == 'EMEA' && sap.VAT__c == NULL) ? NULL : ((sap.VAT__c == NULL)? NULL : Decimal.Valueof(sap.Vat__c))
         );

         System.debug('*** Starting if checks for EMEA ***');
         //check for EMEA for min order qty
         /*
         if( (pq.BusinessUnit__c == 'EMEA' || userRoleName.containsIgnoreCase('EMEA') )
         && mcheck.Min_Order_Qty__c != NULL && mcheck.Min_Order_Qty__c != 0){
            pqliObj.Min_Order_Qty__c = mcheck.Min_Order_Qty__c;
         }else{
            pqliObj.Min_Order_Qty__c = 1;
         }

         //check for EMEA for qty
         if( (pq.BusinessUnit__c == 'EMEA' || userRoleName.containsIgnoreCase('EMEA')) 
         && mcheck.Min_Order_Qty__c != NULL && mcheck.Min_Order_Qty__c != 0){
            pqliObj.Quantity__c = mcheck.Min_Order_Qty__c;
         }else{
            pqliObj.Quantity__c = 1;
         }

         //check for EMEA material description
         if(pq.BusinessUnit__c == 'EMEA'){
            pqliObj.Material_Description__c = sap.MatDesc__c;
         }else{
            pqliObj.Material_Description__c = NULL;
         }
         
        //check for EMEA currency
        if(pq.BusinessUnit__c == 'EMEA'){
            pqliObj.CurrencyIsoCode = sap.Currency__c;
        }else{
            pqliObj.CurrencyIsoCode = pq.CurrencyIsoCode;
        }

        //check for EMEA vat value
        if(pq.BusinessUnit__c == 'EMEA' && sap.VAT__c == NULL){
            pqliObj.Vat__c = NULL;
        }else if(sap.Vat__c == NULL){
            pqliObj.Vat__c = NULL;
        }else{
            pqliObj.Vat__c = Decimal.Valueof(sap.Vat__c);
        }
        
        if(lineItemId == NULL){
            pqliObj.Row_Order__c = rowOrder;
        }
        */
        //if statement handles blank line functionality???
        if(lineItemId == NULL){
            //check for surgical custom product description
            pqliObj.Product_Description__c = (mcheck.Product_Description_Custom__c != NULL) ? mcheck.Product_Description_Custom__c : mcheck.Description;
            pqliObj.Row_Order__c = pq.Line_Count__c;
        }
        else{
            pqliObj.Id = lineItemId;
            pqliObj.Row_Order__c = pq.Line_Count__c + 1;
            pqliObj.Hide_Crossreference__c = false;
        }
        System.debug('*** pqliObj *** ' + pqliObj );
        System.debug('*** Created pqliObj in getCustServPrice PP_SAP_Price.cls ***');
        System.debug('*** pqliObj *** ' + pqliObj.Sales_Number__c );
         //qLineItem.add(pqliObj);
         return pqliObj;
         //System.debug('*** qLineItem.size() after PQ Line Item creation getCustServPrice *** ' + qLineItem.size() );
        //listSAP.add(newSAP);
           
      }
      //end of Customer Service fix
    
    
}//end of class