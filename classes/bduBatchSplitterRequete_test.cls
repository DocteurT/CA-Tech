@isTest(SeeAllData=true)
public class bduBatchSplitterRequete_test 
{
    public static testMethod void bduBatch_test3()
    {
		String stringDate = '01/01/2015';
		Date refDate = Date.parse( stringDate );

		Test.startTest();
 	    bduBatchSplitterRequete b2 = new bduBatchSplitterRequete( refDate ); 
		System.Schedule('b2', '0 51 09 23 3 ? 2080', b2 );
		Test.stopTest();
    } 
}