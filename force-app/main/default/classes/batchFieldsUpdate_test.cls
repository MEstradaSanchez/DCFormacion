@isTest
public class batchFieldsUpdate_test {
@isTest
    static void testBatch(){
        
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
        
        String object_to_Batch = 'Contact';
        List<String> fields_to_Batch= new List<String>();
        fields_to_Batch.add('Email');

            
        Test.startTest();
        batchFieldsUpdate shn = new batchFieldsUpdate(object_to_Batch, fields_to_Batch, '.texto'); 
        database.executeBatch(shn);

        
        Test.stopTest();
        List<Contact> contacts = [Select id, Email from Contact];
        
        System.assert(contacts[0].Email =='agil@gmail.com.texto', 'Values not changed');
    }
}