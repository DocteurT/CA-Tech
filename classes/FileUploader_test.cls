@isTest
public class FileUploader_test 
{
    static testMethod void lancer_test()
    {
        
        FileUploader f = new FileUploader();
        f.contentFile = Blob.valueOf('NOM,RUE,VILLE,REGION,CODE POSTAL,PAYS\nTEST,Pasquier,Paris 8eme,IDF,75008,FRANCE\n');
        Pagereference pr = f.ReadFile();
        List<Account> lst = f.getuploadedAccounts();
    }
}