@isTest
public class MaskEmail_test {
@isTest
    static void maskEmailTest(){
        
        Account accountTest = new Account(
            Name='AccountTest'
        );
        insert accountTest;
        
        List<Account> accountId = [SELECT id from Account WHERE Name='AccountTest'];
        
        Contact contactTest = new Contact(
        LastName='Adria',
        Email='agil@gmail.com',
        AccountId= accountId[0].id
        );
        Contact contactTest2 = new Contact(
        LastName='Adria2',
        Email='agil2@gmail.com',
        AccountId= accountId[0].id
        );
        insert contactTest;
        insert contactTest2;
        
        List<String> fields = new List<String>();
        fields.add('Contact.Email');
        
        Test.startTest();
        Map<String,List<string> > table = MaskEmail.search_value('Email');
        Map<String,List<string> > table2 = MaskEmail.search_value('Phone');
        
        
        String[] returnedValues = MaskEmail.maskFields('.prueba', fields);
       
        Test.stopTest();
        system.assert(table.size()>0, 'Email fields not found');
        system.assert(table2.size()>0, 'Phone fields not found');
        
        List<Contact> contacts = [Select id, Email from Contact];  
        system.debug(contacts[0].Email);
        System.assert(contacts[0].Email =='agil@gmail.com.prueba', 'MaskText not added');
      	System.assert(contacts[1].Email =='agil2@gmail.com.prueba', 'MaskText not added');
        System.assert(returnedValues[0] == 'false', 'The object should not have pending jobs');
		System.assert(returnedValues[1] == '', 'There process should not have any Object with an error for pending jobs');
    }
}