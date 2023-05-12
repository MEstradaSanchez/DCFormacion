/**
* @author Adria Gil Sole
* @date 2021
*
* @description This class contains methods for the MaskEmail Lightning Web Component usage
*/

public with sharing class MaskEmail {
    @AuraEnabled (cacheable=true)

     /*******************************************************************************************************
    * @description Method to get all the fields from the type object defined
    * @param type String that contains the type of the object to search (email or phone)
    * @return returns a Map<String,List<string> with the ObjectNames and their FieldNames for the object defined in the parameter
    */
    public static Map<String,List<string> > search_value (String type){
        
        Map<String,List<string> > table = new Map<String,List<string>>();  
        Map<String, Schema.SObjectType > globalDescription = Schema.getGlobalDescribe();   
        Set <String> listsObjs = new Set <String>();     
        
        //GET ALL OBJECTS
        for(Schema.SObjectType objTyp : Schema.getGlobalDescribe().Values()){
            String name = objTyp.getDescribe().getName();
            String label = objTyp.getDescribe().getLabel();
            if(!name.containsignorecase('history') && !name.containsignorecase('tag') &&
               !name.containsignorecase('share') && !name.containsignorecase('feed') && 
               !name.containsignorecase('group') && !name.containsignorecase('public') &&
               !objTyp.getDescribe().isCustomSetting() && objTyp.getDescribe().isCreateable() &&
               objTyp.getDescribe().getRecordTypeInfos().size() > 0){      
                   listsObjs.add(name);
               }
        }
        //GET ALL FIELD OBJECTS FOR THE TYPE DEFINED	    
        for ( String obj : listsObjs ) {  
            List<String> fields = new List<String>(); 
            Schema.sObjectType objType = globalDescription.get( obj );  
            Schema.DescribeSObjectResult r1 = objType.getDescribe();   
            Map<String , Schema.SObjectField > mapFieldList = r1.fields.getMap();    
            
            for ( Schema.SObjectField field : mapFieldList.values() ) {    
                
                Schema.DescribeFieldResult fieldResult = field.getDescribe();    
                String fieldLabel = fieldResult.getLabel().toLowerCase();  
                Schema.DisplayType fielddataType = fieldResult.getType();  
                
                if(type=='email'){
                    
                    if ( fielddataType == Schema.DisplayType.Email && ! fieldResult.isCalculated() ) {  
                        
                        fields.add(fieldResult.getName());
                        table.put( String.valueOf(objType), fields);
                        System.debug('OBJECT/FIELD WITH EMAIL TYPE: ' + objType + '.' + fieldResult.getName() );  
                        
                    }
                }
                if(type=='phone'){
                    
                    if ( fielddataType == Schema.DisplayType.Phone && ! fieldResult.isCalculated() ) {  
                        
                        fields.add(fieldResult.getName());
                        table.put( String.valueOf(objType), fields);
                        System.debug('OBJECT/FIELD WITH PHONE TYPE: ' + objType + '.' + fieldResult.getName() );                       
                    }
                }      
            }  
            
        }  
        System.debug(table);
        return table;
    }
    
    /*******************************************************************************************************
    * @description Method to add a mask text to all the object fields passed, creating a batch job for every object. 
    * It also searches if there is any pending job for the object
    * @param MaskText String that contains the MaskText that will be added into the field
    * @param fields A List<String> that contains the Object and Field separated by a '.'
    * @return returns a String[] with two values: The string[0] defines if there is anyQueue for this object already and pass the value true/false. 
    * The String[1] passes the value of the Objects that have a Job Pending 
    */ 
    @AuraEnabled
    public static String[] maskFields(String MaskText, List<String> fields){

        String anyQueue='false';
        String objectsError='';
        String[] returnedValues= new String[2];
        //WE GET THE MASKTEXT AND THE FIELDS IN FORMAT (Contact.Email) FROM THE .JS
        List<String> objectsAndField = fields;
        String beforeObj = '';
        List<String> fieldsToAdd  = new List<String>();

        //we create a map to asign the object with a list of fields
        Map<String, List<String>> mapObjects = new Map<String, List<String>>();

        for(String objectAndField : objectsAndField){
            
            String obj = objectAndField.substringBefore('.');
            String field = objectAndField.substringAfter(obj + '.');
            
            if(beforeObj == obj || beforeObj == ''){
                fieldsToAdd.add(field);
            }else{
                mapObjects.put(beforeObj, new List<String>(fieldsToAdd));
                fieldsToAdd.clear();
                fieldsToAdd.add(field);
            }

            beforeObj=obj;
        }
        mapObjects.put(beforeObj, new List<String>(fieldsToAdd));
        system.debug(mapObjects);
        
        //FOR ALL THE OBJECTS IN THE MAP CREATE A BATCH passing the fields in a List format
        for(String objc : mapObjects.keySet()){
        
        String object_to_Batch = objc;
        List<String> fields_to_Batch= mapObjects.get(objc);
        List<sObject> PendingJobs=jobsWorking(object_to_Batch);
      //if there is a  pending job for this object, an error msg appears on the JS screen
        if(PendingJobs.size()>0){
            system.debug('JOBS PENDING' + PendingJobs.size());
            anyQueue='true';
            objectsError+=object_to_Batch + ' ';
        }else{
            batchFieldsUpdate shn = new batchFieldsUpdate(object_to_Batch, fields_to_Batch, MaskText); 
            database.executeBatch(shn);
        }
        }
        returnedValues[0]=anyQueue;
        returnedValues[1]=objectsError;

        return returnedValues;
    }

      /*******************************************************************************************************
    * @description Method to search in MaskJob__c object if there are pending jobs for the object we want 
    * and with Status "Processing". 
    * @param obj String that contains the name of the Object to search
    * @return returns a List<sObject> of the pending jobs for the Object 
    */ 
    public static List<sObject> jobsWorking(String obj){
        String pr='Processing';
        String query= 'SELECT Id FROM MaskJob__c WHERE Object__c = \'' + obj + '\' AND Status__c = \'' + pr+'\'';
        List<sObject> obj_Working = Database.query(query);
        system.debug('LIST OF JOBS PENDING' + obj_Working);
        return obj_Working;
    }
    
}