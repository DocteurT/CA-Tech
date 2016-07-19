/* 
lancement direct du batch:
----------------------------
List<temp_BDU__c> lst;
do
{
    lst = [select id from temp_BDU__c where Annee__c=2014 limit 10000];
    delete lst;
} while (lst.size()>0);

List<Table_temporaire_2_BDU__c> lst2;
do
{
    lst2 = [select id from Table_temporaire_2_BDU__c where Annee__c=2014 limit 10000];
    delete lst2;
} while (lst2.size()>0);

String stringDate = '01/01/2015';
Date refDate = Date.parse( stringDate );
BduCalcAffectations calc = new BduCalcAffectations( refDate );
Database.executeBatch( calc, 2000 );
------------------------*/

global class BduCalcAffectations implements Database.Batchable<SObject>,Schedulable, Database.Stateful 
{
    public class MyException extends Exception {}
    global Date refDate; 
    global String buUtilises; 
    global Integer annee_reference; 
    global Map<String, String>embauches;  
    global Map<String, String>partis;  
    global Map<String, String>embauches_pour_annee;  
    global Map<String, String>partis_pour_annee;  
    global Map<String,Map<String, String>> details;
    
    global bduCalcAffectations( Date pDate_ref ) 
    {
        refDate = pDate_ref.addDays(-1);
        buUtilises = crta__Param_calc_auto__c.getOrgDefaults().crta__organisation_BU__c;
        annee_reference = refDate.year(); 
        embauches = new Map<String, String>(); 
        partis = new Map<String, String>();  
        embauches_pour_annee = new Map<String, String>(); 
        partis_pour_annee = new Map<String, String>();  
        details = new Map<String,Map<String, String>>();
    }
    
    global Database.QueryLocator start( Database.BatchableContext BC ) 
    {
        List<temp_BDU__c> lst;
        do
        {
            lst = [select id from temp_BDU__c where Annee__c=2013 limit 10000];
            delete lst;
        } while (lst.size()>0);
        
        List<Table_temporaire_2_BDU__c> lst2;
        do
        {
            lst2 = [select id from Table_temporaire_2_BDU__c where Annee__c=2013 limit 10000];
            delete lst2;
        } while (lst2.size()>0);

        //order by important pour trouver nb "embauche"
        if ( Test.isRunningTest() )
            return Database.getQueryLocator(
                'Select crta__GS_Salarie__c,crta__Categorie_professionnelle__c, crta__Type_de_contrat__c,crta__CT_BU1__c, crta__CT_BU2__c, crta__CT_BU3__c, crta__CT_BU4__c, crta__CT_BU5__c, ' +
                'crta__GS_Salarie__r.crta__Sexe__c,crta__GS_Salarie__r.birthdate,crta__GS_Date_de_debut__c,crta__GS_Date_de_fin__c,crta__GS_Salarie__r.crta__CT_Date_of_entry_to_the_society__c, ' +
                'crta__GS_Salarie__r.crta__CT_Date_fin_dernier_contrat_en_cours__c,crta__Horaire_moyen_mensuel__c '+
                ' From crta__GS_Affectation_poste__c '+
                ' where crta__Type_de_contrat__c!=\'STAO\' and crta__Categorie_professionnelle__c!=null and crta__Type_de_contrat__c!=null and crta__GS_Salarie__r.crta__sexe__c!=null ' +
                ' and crta__GS_Salarie__r.birthdate!=null and crta__GS_Salarie__r.crta__CT_Date_of_entry_to_the_society__c!=null' +
                ' order by crta__GS_Salarie__c asc, crta__GS_Date_de_fin__c desc limit 50');
        else
            return Database.getQueryLocator(
                'Select crta__GS_Salarie__c,crta__Categorie_professionnelle__c, crta__Type_de_contrat__c,crta__CT_BU1__c, crta__CT_BU2__c, crta__CT_BU3__c, crta__CT_BU4__c, crta__CT_BU5__c, ' +
                'crta__GS_Salarie__r.crta__Sexe__c,crta__GS_Salarie__r.birthdate,crta__GS_Date_de_debut__c,crta__GS_Date_de_fin__c,crta__GS_Salarie__r.crta__CT_Date_of_entry_to_the_society__c, ' +
                'crta__GS_Salarie__r.crta__CT_Date_fin_dernier_contrat_en_cours__c,crta__Horaire_moyen_mensuel__c '+
                ' From crta__GS_Affectation_poste__c '+
                ' where crta__Type_de_contrat__c!=\'STAO\' and crta__Categorie_professionnelle__c!=null and crta__Type_de_contrat__c!=null and crta__GS_Salarie__r.crta__sexe__c!=null ' +
                ' and crta__GS_Salarie__r.birthdate!=null and crta__GS_Salarie__r.crta__CT_Date_of_entry_to_the_society__c!=null' +
                ' order by crta__GS_Salarie__c asc, crta__GS_Date_de_fin__c desc'
                );
    }
    
    global void traiter_periode( crta__GS_Affectation_poste__c af, Date d1, Date d2,  Map<String,temp_BDU__c> temp_bdu_map , String mois, List<details_calcul__c> details_calcul )
    {
        if ( (af.crta__GS_Date_de_debut__c<=d1 && d1<=af.crta__GS_Date_de_fin__c) ||
            (d1<=af.crta__GS_Date_de_debut__c && af.crta__GS_Date_de_debut__c<=d2) ||
            (d1<=af.crta__GS_Date_de_fin__c && af.crta__GS_Date_de_fin__c<=d2) ||
            (af.crta__GS_Date_de_debut__c<=d2 && d2<=af.crta__GS_Date_de_fin__c)
           )
        {
            String cle = annee_reference + mois + af.crta__Categorie_professionnelle__c +af.crta__Type_de_contrat__c+af.crta__GS_Salarie__r.crta__Sexe__c;
            if ( buUtilises.contains('1') )
                cle = cle + af.crta__CT_BU1__c;
            if ( buUtilises.contains('2') )
                cle = cle + af.crta__CT_BU2__c; 
            if ( buUtilises.contains('3') )
                cle = cle + af.crta__CT_BU3__c;
            if ( buUtilises.contains('4') )
                cle = cle + af.crta__CT_BU4__c;
            if ( buUtilises.contains('5') )
                cle = cle + af.crta__CT_BU5__c;
            
            Integer employe = 1;
            Boolean est_deja_compte = false;
            if ( details.get(cle)==null )
                details.put( cle, new Map<String, String>());
            else
                if (details.get(cle).get(af.crta__GS_Salarie__c)!=null)
                {
                    employe = 0; //on ne traite plus car son cas a déjà été traité pour la période concernée
                    est_deja_compte = true;
                }
            if (employe==1)
                details.get(cle).put(af.crta__GS_Salarie__c,af.crta__GS_Salarie__c); //marquer l'employé comme étant traité pour la période en cours
            
            Integer embauche = 0;
            if ( d1<=af.crta__GS_Salarie__r.crta__CT_Date_of_entry_to_the_society__c && af.crta__GS_Salarie__r.crta__CT_Date_of_entry_to_the_society__c<=d2 )
            {
                if ( mois!='Année' && embauches.get(af.crta__GS_Salarie__c)==null )
                {
                    //il est embauché UNE seule fois pendant la période
                    embauche = 1;
                    embauches.put(af.crta__GS_Salarie__c,af.crta__GS_Salarie__c);
                }
                if ( mois=='Année' && embauches_pour_annee.get(af.crta__GS_Salarie__c)==null )
                {
                    //il est embauché UNE seule fois dans l'année 
                    embauche = 1;
                    embauches_pour_annee.put(af.crta__GS_Salarie__c,af.crta__GS_Salarie__c);
                }
            }
            Integer parti = 0;
            if ( d1<=af.crta__GS_Date_de_fin__c && af.crta__GS_Date_de_fin__c<d2 ) //date fin 31/12: il était encore là le 31/12
            {
                if ( mois!='Année' && partis.get(af.crta__GS_Salarie__c)==null )
                {
                    //il est parti UNE seule fois dans la période
                    parti = 1;
                    partis.put(af.crta__GS_Salarie__c,af.crta__GS_Salarie__c);
                }
                if ( mois=='Année' && partis_pour_annee.get(af.crta__GS_Salarie__c)==null )
                {
                    //il est parti UNE seule fois dans l'année
                    parti = 1;
                    partis_pour_annee.put(af.crta__GS_Salarie__c,af.crta__GS_Salarie__c);
                }
            }
            
            Temp_bdu__c tmp = temp_bdu_map.get( cle );
            if ( tmp==null )
            {
                tmp = new Temp_bdu__c();
                tmp.Annee__c = annee_reference;
                tmp.Mois__c = mois; 
                if ( buUtilises.contains('1') )
                    tmp.BU1__c = af.crta__CT_BU1__c;
                if ( buUtilises.contains('2') )
                    tmp.BU2__c = af.crta__CT_BU2__c;
                if ( buUtilises.contains('3') )
                    tmp.BU3__c = af.crta__CT_BU3__c;
                if ( buUtilises.contains('4') )
                    tmp.BU4__c = af.crta__CT_BU4__c;
                if ( buUtilises.contains('5') )
                    tmp.BU5__c = af.crta__CT_BU5__c;
                tmp.type_de_contrat__c  = af.crta__Type_de_contrat__c;
                tmp.Categorie_professionnelle__c = af.crta__Categorie_professionnelle__c;
                tmp.Sexe__c             =  af.crta__GS_Salarie__r.crta__Sexe__c;

                tmp.total_Age__c = 0;
                tmp.total_anciennete__c = 0;
                /*
                tmp.fin_periode_moins_25_ans__c = 0;
                tmp.fin_periode_25_34_ans__c = 0;
                tmp.fin_periode_35_44_ans__c = 0;
                tmp.fin_periode_45_49_ans__c = 0;
                tmp.fin_periode_50_54_ans__c = 0;
                tmp.fin_periode_55_60_ans__c = 0;
                tmp.fin_periode_plus_60_ans__c =0;
                */
                if ( parti != 1 )
                {
                    tmp.total_Age__c            = annee_reference-af.crta__GS_Salarie__r.birthdate.year();
                    tmp.total_anciennete__c = annee_reference-af.crta__GS_Salarie__r.crta__CT_Date_of_entry_to_the_society__c.year();
                    Integer age = annee_reference - af.crta__GS_Salarie__r.birthdate.year();
                    /*
                    if (age<25)
                        tmp.fin_periode_moins_25_ans__c = 1;
                    else if (age>=25 && age<=34)
                        tmp.fin_periode_25_34_ans__c = 1;
                    else if (age>=35 && age<=44)
                        tmp.fin_periode_35_44_ans__c = 1;
                    else if (age>=45 && age<=49)
                        tmp.fin_periode_45_49_ans__c = 1;
                    else if (age>=50 && age<=54)
                        tmp.fin_periode_50_54_ans__c = 1;
                    else if (age>=55 && age<=60)
                        tmp.fin_periode_55_60_ans__c = 1;
                    else if (age>60)
                        tmp.fin_periode_plus_60_ans__c =1;
                        */
                }
                tmp.nombre_embauches__c = embauche;
                tmp.nombre_partis__c        = parti;
                tmp.nombre_employe__c   = 1;
                tmp.total_heures_theoriques_travaillee__c = af.crta__Horaire_moyen_mensuel__c;
                if ( af.crta__GS_Date_de_debut__c<=d1 && d1<=af.crta__GS_Date_de_fin__c )
                {
                    tmp.nb_employes_debut_periode__c = 1;
                }
                else
                    tmp.nb_employes_debut_periode__c = 0;
                
                temp_bdu_map.put( cle, tmp );
                
                if ( mois=='12' && af.crta__Categorie_professionnelle__c=='1')            //pour test                  
                {
                    if (partis.get(af.crta__GS_Salarie__c)==null)  
                        details_calcul.add( new details_calcul__c(donnees__c=af.crta__GS_Salarie__c));
                }
            }
            else
            {
                //calcul ancienneté à ajouter ici aussi
                if (!est_deja_compte)
                {
                    if ( parti != 1 )
                    {
                        Integer age = annee_reference - af.crta__GS_Salarie__r.birthdate.year();
                        tmp.total_Age__c = tmp.total_Age__c + age;
                        tmp.total_anciennete__c = tmp.total_anciennete__c +annee_reference - af.crta__GS_Salarie__r.crta__CT_Date_of_entry_to_the_society__c.year();
                        /*
                        if (age<25)
                            tmp.fin_periode_moins_25_ans__c = tmp.fin_periode_moins_25_ans__c + 1;
                        else if (age>=25 && age<=34)
                            tmp.fin_periode_25_34_ans__c = tmp.fin_periode_25_34_ans__c + 1;
                        else if (age>=35 && age<=44)
                            tmp.fin_periode_35_44_ans__c = tmp.fin_periode_35_44_ans__c + 1;
                        else if (age>=45 && age<=49)
                            tmp.fin_periode_45_49_ans__c = tmp.fin_periode_45_49_ans__c + 1;
                        else if (age>=50 && age<=54)
                            tmp.fin_periode_50_54_ans__c = tmp.fin_periode_50_54_ans__c + 1;
                        else if (age>=55 && age<=60)
                            tmp.fin_periode_55_60_ans__c = tmp.fin_periode_55_60_ans__c + 1;
                        else if (age>60)
                            tmp.fin_periode_plus_60_ans__c =tmp.fin_periode_plus_60_ans__c + 1;
                            */
                    }
                    tmp.nombre_embauches__c = tmp.nombre_embauches__c + embauche;
                    tmp.nombre_partis__c        = tmp.nombre_partis__c + parti;
                    tmp.nombre_employe__c = tmp.nombre_employe__c + employe;
                    tmp.total_heures_theoriques_travaillee__c = tmp.total_heures_theoriques_travaillee__c + af.crta__Horaire_moyen_mensuel__c;
                    
                    if ( af.crta__GS_Date_de_debut__c<=d1 && d1<=af.crta__GS_Date_de_fin__c )
                    {
                        tmp.nb_employes_debut_periode__c = tmp.nb_employes_debut_periode__c + 1;
                    }
                    //---pour test:
                    if ( mois=='12' && af.crta__Categorie_professionnelle__c=='1')
                    {
                        if (partis.get(af.crta__GS_Salarie__c)==null)  
                           details_calcul.add( new details_calcul__c(donnees__c=af.crta__GS_Salarie__c));
                    }
                }
            }
        }
    }
    
    global void execute( Database.BatchableContext BC, List<SObject> scope ) 
    {
        String cle;
        Map<String,Temp_BDU__c> temp_bdu_map = new Map<String,temp_BDU__c>();
        for( Temp_BDU__c t : [SELECT Id, 
                        Mois__c, 
                        Annee__c, BU1__c, BU2__c, BU3__c, BU4__c, BU5__c, 
                            Categorie_professionnelle__c, 
                            Sexe__c, 
                            type_de_contrat__c, 
                            nombre_employe__c, total_Age__c, total_anciennete__c, 
                            nombre_embauches__c, nombre_partis__c, nb_employes_debut_periode__c, total_heures_theoriques_travaillee__c
                          //fin_periode_moins_25_ans__c, fin_periode_25_34_ans__c, fin_periode_35_44_ans__c, fin_periode_45_49_ans__c, fin_periode_50_54_ans__c, fin_periode_55_60_ans__c, fin_periode_plus_60_ans__c
                              FROM Temp_BDU__c where Annee__c=:annee_reference] )
        {
            cle = t.annee__c + t.mois__c + t.categorie_professionnelle__c + t.type_de_contrat__c + t.sexe__c;
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
        
        //---clé de recherche: année, mois, bu1, bu2, bu3, bu4, bu5, Categorie_professionnelle__c,type_de_contrat__c
        List<details_calcul__c> details_calcul = new List<details_calcul__c>();
        for( SObject aff : scope )
        {
            Date d1;
            Date d2;
            crta__GS_Affectation_poste__c af = (crta__GS_Affectation_poste__c)aff;
            for( Integer mois=1; mois<=12; mois++ )
            {
                d1 = Date.newInstance( annee_reference, mois, 1 );
                Integer numberOfDays = Date.daysInMonth( annee_reference, mois );
                d2 = Date.newInstance( annee_reference, mois, numberOfDays );
                
                    String smois;
                    if (mois<10)
                        smois = '0'+mois;
                    else
                        smois = String.valueof(mois);
                traiter_periode( af, d1, d2, temp_bdu_map , smois, details_calcul  );
            }
            //---pour l'année à la place de total général
            d1 = Date.newInstance( annee_reference, 1, 1 );
            d2 = Date.newInstance( annee_reference, 12, 31 );
            traiter_periode( af, d1, d2, temp_bdu_map , 'Année', details_calcul  );
        }
        //insert details_calcul;
        upsert temp_bdu_map.values();
    }
    
    global void finish( Database.BatchableContext BC ) 
    {
        //---IND01202---
        AggregateResult[] groupedResults =[select sum(Nb_employe_fin_periode__c) eff, Categorie_professionnelle__c, Sexe__c,mois__c from temp_bdu__c where mois__c !='Année' and annee__c=:refDate.year() group by mois__c,Categorie_professionnelle__c, Sexe__c];
        Map<String,Integer>cumul_val_categ_sexe = new Map<String,Integer>(); 
        Map<String,Integer>cumul_nb_categ_sexe = new Map<String,Integer>();
        for( AggregateResult ar : groupedResults )
        {
            Integer eff = Integer.valueOf( ar.get('eff') );
            String mois = String.valueOf(ar.get('mois__c'));
            String categ = String.valueOf(ar.get('Categorie_professionnelle__c'));
            String sexe = String.valueOf(ar.get('Sexe__c'));
            String cle_categ_sexe = categ +sexe;
            Integer somme = cumul_val_categ_sexe.get( cle_categ_sexe );
            if (somme==null)
                somme = eff;
            else
                somme = somme + eff;
            cumul_val_categ_sexe.put( cle_categ_sexe, somme );
            Integer nb = cumul_nb_categ_sexe.get( cle_categ_sexe );
            if (nb==null)
                nb = 1;
            else
                nb = nb + 1;
            cumul_nb_categ_sexe.put( cle_categ_sexe, nb );
        }
        List<temp_bdu__c> lst = [select effectif_moyen_mensuel_categ_sexe__c, Nb_employe_fin_periode__c, Categorie_professionnelle__c, Sexe__c, mois__c from temp_bdu__c where mois__c='Année' and annee__c=:refDate.year()];
        for( temp_bdu__c t : lst )
        {
            t.effectif_moyen_mensuel_categ_sexe__c = double.valueOf(cumul_val_categ_sexe.get(t.Categorie_professionnelle__c + t.Sexe__c)) / double.valueOf(cumul_nb_categ_sexe.get(t.Categorie_professionnelle__c + t.Sexe__c)) ;
        }
        update lst;
        
        
                 
        //--- suite du traitement ---
        if (!Test.isRunningTest()) 
        {
            bduCalcAbsences bat = new bduCalcAbsences( refDate.addDays(+1) ); 
            Database.executeBatch( bat, 2000 );
        }
    }
    
    global void execute( SchedulableContext c ) 
    {
        Database.executeBatch( this, 2000 );  
    }
}