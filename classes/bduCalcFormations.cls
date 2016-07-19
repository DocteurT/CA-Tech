global class bduCalcFormations implements Database.Batchable<SObject>, Schedulable, Database.Stateful 
{
    public class MyException extends Exception {}
    global Date refDate; 
    global String buUtilises; 
    global Integer annee_reference; 
    
    class Info_salarie
    {
        ID ident;
        Date debut;
        Date fin;
        String categ;
        String contrat;
        String qualif_det;
        Double tps_trav;
        String classe;
        String BU1;
        String BU2;
        String BU3;
        String BU4;
        String BU5;
    }
    
    global bduCalcFormations( Date pDate_ref ) 
    {
        refDate = pDate_ref.addDays(-1);
        buUtilises = crta__Param_calc_auto__c.getOrgDefaults().crta__organisation_BU__c;
        annee_reference = refDate.year(); 
    }
    
    global Database.QueryLocator start( Database.BatchableContext BC ) 
    {
        Date d1 = Date.newInstance( annee_reference, 1, 1 );
        Date d2 = Date.newInstance( annee_reference, 12, 31 );
        String sd1 = annee_reference +'-01-01';
        String sd2 = annee_reference +'-12-31';
        String req = 'select id, crta__CT_Candidate__c, crta__CT_Start_date__c, ' + 
             ' crta__Categorie_professionnelle_a_date__c, crta__Type_de_contrat_a_date__c, crta__BU1_a_date__c, crta__BU2_a_date__c, crta__BU3_a_date__c, crta__BU4_a_date__c, crta__BU5_a_date__c, ' + 
             ' crta__qualification_detaillee_a_date__c, crta__Temps_de_travail_a_date__c, Classe_a_date__c ' +  
            ' from crta__Formation__c where crta__CT_Start_date__c>='+sd1+' and crta__CT_Start_date__c<='+sd2+' and crta__CT_Candidate__r.recordtype.name=\'Salarié\''; 
        if ( Test.isRunningTest() )
            return Database.getQueryLocator( req +' limit 50' );
        else
            return Database.getQueryLocator( req );
    }
    
    public void traiter_periode( crta__Formation__c  fo, List<Info_salarie> lis )
    {
        //---récupérer categ, type_contrat, BU, ... du salarié quand il avait l'foident
        Info_salarie is =null; 
        for( Info_salarie s1 : lis )
        {
            if ( s1.debut<=fo.crta__CT_Start_date__c && fo.crta__CT_Start_date__c<=s1.fin )
            {
                is = s1;
                break;
            }
        }
        if ( is==null )
        {
            system.debug('foident non trouvé:'+ fo.crta__CT_Candidate__c +'affectations:'+lis);
            return;
        }
        //---traiter la ligne de données d'foident
        fo.crta__Categorie_professionnelle_a_date__c = is.categ;
        fo.crta__Type_de_contrat_a_date__c = is.contrat;
        fo.crta__Temps_de_travail_a_date__c = is.tps_trav;
        fo.crta__qualification_detaillee_a_date__c = is.qualif_det;
        fo.Classe_a_date__c = is.classe;
        if ( buUtilises.contains('1') )
            fo.crta__BU1_a_date__c = is.BU1;
        if ( buUtilises.contains('2') )
            fo.crta__BU2_a_date__c = is.BU2; 
        if ( buUtilises.contains('3') )
            fo.crta__BU3_a_date__c = is.BU3;
        if ( buUtilises.contains('4') )
            fo.crta__BU4_a_date__c = is.BU4;
        if ( buUtilises.contains('5') )
            fo.crta__BU5_a_date__c = is.BU5;
    }
    
    global void execute( Database.BatchableContext BC, List<SObject> scope ) 
    {
        //---salariés concernés
        Set<ID> les_salaries = new Set<ID>();
        for( SObject fo : scope )
        {
            crta__Formation__c fo1 = (crta__Formation__c)fo;      //---préparer la table temp à modifier
            les_salaries.add( fo1.crta__CT_Candidate__c );
        }

        //---list des employés concernés avec leur categ, contrat,sexe,BU,...
        Date d1 = Date.newInstance( annee_reference, 1, 1 );
        Date d2 = Date.newInstance( annee_reference, 12, 31 );
        Map<ID,List<Info_salarie>> employes =new Map<ID,List<Info_salarie>>();
        for( crta__GS_Affectation_poste__c aff : [Select crta__GS_Salarie__c, crta__GS_Date_de_debut__c, crta__GS_Date_de_fin__c, 
                                                   crta__Categorie_professionnelle__c, crta__Type_de_contrat__c, crta__CT_BU1__c, 
                                                   crta__CT_BU2__c, crta__CT_BU3__c, crta__CT_BU4__c, crta__CT_BU5__c,crta__Temps_de_travail_en_pourcentage__c,crta__CT_Qualifications_d_taill_es__c,
                                                   crta__GS_Salarie__r.crta__Sexe__c, crta__Horaire_moyen_mensuel__c, Classe__c 
                                                  From crta__GS_Affectation_poste__c
                                                  where crta__Stagiaire__c=false and crta__GS_Salarie__c in :les_salaries] )
        {
            Info_salarie is = new Info_salarie();
            is.ident = aff.crta__GS_Salarie__c;
            is.debut = aff.crta__GS_Date_de_debut__c;
            if ( aff.crta__GS_Date_de_fin__c==null )
                 aff.crta__GS_Date_de_fin__c = Date.parse('31/12/2999');
            is.fin = aff.crta__GS_Date_de_fin__c;
            is.categ = aff.crta__Categorie_professionnelle__c;
            is.contrat = aff.crta__Type_de_contrat__c;
            is.qualif_det = aff.crta__CT_Qualifications_d_taill_es__c; 
            is.tps_trav = aff.crta__Temps_de_travail_en_pourcentage__c;
            is.BU1 = aff.crta__CT_BU1__c;
            is.BU2 = aff.crta__CT_BU2__c;
            is.BU3 = aff.crta__CT_BU3__c;
            is.BU4 = aff.crta__CT_BU4__c;
            is.BU5 = aff.crta__CT_BU5__c;
            is.classe = aff.Classe__c;
            
            List<Info_salarie>lst =employes.get( aff.crta__GS_Salarie__c ); 
            if ( lst==null )
            {
                lst = new List<Info_salarie>();
                lst.add(is);
                employes.put( aff.crta__GS_Salarie__c, lst );
            }
            else
            {
                lst.add(is);
            }
        } 
        
        //---clé de recherche: année, mois, bu1, bu2, bu3, bu4, bu5, Categorie_professionnelle__c,type_de_contrat__c
        for( SObject fo : scope )
        {
            crta__Formation__c fo1 = (crta__Formation__c)fo;
            List<Info_salarie> is = employes.get( fo1.crta__CT_Candidate__c );
            if ( is!=null )
                traiter_periode( fo1, is );
            else
                system.debug('non trouvé:'+ fo1.crta__CT_Candidate__c +'debut fo:'+fo1.crta__CT_Start_date__c);
        }
        update scope;
    }
    
    global void finish( Database.BatchableContext BC ) 
    {
        if (!Test.isRunningTest()) 
        {
            bduCalcMedecines bat = new bduCalcMedecines( refDate.addDays(+1) ); 
            Database.executeBatch( bat, 2000 );
        }
    }
    
    global void execute( SchedulableContext c ) 
    {
        Database.executeBatch( this, 2000 );  
    }
}