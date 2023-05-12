import { LightningElement,track,wire} from 'lwc';
import getObjectsWithEmail from'@salesforce/apex/MaskEmail.search_value';
import insertMaskFields from'@salesforce/apex/MaskEmail.maskFields';
import {exportCSVFile} from 'c/utils'

export default class LWC_seleccion extends LightningElement {
    readyPrefix=false;
    readySearch = false;
    searchType;
    selectedOption;
    selectAll=false;   
    selectedFields = [];

    options = [
        {'label': 'Email', 'value': 'email'},
        {'label': 'Phone', 'value': 'phone'},
    ];

    //SELECT OPTION RADIO BUTTON
    handleChange(event) {
        const selectedOption2 = event.detail.value;
        console.log('Option selected with value: ' + selectedOption2);
        this.selectedOption = event.detail.value;

        if(selectedOption2 == 'email'){
            this.readyPrefix=true;
        }
    }

    downloadData= [];
    data={};

    //SELECT ALL THE FIELDS
    handleSelectAll(event){
        this.downloadData=[];
        this.selectedFields=[];
        if(this.selectAll==true){
            this.selectAll=false;
            this.template.querySelectorAll('.field').forEach(element => {
                
                element.checked = false;

                for(let i=0; i<this.selectedFields.length;i++){
                    if(this.selectedFields[i]==this.objectAndFields){
                        this.selectedFields.splice(i, 1);
                        this.downloadData.splice(i,1);
                    }  
                }               
            });
            console.log('SELECTED FIELDS  -  REMOVE ALL = ' + this.selectedFields);
        }else{
            this.selectAll=true;            
            this.template.querySelectorAll('.field').forEach(element => {
               
            element.checked = true;
          //  console.log('OBJECT/FIELD = '+ element.value + '.' + element.label);
            this.objectAndFields = element.value + '.' + element.label;
            this.selectedFields.push(this.objectAndFields);
           
            this.data={object: element.value, fieldName: element.label};
            this.downloadData.push(this.data);
      
            });
            console.log('SELECTED FIELDS - ADD ALL = ' + this.selectedFields);      
        }  
    }

    //SELECT FUNCTION FROM INDIVIDUAL CHECKBOXS 
    handleSelected(event){
        if(event.target.checked==true){
            this.objectAndFields = event.target.value + '.' + event.target.label;
            this.selectedFields.push(this.objectAndFields);
            
            console.log('SELECTED FIELDS  - ADD = ' + this.selectedFields);

            this.data={object: event.target.value, fieldName: event.target.label};
            this.downloadData.push(this.data);
        }
        else{
            
            for(let i=0; i<this.selectedFields.length;i++){
                if(this.selectedFields[i]==this.objectAndFields){
                    this.selectedFields.splice(i, 1);
                    this.downloadData.splice(i,1);
                }  
            }            
            console.log('SELECTED FIELDS  -  REMOVE = ' + this.selectedFields);
        }    
    }
    
    headers = {
        object:"Object",
        fieldName:"FieldName",
    }

    //BUTTON DOWNLOAD
    handleDownload(event){
        if(this.selectedFields.length>0){
            exportCSVFile(this.headers, this.downloadData, "FieldNames_And_Objects")
        }else{
            window.alert('No data available to Download');
        }
       
    }

    //BUTTON SEARCH
    handleLoad(event){
        this.objWithEmailOrPhone=[];
        this.downloadData=[];
        this.selectedFields=[];
        this.selectAll=false;

        if(this.selectedOption =='email'){
            window.clearTimeout(this.delayTimeout);const searchType = 'email'; this.delayTimeout = setTimeout(() => {this.searchType = searchType;}, 200);  
            this.readySearch=true;
        }
        if(this.selectedOption=='phone'){
            window.clearTimeout(this.delayTimeout);const searchType = 'phone'; this.delayTimeout = setTimeout(() => {this.searchType = searchType;}, 200);
            this.readySearch=true;
        }

    }
    //USE APEX METHOD TO SEARCH AND STORE VALUES
    @track objWithEmailOrPhone=[];
	@wire(getObjectsWithEmail,{type : '$searchType'})
    getResults(result){

    if(result.data){
        console.log('Loaded data');
        for(var key in result.data){
        this.objWithEmailOrPhone.push({key:key,value:result.data[key]});
        }
    
     }
    }

    //MASK FIELDS

   @track emailPrefixInputValue;
   
    nameChange(event) {
    this.emailPrefixInputValue= event.target.value;
    }
    handleMask(){
        
        if(this.selectedFields.length>0 ){
            if(this.emailPrefixInputValue!=undefined && this.emailPrefixInputValue!=''){
               // console.log('MASKING VALUE' + this.emailPrefixInputValue);
                
            insertMaskFields({ MaskText: this.emailPrefixInputValue, fields: this.selectedFields })
            .then((result) => {
                console.log('anyQUEUE value' + result[0]);

                if(result[0]=='true'){
                    window.alert('There is a job processing for this objects: ' + result[1]);
                    console.log('There is a job for this object processing in queue');
                }else{
                    window.alert('Update Field Job created for the Object ' + result[1])
                    console.log('The records have been updated');
                }
                //we use the method select all true to remove the data once masked is done
                this.selectAll=true;
                this.handleSelectAll();
                
            })
            .catch((error) => {
                console.log('Error changing values');
            });
              //  console.log(this.selectedFields);
            }else{
                window.alert('No masking text defined')
            }
        }else{
            window.alert('No fields selected to Mask');
        }
       

    }

}