/**
 * Schedulable class creating the new BDU_Valeur__c for the given parameters
 *
 * @author Crosstalent
 * @version 1.1
 */
global class bduBatchRequete implements Database.Batchable<crta.bduBatchParam>, Schedulable {
    global List<crta.bduBatchParam> pendingParams;

    global bduBatchRequete( List<crta.bduBatchParam> batchParams ) 
    {
        pendingParams = batchParams;
    }
    
    global Iterable<crta.bduBatchParam> start( Database.BatchableContext bc )  
    {
        return pendingParams;
    } 

    /**
     * Executes bduBatchRequete for the given parameters
     * @param  Database.BatchableContext info
     * @param  List<crta.bduBatchParam>       scope         List of parameters to process
     */
    global void execute( Database.BatchableContext info, List<crta.bduBatchParam> scope ) 
    {
        for( crta.bduBatchParam currentParam : scope ) 
        {
            //Remove existing values
            List<crta__BDU_Valeur__c> delList = [Select id From crta__BDU_Valeur__c 
                Where crta__CT_BDU_Indicateur__c = :currentParam.indi.id 
                    and crta__CT_BU1__c = :currentParam.BU1 
                    and crta__CT_BU2__c = :currentParam.BU2 
                    and crta__CT_BU3__c = :currentParam.BU3 
                    and crta__CT_BU4__c = :currentParam.BU4 
                    and crta__CT_BU5__c = :currentParam.BU5 
                    and crta__CT_Annee__c = :String.valueOf(currentParam.year) 
                    and crta__CT_semestre__c = :String.valueOf(currentParam.semester) 
                    and crta__CT_Trimestre__c = :String.valueOf(currentParam.quarter) 
                    and crta__CT_Bimestre__c = :String.valueOf(currentParam.bimestre) 
                    and crta__CT_Mois__c = :String.valueOf(currentParam.month)]; 
            delete delList;
            
            /*
		    global static void processReport( 
		        String code, String indicId, 
		        String BU1, String BU2, String BU3, String BU4, String BU5, 
		        Date startDate, Date endDate, 
		        Integer year, Integer semester, Integer quarter, Integer bimestre, Integer month, 
		        Boolean isSOQL, String aff_totaux, Boolean libelles_elements_tableau, Boolean totaux_via_batch)
		    */   
            //Starts batch for the current parameters
            bduValuesCalcRequete.processReport( 
                currentParam.indi.crta__CT_Code__c, 
                currentParam.indi.Id, 
                currentParam.BU1, currentParam.BU2, currentParam.BU3, currentParam.BU4, currentParam.BU5, 
                currentParam.startDate, currentParam.endDate, 
                currentParam.year, 
                currentParam.semester, currentParam.quarter, currentParam.bimestre, currentParam.month,
                currentParam.indi.crta__CT_isSOQL__c,
                currentParam.indi.totaux_a_afficher__c, currentParam.indi.libelles_elements_tableau__c, currentParam.indi.totaux_via_batch__c );
        }
    }

    global void finish( Database.BatchableContext BC ) {
        //System.abortJob(this.id); idée à explorer 
    }

    global void execute( SchedulableContext c ) {
        Database.executeBatch( this, 1 ); // un report à la fois
    }
}