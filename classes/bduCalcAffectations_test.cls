@isTest(SeeAllData=true)
public class bduCalcAffectations_test 
{
    public static testMethod void bduBatch_test()
    {
        String stringDate = '01/01/2015';
        Date refDate = Date.parse( stringDate );
        
        Test.startTest();
        
        BduCalcAffectations b1 = new BduCalcAffectations( refDate ); 
        System.Schedule('b1', '0 51 09 23 3 ? 2080', b1 );

        Test.stopTest();
    } 
}