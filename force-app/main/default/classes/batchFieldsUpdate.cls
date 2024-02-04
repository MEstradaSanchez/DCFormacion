/**
* @author Adria Gil Sole
* @date 2021
* WI-000019
* WI-000020
* @description This class contains a Batch process to update Email or Phone fields for the objects we want using Apex Jobs
*/

global class batchFieldsUpdate implements Database.Batchable<sObject>, Database.Stateful {
    
    global List<String> exception_List;

    private String strObject;
    private List<String> strFields;
    //TEXT TO ADD IN THE FIELDS
	private String strMaskText;
    

    public batchFieldsUpdate(String strObj, List<String> strField, String strMskText) {
        strObject = strObj;
        strFields = strField;
        strMaskText = strMskText;
    }

      /*******************************************************************************************************
    * @description Uses a dynamic query to select the registers with the fields we want to update from the object required
    * @param type String that contains the type of the object to search (email or phone)
    * @return returns a List<sObject> with the ObjectNames and their FieldNames for the object defined in the parameter
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {

        String queryField='';

        for(integer i = 0; i<strFields.size();i++){
            queryField+=', ' +strFields[i];
        }
        
        String query = 'select id' + queryField +' from '+ String.escapeSingleQuotes(strObject);
        queryField='';
        return Database.getQueryLocator(query);
    }
      /*******************************************************************************************************
    * @description Updates the Object type Email/phone fields with the new values 
    * @param type List of sObjects that are queried in the start method
    */
    global void execute(Database.BatchableContext BC, List<sObject> lstSObject) {
        //FOR ALL THE LIST FIELDS SELECT THE REGISTERS AND CHANGE DE VALUE OF THE FIELD
        List<sObject> objectsToUpdate = new List<sObject>();
        for(String field : strFields){
            System.debug('-OBJECT- '+strObject + ' -FIELD-' + field); 
            System.debug('QUERY LIST ' + lstSObject);
            
            //ADD THE MASK TEXT TO THE ORIGINAL FIELD VALUES
            for(sObject objct : lstSObject){

                String idNow=(String)objct.get('id');
                String realEmail = (String)objct.get(field);
                String FinalEmail= realEmail + strMaskText;
               //FOR EVERY OBJECT IN THE OBJECT LIST UPDATE: WE DON'T WANT TO DUPLICATE ANY OBJECT BY ID, SO WE
               //MODIFY THE ONE ALLREADY STORED THAT HAS THE SAME ID WITH THE "new" other FIELD VALUE
                if(objectsToUpdate.size()>0){
                    Boolean exists=false;
                    for(integer i=0;i<objectsToUpdate.size();i++){
                        String idStored=(String)objectsToUpdate[i].get('id');                       
                        system.debug('IDNOW ' +idNow + ' ID STORED ' + idStored);
                        if(idNow==idStored){
                            objectsToUpdate[i].put(field,FinalEmail);
                            exists=true;
                        }
                    }
                    if(exists==false){
                        objct.put(field, FinalEmail); 
                        objectsToUpdate.add(objct); 
                    }
                }else{
                    objct.put(field, FinalEmail); 
                    objectsToUpdate.add(objct); 
                }                
            }
        }

        MaskJob__c report= new MaskJob__c(
            Object__c=strObject,
            Status__c='Processing',
            Description__c=''
            );
        insert report;

        Database.SaveResult[] SaveResultList = Database.update(objectsToUpdate,false); 
          
        
        //WE GET THE ERRORS FROM THE UPDATE PROCESS
        Boolean isAnyError=false;
        String error='';
        Integer countError=0;
           for (Database.SaveResult sr : SaveResultList) {
                if (sr.isSuccess()) { 
                    System.debug('Successfully updated ' + sr.getId()); 
                } else { 
                    for(Database.Error err : sr.getErrors()) { 
                        countError++;
                        isAnyError=true;

                        if(error.length()>200){
                            error+=' ...';
                            error=error.left(204);  

                        }else{
                            error+=err.getStatusCode() + '; ' + err.getMessage() +';' + err.getFields();
                        }
                        system.debug(error);
                    } 
                } 
            }
            report.Status__c='Completed';

           if(isAnyError==true){          
            report.Status__c='Completed with Errors';
            report.Description__c='Failed errors : ' + countError + ' ' +error;

           }else{
            report.Description__c='Completed Succesfully';
           }
           
           update report;  
    }
       
    global void finish(Database.BatchableContext BC) {

    }
}