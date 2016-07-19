/*-----------------------
String stringDate = '01/01/2014';
bduPreBatch clsCRON = new bduPreBatch( stringDate );
System.Schedule('Traitement des données', '0 0 20 1 1-12 ? *', clsCRON);
------------------------*/

global class bduCalcAbsences implements Database.Batchable<SObject>,Schedulable, Database.Stateful 
{
    public class MyException extends Exception {}
    global Date refDate; 
    global String buUtilises;
    global Decimal horaireMoyenMens_tpsplein;
    global Integer annee_reference;
    global Map<String,String> type_abs_a_considerer; 
    
    class Info_salarie
    {
        ID ident;
        Date debut;
        Date fin;
        String categ;
        String niveau;
        String classe;
        String qualif_det;
        Double tps_trav;
        String contrat;
        String BU1;
        String BU2;
        String BU3;
        String BU4;
        String BU5;
        String sexe;
        Double heure_mens;
    }
    
    global bduCalcAbsences( Date pDate_ref ) 
    {
        refDate = pDate_ref.addDays(-1);
        buUtilises = crta__Param_calc_auto__c.getOrgDefaults().crta__organisation_BU__c;
        horaireMoyenMens_tpsplein = crta__Param_calc_auto__c.getOrgDefaults().Horaire_moyen_mensuel_Temp_plein__c;
        annee_reference = refDate.year();
    }
    
    global Database.QueryLocator start( Database.BatchableContext BC ) 
    {
        String filtre_type_abs = crta__Param_calc_auto__c.getOrgDefaults().types_absence_a_considerer_1__c;
        String filtre_type_abs2 = crta__Param_calc_auto__c.getOrgDefaults().types_absence_a_considerer_2__c;
        String filtre_type_abs3 = crta__Param_calc_auto__c.getOrgDefaults().types_absence_a_considerer_3__c;
        String filtre_type_abs4 = crta__Param_calc_auto__c.getOrgDefaults().types_absence_a_considerer_4__c;
        if ( filtre_type_abs2!=null )
        {
            if ( filtre_type_abs.trim().endsWith(',') )            
                filtre_type_abs = filtre_type_abs + filtre_type_abs2;
            else
                filtre_type_abs = filtre_type_abs + ',' + filtre_type_abs2;
        }
        if ( filtre_type_abs3!=null )
        {
            if ( filtre_type_abs.trim().endsWith(',') )            
                filtre_type_abs = filtre_type_abs + filtre_type_abs3;
            else
                filtre_type_abs = filtre_type_abs + ',' + filtre_type_abs3;
        }
        if ( filtre_type_abs4!=null )
        {
            if ( filtre_type_abs.trim().endsWith(',') )            
                filtre_type_abs = filtre_type_abs + filtre_type_abs4;
            else
                filtre_type_abs = filtre_type_abs + ',' + filtre_type_abs4;
        }
        type_abs_a_considerer = new Map<String,String>();
        for( String type_abs:filtre_type_abs.split(',') )
        {
            if ( type_abs.startsWith('\'') && type_abs.endsWith('\'') )
                type_abs = type_abs.substring(1,type_abs.length()-1);
            type_abs_a_considerer.put( type_abs, type_abs );
        }
        
        String req = 'SELECT crta__CT_Salarie__c,crta__CT_Date_debut__c,crta__CT_Date_fin__c,  crta__Type_d_absence__c, Niveau_a_date__c, Classe_a_date__c,'+
             ' crta__Categorie_professionnelle_a_date__c, crta__Type_de_contrat_a_date__c, crta__BU1_a_date__c, crta__BU2_a_date__c, crta__BU3_a_date__c, crta__BU4_a_date__c, crta__BU5_a_date__c, ' + 
             ' crta__qualification_detaillee_a_date__c, crta__Temps_de_travail_a_date__c ' +  
            ' FROM crta__BDU_Data_Absence__c where crta__CT_Date_debut__c!=null and crta__CT_Date_fin__c!=null and crta__CT_Salarie__r.recordtype.name=\'Salarié\' ';
        if ( Test.isRunningTest() )
            return Database.getQueryLocator( req + ' limit 50' );
        else
            return Database.getQueryLocator( req );
    }
    
    public void traiter_periode( crta__BDU_Data_Absence__c ab, List<Info_salarie> lis, Date d1, Date d2,  Map<String,temp_BDU__c> temp_bdu_map , String mois )
    {
        if ( (ab.crta__CT_Date_debut__c<=d1 && d1<=ab.crta__CT_Date_fin__c ) ||
            (d1<=ab.crta__CT_Date_debut__c&& ab.crta__CT_Date_debut__c<=d2) ||
            (d1<=ab.crta__CT_Date_fin__c && ab.crta__CT_Date_fin__c <=d2) ||
            (ab.crta__CT_Date_debut__c<=d2 && d2<=ab.crta__CT_Date_fin__c )
           )
        {
            //---récupérer categ, type_contrat, BU, ... du salarié quand il était absent
            Info_salarie is =null; 
            for( Info_salarie s1 : lis )
            {
                if ( s1.debut<=ab.crta__CT_Date_debut__c && ab.crta__CT_Date_debut__c<=s1.fin )
                {
                    is = s1;
                    break;
                }
            }
            if ( is==null )
            {
                system.debug('abs non trouvé:'+ ab.crta__CT_Salarie__c +'affectations:'+lis);
                return;
            }
            //---traiter la ligne de données d'absence
            if (type_abs_a_considerer.containsKey(ab.crta__Type_d_absence__c))
            {
                Date debut_abs;
                Date fin_abs;
                String cle = annee_reference + mois + is.categ + is.niveau + is.classe + is.contrat + is.sexe + is.qualif_det;
                
                if ( buUtilises.contains('1') )
                    cle = cle + is.BU1;
                if ( buUtilises.contains('2') )
                    cle = cle + is.BU2; 
                if ( buUtilises.contains('3') )
                    cle = cle + is.BU3;
                if ( buUtilises.contains('4') )
                    cle = cle + is.BU4;
                if ( buUtilises.contains('5') )
                    cle = cle + is.BU5;
                    
                if ( is.heure_mens!=null && is.heure_mens!=0 )
                {
                    Double nb_heures_par_jour = 7*is.heure_mens/horaireMoyenMens_tpsplein; //temps plein de 7h/jours vaut 159.78heures par mois
                    if ( ab.crta__CT_Date_debut__c<d1 )
                        debut_abs = d1;
                    else
                        debut_abs = ab.crta__CT_Date_debut__c;
                    if (ab.crta__CT_Date_fin__c.addDays(1) >d2)
                        fin_abs = d2 ;
                    else
                        fin_abs = ab.crta__CT_Date_fin__c.addDays(1); //car pour une absence d'une journée: date debut=fin 
                    Integer nbjrs = debut_abs.daysBetween( fin_abs );
                    Integer nbSemaines = nbjrs/7; 
                    nbjrs = nbjrs - (2*nbSemaines); //sans compter les samedi et dimanches
                     
                    Temp_bdu__c tmp = temp_bdu_map.get( cle );
                    if ( tmp!=null )
                    {
                        if (tmp.total_heures_absence__c==null)
                            tmp.total_heures_absence__c = 0;
                        tmp.total_heures_absence__c = tmp.total_heures_absence__c + (nbjrs*nb_heures_par_jour);
                    }
                }
            }
            //---mettre dans absence categ, contrat, bu du salarié au moment où il était absent
            if (mois=='Année')
            {
                ab.crta__Categorie_professionnelle_a_date__c = is.categ;
                ab.niveau_a_date__c = is.niveau;
                ab.classe_a_date__c = is.classe;
                ab.crta__Type_de_contrat_a_date__c = is.contrat;
                ab.crta__Temps_de_travail_a_date__c = is.tps_trav;
                ab.crta__qualification_detaillee_a_date__c = is.qualif_det;
                if ( buUtilises.contains('1') )
                    ab.crta__BU1_a_date__c = is.BU1;
                if ( buUtilises.contains('2') )
                    ab.crta__BU2_a_date__c = is.BU2; 
                if ( buUtilises.contains('3') )
                    ab.crta__BU3_a_date__c = is.BU3;
                if ( buUtilises.contains('4') )
                    ab.crta__BU4_a_date__c = is.BU4;
                if ( buUtilises.contains('5') )
                    ab.crta__BU5_a_date__c = is.BU5;
            }
        }
    }
    
    global void execute( Database.BatchableContext BC, List<SObject> scope ) 
    {
        //---salariés concernés
        Set<ID> les_salaries = new Set<ID>();
        for( SObject abs : scope )
        {
            crta__BDU_Data_Absence__c ab = (crta__BDU_Data_Absence__c)abs;      //---préparer la table temp à modifier
            les_salaries.add( ab.crta__CT_Salarie__c );
        }
        String cle;
        Map<String,Temp_BDU__c> temp_bdu_map = new Map<String,temp_BDU__c>();
        for( Temp_BDU__c t : [SELECT Id, 
                Mois__c, 
                Annee__c, BU1__c, BU2__c, BU3__c, BU4__c, BU5__c, 
            Categorie_professionnelle__c, Niveau__c, Classe__c,
            qualification_detaillee__c, 
            Sexe__c, 
            type_de_contrat__c, 
            total_heures_absence__c 
            FROM Temp_BDU__c where Annee__c=:annee_reference] )
        {
            cle = t.annee__c + t.mois__c + t.categorie_professionnelle__c + t.niveau__c + t.classe__c + t.type_de_contrat__c + t.sexe__c + t.qualification_detaillee__c;
            if ( buUtilises.contains('1') )
                cle = cle + t.BU1__c;
            if ( buUtilises.contains('2') )
                cle = cle + t.BU2__c; 
            if ( buUtilises.contains('3') )
                cle = cle + t.BU3__c;
            if ( buUtilises.contains('4') )
                cle = cle + t.BU4__c;
            if ( buUtilises.contains('5') )
                cle = cle + t.BU5__c;
            temp_bdu_map.put( cle,  t );
        }
        
        //---list des employés concernés avec leur categ, contrat,sexe,BU,...
        Date d1 = Date.newInstance( annee_reference, 1, 1 );
        Date d2 = Date.newInstance( annee_reference, 12, 31 );
        Map<ID,List<Info_salarie>> employes =new Map<ID,List<Info_salarie>>();
        for( crta__GS_Affectation_poste__c aff : [Select crta__GS_Salarie__c, crta__GS_Date_de_debut__c, crta__GS_Date_de_fin__c, 
                                                   crta__Categorie_professionnelle__c, crta__CT_Qualifications_d_taill_es__c, crta__Type_de_contrat__c, crta__CT_BU1__c, 
                                                   crta__CT_BU2__c, crta__CT_BU3__c, crta__CT_BU4__c, crta__CT_BU5__c,crta__Temps_de_travail_en_pourcentage__c,
                                                   crta__GS_Salarie__r.crta__Sexe__c, crta__Horaire_moyen_mensuel__c, Niveau__c, Classe__c  
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
            is.niveau = aff.niveau__c;
            is.classe = aff.classe__c;
            is.qualif_det = aff.crta__CT_Qualifications_d_taill_es__c; 
            is.contrat = aff.crta__Type_de_contrat__c;
            is.tps_trav = aff.crta__Temps_de_travail_en_pourcentage__c;
            is.BU1 = aff.crta__CT_BU1__c;
            is.BU2 = aff.crta__CT_BU2__c;
            is.BU3 = aff.crta__CT_BU3__c;
            is.BU4 = aff.crta__CT_BU4__c;
            is.BU5 = aff.crta__CT_BU5__c;
            is.sexe = aff.crta__GS_Salarie__r.crta__Sexe__c;
            is.heure_mens = aff.crta__Horaire_moyen_mensuel__c;
            
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
        for( Integer mois=1; mois<=12; mois++ )
        {
            d1 = Date.newInstance( annee_reference, mois, 1 );
            Integer numberOfDays = Date.daysInMonth( annee_reference, mois );
            d2 = Date.newInstance( annee_reference, mois, numberOfDays );
            
            for( SObject abs : scope )
            {
                crta__BDU_Data_Absence__c ab = (crta__BDU_Data_Absence__c)abs;
                List<Info_salarie> is = employes.get( ab.crta__CT_Salarie__c );
                if ( is!=null )
                {
                    String smois;
                    if (mois<10)
                        smois = '0'+mois;
                    else
                        smois = String.valueof(mois);
                    traiter_periode( ab, is, d1, d2, temp_bdu_map , smois );
                }
                else
                    system.debug('non trouvé:'+ ab.crta__CT_Salarie__c +'debut abs:'+ab.crta__CT_Date_debut__c);
            }
        }
        //---pour l'année à la place de total général
        d1 = Date.newInstance( annee_reference, 1, 1 );
        d2 = Date.newInstance( annee_reference, 12, 31 );
        for( SObject abs : scope )
        {
            crta__BDU_Data_Absence__c ab = (crta__BDU_Data_Absence__c)abs;
            List<Info_salarie> is = employes.get( ab.crta__CT_Salarie__c );
            if (is!=null)
                traiter_periode( ab, is, d1, d2, temp_bdu_map , 'Année');
            else
                system.debug('non trouvé:'+ ab.crta__CT_Salarie__c +'debut abs:'+ab.crta__CT_Date_debut__c);
        }
        
        upsert temp_bdu_map.values();
        update scope;
    }
    
    global void finish( Database.BatchableContext BC ) 
    {
        if (!Test.isRunningTest()) 
        {
            bduCalcRemunerations bat = new bduCalcRemunerations( refDate.addDays(+1) ); 
            Database.executeBatch( bat, 2000 );
        }
    }
    
    global void execute( SchedulableContext c ) 
    {
        Database.executeBatch( this, 2000 );  
    }
}