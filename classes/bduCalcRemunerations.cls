/*-----------------------
String stringDate = '01/01/2014';
bduPreBatch clsCRON = new bduPreBatch( stringDate );
System.Schedule('Traitement des données', '0 0 20 1 1-12 ? *', clsCRON);
------------------------*/

global class bduCalcRemunerations implements Database.Batchable<SObject>,Schedulable, Database.Stateful 
{
    public class MyException extends Exception {}
    global Date refDate; 
    global String buUtilises; 
    global Integer annee_reference;
    global Map<ID,ID> salaries_permanents; 
     
    /*
    //---IND01209
    global Map<String,Info_salarie> dix_plus_hautes_rem;
    //---IND01206
    global Integer compte_dix_pourcent;
    global Map<String,Info_salarie> dix_pourcent_hautes_rem;
    global Map<String,Info_salarie> dix_pourcent_basses_rem;
    */
    global class Employe implements Comparable
    {
        ID ident;
        Decimal remu_annuelle;
        String sexe;
        global Integer compareTo(Object compareTo) 
        {
            Employe compareToEmp = (Employe)compareTo;
            if (remu_annuelle == compareToEmp.remu_annuelle) return 0;
            if (remu_annuelle > compareToEmp.remu_annuelle) return 1;
            return -1;        
        }
    }
    global Map<String,Employe> remu_annuel_par_emp;
        
    class Affectation
    {
        ID ident;
        Date debut;
        Date fin;
        String categ;
        String contrat;
        String BU1;
        String BU2;
        String BU3;
        String BU4;
        String BU5;
        String sexe;
    }
    
    global bduCalcRemunerations( Date pDate_ref ) 
    {
        refDate = pDate_ref.addDays(-1);
        buUtilises = crta__Param_calc_auto__c.getOrgDefaults().crta__organisation_BU__c;
        annee_reference = refDate.year();
        remu_annuel_par_emp = new Map<String,Employe>();
        salaries_permanents = new Map<ID,ID>();
        /*
        //---IND01209
        dix_plus_hautes_rem = new  Map<String,Info_salarie>(); 
        //---IND01206
        dix_pourcent_hautes_rem = new Map<String,Info_salarie>();
        dix_pourcent_basses_rem = new Map<String,Info_salarie>();
        */
    }
    
    global Database.QueryLocator start( Database.BatchableContext BC ) 
    {
        Date d1 = Date.newInstance( annee_reference, 1, 1 );
        Date d2 = Date.newInstance( annee_reference, 12, 31 );
        String sd1 = annee_reference +'-01-01';
        String sd2 = annee_reference +'-12-31';

        /*
        AggregateResult[] groupedResults = [SELECT count(id) nb_rem FROM crta__Salaire__c WHERE crta__CT_Date_de_remuneration__c>=:d1 AND crta__CT_Date_de_remuneration__c<=:d2 group by crta__Salarie__c];
        compte_dix_pourcent  = Integer.valueOf( groupedResults.size() * 0.1 );
        system.debug('compte_dix_pourcent:'+compte_dix_pourcent);
        */
        for(crta__GS_Affectation_poste__c aff : [select crta__GS_Salarie__c,crta__GS_Date_de_debut__c,crta__GS_Date_de_fin__c, crta__Type_de_contrat__c  
            from crta__GS_Affectation_poste__c
          where crta__Type_de_contrat__c='CDI' 
              and crta__GS_Date_de_fin__c>=:d2 
              and crta__GS_Date_de_debut__c<=:d1 
              and crta__GS_Salarie__r.crta__CT_Working_time__c='Temps plein'])
        {
            salaries_permanents.put( aff.crta__GS_Salarie__c, aff.crta__GS_Salarie__c );
        }

        String req = 'SELECT crta__Salarie__c,crta__CT_Brut_SS__c,crta__CT_Date_de_remuneration__c FROM crta__Salaire__c WHERE crta__CT_Brut_SS__c!=0 and crta__CT_Date_de_remuneration__c>='+sd1+' AND crta__CT_Date_de_remuneration__c<='+sd2;
        system.debug( req );        
        if ( Test.isRunningTest() )
            return Database.getQueryLocator('SELECT crta__Salarie__c,crta__CT_Brut_SS__c,crta__CT_Date_de_remuneration__c FROM crta__Salaire__c limit 50');
        else
            return Database.getQueryLocator( req );
    }
    private Affectation trouver_affectation( Date repere, List<Affectation> lis )
    {
        Affectation res = null;
        Affectation dernier = null;
        for( Affectation s1 : lis )
        {
            String d1 =DateTime.newInstance( s1.debut.year(), s1.debut.month(), s1.debut.day(), 8,0,0).format('yyyyMM'); 
            String d2 =DateTime.newInstance( s1.fin.year(), s1.fin.month(), s1.fin.day(), 8,0,0).format('yyyyMM'); 
            string srepere = DateTime.newInstance( repere.year(), repere.month(), repere.day(), 8,0,0).format('yyyyMM');
            if ( d1<=srepere && srepere<=d2 ) 
            {
                res = s1;
                break;
            }
            if (dernier==null)
            {
                dernier = s1;
            }
            else if ( dernier.fin < s1.fin )
            {
                dernier = s1;
            }
        }
        if (res==null && lis.size()>0)
            res = dernier; //prendre la dernière affectation
        return res;
    }
    
    private void traiter_periode( 
        crta__Salaire__c sal, 
        List<Affectation> affect_emp, 
        Map<String,temp_BDU__c> temp_bdu_map,
        Boolean traiter_annee,
        List<details_calcul__c> details_calcul)
    {
        //---récupérer categ, type_contrat, BU, ... du salarié quand on lui a payé son salaire
        Affectation aff = trouver_affectation( sal.crta__CT_Date_de_remuneration__c, affect_emp ); 
        if ( aff==null )
        {
                system.debug('sal non trouvé:'+ sal.crta__Salarie__c +'affectations:'+affect_emp);
                return;
        }
        //---traiter la ligne de données
        //Date debut_abs;
        //Date fin_abs;
        String smois;
        if ( !traiter_annee )
        {
            if (sal.crta__CT_Date_de_remuneration__c.month()<10)
                smois = '0'+sal.crta__CT_Date_de_remuneration__c.month();
            else
                smois = String.valueof(sal.crta__CT_Date_de_remuneration__c.month());
        }
        else
            smois = 'Année';

        String cle = annee_reference + smois + aff.categ + aff.contrat + aff.sexe;
        if ( buUtilises.contains('1') )
            cle = cle + aff.BU1;
        if ( buUtilises.contains('2') )
            cle = cle + aff.BU2; 
        if ( buUtilises.contains('3') )
            cle = cle + aff.BU3;
        if ( buUtilises.contains('4') )
            cle = cle + aff.BU4;
        if ( buUtilises.contains('5') )
            cle = cle + aff.BU5;
            
        Temp_bdu__c tmp = temp_bdu_map.get( cle );
        if ( tmp!=null )
        {
            if (tmp.total_Salaire__c==null)
                tmp.total_Salaire__c = 0;
            tmp.total_Salaire__c = tmp.total_Salaire__c + sal.crta__CT_Brut_SS__c;
            if (tmp.nombre_Salaires__c==null)
                tmp.nombre_Salaires__c = 0;
            tmp.nombre_Salaires__c = tmp.nombre_Salaires__c + 1;
            
            if ( !traiter_annee && salaries_permanents.get(sal.crta__Salarie__c)!=null )
            {
                Employe e1 = remu_annuel_par_emp.get(sal.crta__Salarie__c);
                if ( e1==null )
                {
                    e1 = new Employe();
                    e1.remu_annuelle = sal.crta__CT_Brut_SS__c;
                    e1.sexe = aff.sexe;
                    e1.ident = sal.crta__Salarie__c;
                    remu_annuel_par_emp.put(sal.crta__Salarie__c,e1);
                }
                else
                {
                    e1.remu_annuelle = e1.remu_annuelle + sal.crta__CT_Brut_SS__c;
                }
                //details_calcul.add( new details_calcul__c(donnees__c=sal.id) );
            }
        }
    }

    private void traiter_periode_pour_temp2( 
        crta__Salaire__c sal, 
        List<Affectation> affect_emp, 
        Map<String,Table_temporaire_2_BDU__c> temp_bdu_2_map )
    {
        //---récupérer categ, type_contrat, BU, ... du salarié quand on lui a payé son salaire
        Affectation aff =trouver_affectation( sal.crta__CT_Date_de_remuneration__c, affect_emp ); 
        if ( aff==null || salaries_permanents.get(sal.crta__Salarie__c)==null )
        {
                system.debug('sal non trouvé ou non permanent:'+ sal.crta__Salarie__c +'affectations:'+affect_emp);
                return;
        }
            
        //---traiter la ligne de données 
        //Date debut_abs;
        //Date fin_abs;
        String cle = annee_reference + 'IND01207b';
            
        if ( buUtilises.contains('1') )
            cle = cle + aff.BU1;
        if ( buUtilises.contains('2') )
            cle = cle + aff.BU2; 
        if ( buUtilises.contains('3') )
            cle = cle + aff.BU3;
        if ( buUtilises.contains('4') )
            cle = cle + aff.BU4;
        if ( buUtilises.contains('5') )
            cle = cle + aff.BU5;
            
        Table_temporaire_2_BDU__c tmp = temp_bdu_2_map.get( cle );
        if ( tmp==null )
        {
            tmp = new Table_temporaire_2_BDU__c();
            tmp.Annee__c = annee_reference;
            tmp.Code_indicateur__c = 'IND01207b';
            if ( buUtilises.contains('1') )
                tmp.BU1__c = aff.BU1;
            if ( buUtilises.contains('2') )
                tmp.BU2__c = aff.BU2;
            if ( buUtilises.contains('3') )
                tmp.BU3__c = aff.BU3;
            if ( buUtilises.contains('4') )
                tmp.BU4__c = aff.BU4;
            if ( buUtilises.contains('5') )
                tmp.BU5__c = aff.BU5;

            if ( aff.categ=='Cadre' ) //cadre
            {
                tmp.total_rem_cadres__c = sal.crta__CT_Brut_SS__c;
                tmp.nb_rem_cadres__c = 1;
            }
            if ( aff.categ=='Ouvrier' ) //ouvrier
            {
                tmp.total_rem_ouvriers__c = sal.crta__CT_Brut_SS__c;
                tmp.nb_rem_ouvriers__c = 1;
            }
            temp_bdu_2_map.put( cle, tmp );
        }
        else
        {
            if ( aff.categ=='Cadre' ) //cadre
            {
                if ( tmp.total_rem_cadres__c==null )
                    tmp.total_rem_cadres__c = 0;
                tmp.total_rem_cadres__c = tmp.total_rem_cadres__c + sal.crta__CT_Brut_SS__c;
                if ( tmp.nb_rem_cadres__c==null )
                    tmp.nb_rem_cadres__c = 0;
                tmp.nb_rem_cadres__c = tmp.nb_rem_cadres__c + 1;
            }
            if ( aff.categ=='Ouvrier' ) //ouvrier
            {
                if ( tmp.total_rem_ouvriers__c==null )
                    tmp.total_rem_ouvriers__c = 0;
                tmp.total_rem_ouvriers__c = tmp.total_rem_ouvriers__c  + sal.crta__CT_Brut_SS__c;
                if ( tmp.nb_rem_ouvriers__c==null )
                    tmp.nb_rem_ouvriers__c = 0;
                tmp.nb_rem_ouvriers__c = tmp.nb_rem_ouvriers__c + 1;
            }
        }
    }

    /*
    private void recup_plus_hautes_rem( crta__Salaire__c sal, List<Info_salarie> affect_emp, Integer nb_elts, Map<String,Info_salarie> plus_hautes_rem )
    {
        //---récupérer categ, type_contrat, BU, ... du salarié quand on lui a payé son salaire
        Info_salarie aff =trouver_affectation( sal.crta__CT_Date_de_remuneration__c, affect_emp ); 
        if ( aff==null )
        {
                system.debug('sal non trouvé:'+ sal.crta__Salarie__c +'affectations:'+affect_emp);
                return;
        }
            
        //---traiter la ligne de données 
        if ( plus_hautes_rem.size()<nb_elts )
        {
            aff.salaire = sal.crta__CT_Brut_SS__c;
            plus_hautes_rem.put( sal.crta__Salarie__c, aff );
        }
        else
        {
            Decimal min = 1000000;
            ID id_min;
            for( Info_salarie is2 : plus_hautes_rem.values() )
            {
                if (is2.salaire<min)
                {
                    min = is2.salaire;
                   id_min =is2.ident;
                } 
            }
            if ( sal.crta__CT_Brut_SS__c >min )
            {
                plus_hautes_rem.remove( id_min );
                aff.salaire = sal.crta__CT_Brut_SS__c;
                plus_hautes_rem.put( sal.crta__Salarie__c, aff );
            }
        }
    }   
     
    private void recup_plus_basses_rem( crta__Salaire__c sal, List<Info_salarie> affect_emp,  Integer nb_elts,  Map<String,Info_salarie> plus_basses_rem  )
    {
        //---récupérer categ, type_contrat, BU, ... du salarié quand on lui a payé son salaire
        Info_salarie aff =trouver_affectation( sal.crta__CT_Date_de_remuneration__c, affect_emp ); 
        if ( aff==null || sal.crta__CT_Brut_SS__c<0 )
        {
                system.debug('sal non trouvé:'+ sal.crta__Salarie__c +'affectations:'+affect_emp+' ou brut negatif:'+sal.crta__CT_Brut_SS__c);
                return;
        }

        //---traiter la ligne de données 
        if ( plus_basses_rem.size()<nb_elts )
        {
            aff.salaire = sal.crta__CT_Brut_SS__c;
            plus_basses_rem.put( sal.crta__Salarie__c, aff );
        }
        else
        {
            Decimal max = 0;
            ID id_max;
            for( Info_salarie is2 : plus_basses_rem.values() )
            {
                if (is2.salaire>max)
                {
                    max = is2.salaire;
                   id_max =is2.ident;
                } 
            }
            system.debug('max:'+max);
            if ( sal.crta__CT_Brut_SS__c <max )
            {
                plus_basses_rem.remove( id_max );
                aff.salaire = sal.crta__CT_Brut_SS__c;
                plus_basses_rem.put( sal.crta__Salarie__c, aff );
            }
        }
    }
       
    private void traiter_IND01209( crta__Salaire__c sal, List<Info_salarie> affect_emp )
    {
        Integer nb_elts  = 10; //les 10 plus hautes rémunerations
        recup_plus_hautes_rem( sal, affect_emp,  nb_elts, dix_plus_hautes_rem );
    }
    
    private void traiter_IND01206( crta__Salaire__c sal, List<Info_salarie> affect_emp )
    {
        Integer nb_elts  = compte_dix_pourcent; //10% des salariés touchant les rémunérations les plus élevées
        recup_plus_hautes_rem( sal, affect_emp,  nb_elts, dix_pourcent_hautes_rem );
        recup_plus_basses_rem( sal, affect_emp, nb_elts, dix_pourcent_basses_rem );
    }
    */
    
    global void execute( Database.BatchableContext BC, List<SObject> scope ) 
    {
        //---salariés concernés
        Set<ID> les_salaries = new Set<ID>();
        for( SObject sala : scope )
        {
            crta__Salaire__c sal = (crta__Salaire__c)sala;      //---préparer la table temp à modifier
            les_salaries.add( sal.crta__Salarie__c );
        }
        //---list des employés concernés avec leur categ, contrat,sexe,BU,...
        Date d1 = Date.newInstance( annee_reference, 1, 1 );
        Date d2 = Date.newInstance( annee_reference, 12, 31 );
        Map<ID,List<Affectation>>employes =new Map<ID,List<Affectation>>();
        for( crta__GS_Affectation_poste__c aff : [Select crta__GS_Salarie__c, crta__GS_Date_de_debut__c, crta__GS_Date_de_fin__c, crta__Categorie_professionnelle__c, crta__Type_de_contrat__c, crta__CT_BU1__c, crta__CT_BU2__c, crta__CT_BU3__c, crta__CT_BU4__c, crta__CT_BU5__c,crta__GS_Salarie__r.crta__Sexe__c,crta__Horaire_moyen_mensuel__c  
                                                  From crta__GS_Affectation_poste__c
                                                  where crta__Type_de_contrat__c!='STAO' and crta__GS_Salarie__c in :les_salaries] )
        {
            Affectation info_sal = new Affectation();
            info_sal.ident = aff.crta__GS_Salarie__c;
            info_sal.debut = aff.crta__GS_Date_de_debut__c; 
            info_sal.fin = aff.crta__GS_Date_de_fin__c;
            info_sal.categ = aff.crta__Categorie_professionnelle__c;
            info_sal.contrat = aff.crta__Type_de_contrat__c;
            info_sal.BU1 = aff.crta__CT_BU1__c;
            info_sal.BU2 = aff.crta__CT_BU2__c;
            info_sal.BU3 = aff.crta__CT_BU3__c;
            info_sal.BU4 = aff.crta__CT_BU4__c;
            info_sal.BU5 = aff.crta__CT_BU5__c;
            info_sal.sexe = aff.crta__GS_Salarie__r.crta__Sexe__c;

            List<Affectation>lst =employes.get( aff.crta__GS_Salarie__c ); 
            if ( lst==null )
            {
                lst = new List<Affectation>();
                lst.add( info_sal );
                employes.put( aff.crta__GS_Salarie__c, lst );
            }
            else
            {
                lst.add(info_sal);
            }
        } 
        
        //---les données à modifier dans la table temporaire
        String cle;
        Map<String,Temp_BDU__c> temp_bdu_map = new Map<String,temp_BDU__c>();
        for( Temp_BDU__c t : [SELECT Id, 
            Mois__c, 
            Annee__c, BU1__c, BU2__c, BU3__c, BU4__c, BU5__c, 
            Categorie_professionnelle__c, 
            Sexe__c, 
            type_de_contrat__c, 
            nombre_Salaires__c,total_Salaire__c FROM Temp_BDU__c where Annee__c=:annee_reference] )
        {
            cle = t.annee__c + t.mois__c + t.categorie_professionnelle__c +t.type_de_contrat__c + t.sexe__c;
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

        //---les données à modifier dans la table temporaire 2
        Map<String,Table_temporaire_2_BDU__c> temp_bdu_2_map = new Map<String,Table_temporaire_2_BDU__c>();
        for( Table_temporaire_2_BDU__c t : [SELECT Id, Code_indicateur__c,
            Annee__c, BU1__c, BU2__c, BU3__c, BU4__c, BU5__c, 
            nb_rem_cadres__c, nb_rem_ouvriers__c, total_rem_cadres__c, total_rem_ouvriers__c  FROM Table_temporaire_2_BDU__c where Annee__c=:annee_reference] )
        {
            cle = t.annee__c + t.Code_indicateur__c;
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
            temp_bdu_2_map.put( cle,  t );
        }

        //---clé de recherche: année, mois, bu1, bu2, bu3, bu4, bu5, Categorie_professionnelle__c,type_de_contrat__c
        List<details_calcul__c> details_calcul = new List<details_calcul__c>();
        for( SObject sala : scope )
        {
            crta__Salaire__c sal = (crta__Salaire__c)sala;
            List<Affectation> lst_employes = employes.get( sal.crta__Salarie__c );
            if ( lst_employes!=null )
            {
                Boolean traiter_annee = false;
                traiter_periode( sal, lst_employes, temp_bdu_map, traiter_annee, details_calcul  );
                traiter_annee = true;
                traiter_periode( sal, lst_employes, temp_bdu_map, traiter_annee, details_calcul );
                traiter_periode_pour_temp2( sal, lst_employes, temp_bdu_2_map );
                /*
                traiter_IND01209( sal, lst_employes );
                traiter_IND01206( sal, lst_employes );
                */
            }
            else
                system.debug('non trouvé:'+sal.crta__Salarie__c);
        }
        //insert details_calcul;
        
        upsert temp_bdu_map.values();
        upsert temp_bdu_2_map.values();
    }
    
    global void finish( Database.BatchableContext BC ) 
    {
        //---IND01209 Nombre de femmes dans les 10 plus hautes rémunérations
        Integer val_IND01209 = 0;
        /*
        List<details_calcul__c> details_calcul = new List<details_calcul__c>(); 
        for( Info_salarie s : dix_plus_hautes_rem.values() )
        { 
            system.debug('10plus hautes rem:'+ s);
            if (s.sexe=='F')
            {
                val_IND01209++;
            }
            details_calcul.add( new details_calcul__c(donnees__c=s.ident) );
        }
        */
        List<Employe>lst_emp = remu_annuel_par_emp.values().clone();
        lst_emp.sort();
        Integer nb_sal =lst_emp.size(); 
        for( Integer cpt = 1; nb_sal>=10 && cpt<=10; cpt++ )
        {
            Employe e1 = lst_emp[nb_sal-cpt];
            system.debug( e1 );
            if ( e1.sexe=='F' )
            {
                val_IND01209++;
            }
            //details_calcul.add( new details_calcul__c(donnees__c=e1.ident+' sal:'+e1.remu_annuelle+' sexe:'+e1.sexe) );
        }
        //insert details_calcul;
        List<Table_temporaire_2_BDU__c> lst = [select  id from Table_temporaire_2_BDU__c where Annee__c=:refDate.year() and Code_indicateur__c='IND01209'];
        if ( lst.size()>0 )
            delete lst; 
        Table_temporaire_2_BDU__c v2 = new Table_temporaire_2_BDU__c(Annee__c=refDate.year(), Code_indicateur__c='IND01209',Valeur__c = String.valueOf( val_IND01209 ));   
        insert v2;
        
        //---IND01206 Rapport entre la moyenne des 10% des salariés touchant les rémunérations les plus élevées et celle correspondant au 10% des salariés touchant les rémunérations les moins élevées
        Decimal tot_dix_pourcent_hautes_rem = 0;
        Decimal tot_dix_pourcent_basses_rem = 0;
        /*
        for( Info_salarie s : dix_pourcent_hautes_rem.values() )
        { 
            //system.debug('10% hautes rem:'+ s);
            tot_dix_pourcent_hautes_rem = tot_dix_pourcent_hautes_rem + s.salaire;
        }
        for( Info_salarie s : dix_pourcent_basses_rem.values() )
        { 
            //system.debug('10% basses rem:'+ s);
            tot_dix_pourcent_basses_rem = tot_dix_pourcent_basses_rem + s.salaire;
        }
        */
        Integer cpt_dix_pourent = Integer.valueOf(nb_sal*0.1);
        List<details_calcul__c> del=[select id,donnees__c from details_calcul__c];
        delete del;
        List<details_calcul__c> details_calcul = new List<details_calcul__c>(); 
        for( Integer cpt = 0; cpt_dix_pourent>0 && cpt<cpt_dix_pourent; cpt++ )
        {
            tot_dix_pourcent_basses_rem = tot_dix_pourcent_basses_rem +  lst_emp[cpt].remu_annuelle;
            details_calcul.add( new details_calcul__c(donnees__c=lst_emp[cpt].ident+' sal:'+lst_emp[cpt].remu_annuelle+' sexe:'+lst_emp[cpt].sexe) );
        }
        insert details_calcul;
        for( Integer cpt = 1; cpt<=cpt_dix_pourent; cpt++ )
        {
            tot_dix_pourcent_hautes_rem = tot_dix_pourcent_hautes_rem +  lst_emp[nb_sal-cpt].remu_annuelle;
        }
        
        String val_IND01206 = '';
        if ( tot_dix_pourcent_basses_rem!=0 )
        {
            val_IND01206 = 'Moyenne des 10% rém. des salariés touchant les rémunérations les plus élevées  :' + Integer.valueOf(tot_dix_pourcent_hautes_rem/cpt_dix_pourent).format() 
                + '<br/>Moyenne des 10% des salariés touchant les rémunérations les moins élevées : ' +  Integer.valueOf(tot_dix_pourcent_basses_rem/cpt_dix_pourent).format()
                + '<br/>Rapport : '+ ((tot_dix_pourcent_hautes_rem/cpt_dix_pourent) / (tot_dix_pourcent_basses_rem/cpt_dix_pourent)).setScale(2).format();
        }
        else
        {
            val_IND01206 = '';
        }
        lst = [select  id from Table_temporaire_2_BDU__c where Annee__c=:refDate.year() and Code_indicateur__c='IND01206'];
        if ( lst.size()>0 )
            delete lst; 
        v2 = new Table_temporaire_2_BDU__c( Annee__c=refDate.year(), Code_indicateur__c='IND01206', Valeur__c =val_IND01206 );   
        insert v2;
        
        //---lancer la suite du traitement
        if (!Test.isRunningTest()) 
        {
            bduCalcFormations bat = new bduCalcFormations( refDate.addDays(+1) ); 
            Database.executeBatch( bat, 2000 );
        }
    }
    
    global void execute( SchedulableContext c ) 
    {
        Database.executeBatch( this, 2000 );  
    }
}