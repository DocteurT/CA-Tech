/**
 * Class splitting the bduBatch into manageable size inside Salesforce governors limits
 * Database.stateful is used as a counter between batches
 * This class is only called by the bduPreBatch class
 *
 * To manually launch this batch :
  Date date_ref = Date.newInstance(2014,01,01);
  bduBatchSplitter batch = new bduBatchSplitter( date_ref );
  Database.executeBatch( batch, 1 );  
 * 
 * @author Crosstalent
 * @version 2.0
 */
global class bduBatchSplitterRequete implements Database.Batchable<crta.bduBatchParam>,Schedulable, Database.Stateful {
  
    global final Date refDate;
    global Integer scopeCounter; //Database.Stateful: au max 500 reports par heure
    global Integer hourCounter; //Database.Stateful
    global List<crta.bduBatchParam> batchParams; //Database.Stateful 
    global Decimal LIMIT_REPORTS = 250; //Database.Stateful

    /**
     * A specific combinations of Business Units
     */
    public class Node  {
        public String BU1;
        public String BU2;
        public String BU3;
        public String BU4;
        public String BU5;

        public Node( String pBU1, String pBU2, String pBU3, String pBU4, String pBU5 ) { 
            BU1=pBU1; 
            BU2=pBU2; 
            BU3=pBU3; 
            BU4=pBU4; 
            BU5=pBU5; 
        }
    }

    /**
     * A specific period of time
     */
    public class Period {
        public Date startDate;
        public Date endDate;
        public Integer year;
        public Integer semester;
        public Integer quarter;
        public Integer bimestre;
        public Integer month;
        
        public Period( Date pStartDate, Date pEndDate, Integer pYear, Integer pSemester, Integer pQuarter, Integer pBimestre, Integer pMonth ) { 
            startDate=pStartDate; 
            endDate=pEndDate; 
            year=pYear; 
            semester=pSemester;
            quarter=pquarter; 
            bimestre=pBimestre; 
            month=pmonth; 
        }
    }

    global bduBatchSplitterRequete( Date pDate_ref ) 
    {
        LIMIT_REPORTS = [select crta__Reports_limit_calc__c from crta__Param_calc_auto__c ].crta__Reports_limit_calc__c;
        refDate = pDate_ref;
        
        if (Test.isRunningTest())
            LIMIT_REPORTS = 2; 
    }

    global Iterable<crta.bduBatchParam> start( Database.BatchableContext bc )  {
        scopeCounter = 0;
        hourCounter = 1;

        Set<Node> nodes = nodeSearch();
        List<Period> periodList = periodSearch();
        List<crta__BDU_Indicateur__c> indicateurs;
        List<crta.bduBatchParam> pendingParams = new List<crta.bduBatchParam>();

        if (Test.isRunningTest()) {
            indicateurs = [Select Id, crta__CT_isSOQL__c, crta__CT_wantedColumn__c, crta__ct_columnLabels__c, crta__CT_Afficher_le_tableau__c, crta__CT_Afficher_le_graphique__c, crta__CT_Code__c, crta__CT_Annuel__c, crta__CT_Semestriel__c, crta__CT_Trimestriel__c, crta__CT_Bimestriel__c, crta__CT_Mensuel__c, totaux_a_afficher__c,libelles_elements_tableau__c,totaux_via_batch__c From crta__BDU_Indicateur__c limit 50];
        } else {
            indicateurs = [Select Id, crta__CT_isSOQL__c, crta__CT_wantedColumn__c, crta__ct_columnLabels__c, crta__CT_Afficher_le_tableau__c, crta__CT_Afficher_le_graphique__c, crta__CT_Annuel__c, crta__CT_Semestriel__c, crta__CT_Code__c, crta__CT_Trimestriel__c, crta__CT_Bimestriel__c, crta__CT_Mensuel__c, totaux_a_afficher__c,libelles_elements_tableau__c,totaux_via_batch__c From crta__BDU_Indicateur__c
                // where crta__CT_isSOQL__c = true ];
                 //where id='a04w000000OTcUQAA1'];
               //where crta__CT_Code__c in ('IND01115')  
               order by crta__CT_Code__c 
                ]; //-->tout prendre même les indicateurs faits avec des reports
        }
        
        //Loops on all BDU_Indicateur__c, Nodes and period to contruct the needed parameter s to be passed onto the batch
        for( crta__BDU_Indicateur__c indicateur : indicateurs ) 
        {
            if ( indicateur.crta__CT_Code__c != null )
            {
                for( Period p : periodList ) 
                {
                    if ( (indicateur.crta__CT_Annuel__c==true && p.semester==null && p.quarter==null && p.bimestre==null && p.month==null) 
                        || (indicateur.crta__CT_Semestriel__c==true && p.semester!=null) 
                        || (indicateur.crta__CT_Trimestriel__c==true && p.quarter!=null) 
                        || (indicateur.crta__CT_Bimestriel__c==true && p.bimestre!=null) 
                        || (indicateur.crta__CT_Mensuel__c==true && p.month!=null) ) 
                    {
                        pendingParams.add( new crta.bduBatchParam(indicateur, null, null, null, null, null, p.startDate, p.endDate, p.year, p.semester, p.quarter, p.bimestre, p.month) );
                        
                        if (Test.isRunningTest()) 
                        {
                            return pendingParams;
                        }
                        for( Node n : nodes) 
                        {
                            pendingParams.add( new crta.bduBatchParam(indicateur, n.BU1, n.BU2, n.BU3, n.BU4, n.BU5, p.startDate, p.endDate, p.year, p.semester, p.quarter, p.bimestre, p.month) );

                            if (Test.isRunningTest() && pendingParams.size()>50) 
                            {
                                return pendingParams; 
                            }
                        }
                    }
                }
            }
        }

        batchParams = new List<crta.bduBatchParam>();
        return pendingParams; 
    }

    /**
     * Launches the batches with the previously calculated parameters and within Salesforce governors limits (i.e. 500 reports/hour max)
     * @param  Database.BatchableContext info
     * @param  List<crta.bduBatchParam>       scope         List of the parameters to process in the batch
     */
    global void execute( Database.BatchableContext info, List<crta.bduBatchParam> scope ) 
    {
        for( crta.bduBatchParam currentParam : scope ) 
        {
                scopeCounter++;
                if(scopeCounter <= LIMIT_REPORTS) 
                {
                    //Remove existing values
                    List<crta__BDU_Valeur__c> delList = [Select id From crta__BDU_Valeur__c Where crta__CT_BDU_Indicateur__c = :currentParam.indi.id and crta__CT_BU1__c = :currentParam.BU1 and crta__CT_BU2__c = :currentParam.BU2 and crta__CT_BU3__c = :currentParam.BU3 and crta__CT_BU4__c = :currentParam.BU4 and crta__CT_BU5__c = :currentParam.BU5 and crta__CT_Annee__c = :String.valueOf(currentParam.year) and crta__CT_semestre__c = :String.valueOf(currentParam.semester) and crta__CT_Trimestre__c = :String.valueOf(currentParam.quarter) and crta__CT_Bimestre__c = :String.valueOf(currentParam.bimestre) and crta__CT_Mois__c = :String.valueOf(currentParam.month)]; 
                    delete delList;
                    //Starts batch for the current parameters
                    /*
                    global static void processReport( 
                        String code, String indicId, 
                        String BU1, String BU2, String BU3, String BU4, String BU5, 
                        Date startDate, Date endDate, 
                        Integer year, Integer semester, Integer quarter, Integer bimestre, Integer month, 
                        Boolean isSOQL, String aff_totaux, Boolean libelles_elements_tableau, Boolean totaux_via_batch)
                    */   
                    bduValuesCalcRequete.processReport( 
                        currentParam.indi.crta__CT_Code__c, 
                        currentParam.indi.Id, 
                        currentParam.BU1, currentParam.BU2, currentParam.BU3, currentParam.BU4, currentParam.BU5, 
                        currentParam.startDate, currentParam.endDate, 
                        currentParam.year, 
                        currentParam.semester, currentParam.quarter, currentParam.bimestre, currentParam.month,
                        currentParam.indi.crta__CT_isSOQL__c,
                        currentParam.indi.totaux_a_afficher__c,currentParam.indi.libelles_elements_tableau__c, currentParam.indi.totaux_via_batch__c );
                } 
                else 
                {
                    batchParams.add( currentParam );
                    if ( batchParams.size() >= LIMIT_REPORTS ) 
                    {
                        DateTime nextBatch = DateTime.now().addHours(hourCounter);
                        /*
                        if(hourCounter == 0) { //Initial batch
                            nextBatch = DateTime.now().addMinutes(10);
                        }
                        */
                        if (!Test.isRunningTest())
                        {
                            system.debug('lancement suite 500');
                            bduBatchRequete clsCRON = new bduBatchRequete( batchParams );
                            System.Schedule('Calcul automatique des BDU_valeur__c'+nextBatch.format(), 
                            '0 '+nextBatch.minute()+' '+nextBatch.hour()+' '+nextBatch.day()+' '+ nextBatch.month()+' ? '+nextBatch.year(), clsCRON);
                        }   
                        batchParams = new List<crta.bduBatchParam>(); //Resetting batchParams for the next batch
                        hourCounter++; //Next batch in the next hour
                    }
                }
        }
    }

    /**
     * Launches a new batch the following hour if there are batch parameters still in the queue
     * @param  Database.BatchableContext BC
     */
    global void finish(Database.BatchableContext BC) 
    {
        
        if ( !Test.isRunningTest() && batchParams!=null && batchParams.size()>0 )
        {
            DateTime nextBatch = DateTime.now().addHours(hourCounter);
            bduBatchRequete clsCRON = new bduBatchRequete( batchParams );
            System.Schedule('Calcul automatique des BDU_valeur__c '+nextBatch.format(), 
            '0 '+nextBatch.minute()+' '+nextBatch.hour()+' '+nextBatch.day()+' '+ nextBatch.month()+' ? '+nextBatch.year(), clsCRON);
        }
    }

    /**
     * Search all the possible nodes for the setting specified Business Units
     * @return Set<Node> Set of the unique nodes found
     */
    private Set<Node> nodeSearch() {
        Set<Node> nodes = new Set<Node>();

        //We only look at the specified Business Units
        String buOptions = crta__Param_calc_auto__c.getOrgDefaults().crta__organisation_BU__c;
        String col = ''; 
        List<String> selectedBUs = buOptions.split(';'); 
        Map<String,String> buMap  = new Map<String,String>{
            '1'=>'crta__CT_BU1__c',
            '2'=>'crta__CT_BU2__c',
            '3'=>'crta__CT_BU3__c',
            '4'=>'crta__CT_BU4__c',
            '5'=>'crta__CT_BU5__c'
        }; 

        //Creating select condition for future soql request
        for( String selectedBU : selectedBUs ) {
            if (col=='') {
                col = buMap.get( selectedBU ) ;
            }
            else {
                col = col + ',' + buMap.get( selectedBU );
            }
        }
        
        String soql1 = 'Select '+String.escapeSingleQuotes(col)+' From crta__GS_Affectation_poste__c Group By '+String.escapeSingleQuotes(col);
        for( aggregateResult res : Database.query(soql1) ) 
        {
            String sBU1;
            String sBU2;
            String sBU3;
            String sBU4;
            String sBU5;
            for( String selectedBU : selectedBUs ) 
            {
                Boolean nouv_bu_trouve = false;
                if ( selectedBU.trim() == '1' ) 
                {
                    sBU1 = String.valueOf( res.get( buMap.get(selectedBU) ) );
                    nouv_bu_trouve = true;
                } 
                else if ( selectedBU.trim() == '2' ) 
                {
                    sBU2 = String.valueOf( res.get( buMap.get(selectedBU) ) );
                    nouv_bu_trouve = true;
                } 
                else if ( selectedBU.trim() == '3' ) 
                {
                    sBU3 = String.valueOf( res.get( buMap.get(selectedBU) ) );
                    nouv_bu_trouve = true;
                } 
                else if ( selectedBU.trim() == '4' ) 
                {
                    sBU4 = String.valueOf( res.get( buMap.get(selectedBU) ) );
                    nouv_bu_trouve = true;
                } 
                else if ( selectedBU.trim() == '5' ) 
                {
                    sBU5 = String.valueOf( res.get( buMap.get(selectedBU) ) );
                    nouv_bu_trouve = true;
                }
                if ( nouv_bu_trouve )
                    nodes.add(new Node( sBU1, sBU2, sBU3, sBU4, sBU5 ) );
            }
        }
        return nodes;
    }

    /**
     * Searches all the possible periods
    * @return List<Period> All found periods
     */
    public List<Period> periodSearch() {
        List<Period> periodList = new List<Period>(); 

        if ( Test.isRunningTest() || refDate.month()==1 ) 
        {
            //---pour 01/01/2014 => annuel: 01/01/2013 - 31/12/2013
            periodList.add(new Period( Date.newInstance(refDate.year()-1,1,1), refDate.addDays( -1 ), 
            refDate.year()-1, null, null, null, null));
            //---pour 01/01/2014 => 2eme semestre 2013: 01/07/2013 - 31/12/2013
            periodList.add(new Period( Date.newInstance(refDate.year()-1,07,1), refDate.addDays( -1 ), 
            refDate.year()-1, 2, null, null, null));
            //---pour 01/01/2014 => 4eme trimestre 2013: 01/10/2013 - 31/12/2013
            periodList.add(new Period( Date.newInstance(refDate.year()-1,10,1), refDate.addDays( -1 ), 
            refDate.year()-1, null, 4, null, null));
            //---pour 01/01/2014 => 6eme bimestre 2013: 01/11/2013 - 31/12/2013
            periodList.add(new Period( Date.newInstance(refDate.year()-1,11,01), refDate.addDays( -1 ), 
            refDate.year()-1, null, null, 6, null));
            //---pour 01/01/2014 => mensuel ann?e pr?c?dente
            periodList.add(new Period( Date.newInstance(refDate.year()-1,12,01), refDate.addDays( -1 ), 
            refDate.year()-1, null, null, null, 12));
        } 
        if ( Test.isRunningTest() || refDate.month()==3 ) 
        {
            //---pour 01/03/2014 => 1er bimestre 2014: 01/01/2014 - 28/02/2014 (ann?e biscextile ? voir)
            periodList.add(new Period( Date.newInstance(refDate.year(),01,01), refDate.addDays( -1 ), 
            refDate.year(), null, null, 1, null));
            //--- mensuel
            periodList.add(new Period( Date.newInstance(refDate.year(),refDate.month()-1,01), refDate.addDays( -1 ), 
            refDate.year(), null, null, null, refDate.month()-1));
        } 
        if ( Test.isRunningTest() || refDate.month()==4 ) 
        {
            //---pour 01/04/2014 => 1er trimestre 2014: 01/01/2014 - 31/03/2014
            periodList.add(new Period(
            Date.newInstance(refDate.year(),01,01), refDate.addDays( -1 ), 
            refDate.year(), null, 1, null, null));
            //--- mensuel
            periodList.add(new Period( Date.newInstance(refDate.year(),refDate.month()-1,01), refDate.addDays( -1 ), 
            refDate.year(), null, null, null, refDate.month()-1));
        } 
        if ( Test.isRunningTest() || refDate.month()==5 ) 
        {
            //---pour 01/05/2014 => 2eme bimestre 2014: 01/03/2014 - 30/04/2014
            periodList.add(new Period( Date.newInstance(refDate.year(),03,01), refDate.addDays( -1 ), 
            refDate.year(), null, null, 2, null));
            //--- mensuel
            periodList.add(new Period( Date.newInstance(refDate.year(),refDate.month()-1,01), refDate.addDays( -1 ), 
            refDate.year(), null, null, null, refDate.month()-1));
        } 
        if ( Test.isRunningTest() || refDate.month()==7 ) 
        {
            //---pour 01/07/2014 => 1er semestre 2014: 01/01/2014 - 30/06/2014
            periodList.add(new Period( Date.newInstance(refDate.year(),1,1), refDate.addDays( -1 ), 
            refDate.year(), 1, null, null, null));
            //---pour 01/07/2014 => 2eme trimestre 2014: 01/04/2014 - 30/06/2014
            periodList.add(new Period( Date.newInstance(refDate.year(),04,01), refDate.addDays( -1 ), 
            refDate.year(), null, 2, null, null));
            //---pour 01/07/2014 => 3eme bimestre 2014: 01/05/2014 - 30/06/2014
            periodList.add(new Period( Date.newInstance(refDate.year(),05,01), refDate.addDays( -1 ), 
            refDate.year(), null, null, 3, null));
            //--- mensuel
            periodList.add(new Period( Date.newInstance(refDate.year(),refDate.month()-1,01), refDate.addDays( -1 ), 
            refDate.year(), null, null, null, refDate.month()-1));
        } 
        if ( Test.isRunningTest() || refDate.month()==9 ) 
        {
            //---pour 01/09/2014 => 4eme bimestre 2014: 01/07/2014 - 31/08/2014
            periodList.add(new Period( Date.newInstance(refDate.year(),07,01), refDate.addDays( -1 ), 
            refDate.year(), null, null, 4, null));
            //--- mensuel
            periodList.add(new Period( Date.newInstance(refDate.year(),refDate.month()-1,01), refDate.addDays( -1 ), 
            refDate.year(), null, null, null, refDate.month()-1));
        } 
        if ( Test.isRunningTest() || refDate.month()==10 ) 
        {
            //---pour 01/10/2014 => 3eme trimestre 2014: 01/07/2014 - 30/09/2014
            periodList.add(new Period( Date.newInstance(refDate.year(),07,01), refDate.addDays( -1 ), 
            refDate.year(), null, 3, null, null));
            //--- mensuel
            periodList.add(new Period( Date.newInstance(refDate.year(),refDate.month()-1,01), refDate.addDays( -1 ),
            refDate.year(), null, null, null, refDate.month()-1));
        } 
        if ( Test.isRunningTest() || refDate.month()==11 ) 
        {
            //---pour 01/11/2014 => 5eme bimestre 2014: 01/09/2014 - 31/10/2014
            periodList.add(new Period( Date.newInstance(refDate.year(),09,01), refDate.addDays( -1 ), 
            refDate.year(), null, null, 5, null));
            //--- mensuel
            periodList.add(new Period( Date.newInstance(refDate.year(),refDate.month()-1,01), refDate.addDays( -1 ),
            refDate.year(), null, null, null, refDate.month()-1));
        } 
        else 
        {
            //--- mensuel
            periodList.add(new Period( Date.newInstance(refDate.year(),refDate.month()-1,01), refDate.addDays( -1 ), 
            refDate.year(), null, null, null, refDate.month()-1));
        }

        return periodList;
    }
    global void execute( SchedulableContext c ) {
        Database.executeBatch( this, 1 ); // un report à la fois
    }
}