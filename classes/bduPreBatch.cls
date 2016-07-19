/*
bduPreBatch splitter = new bduPreBatch( '01/01/2015' );
Database.executeBatch(splitter, 2000);
*/
global class bduPreBatch implements Database.Batchable<SObject>, Schedulable {
    public class MyException extends Exception {}
    public class BduPreBatchException extends Exception {}
    private String stringDate;
    private Date refDate;

    Class Contact_categories {
        Contact salarie;
        Map<String, Date> date_debut_par_categorie;

        public Contact_categories( Contact psalarie, Map<String, Date> pdebut_categorie ) {
            salarie = psalarie;
            date_debut_par_categorie = pdebut_categorie;
        }
    }

    global bduPreBatch( String prefDate ) {
        if ( prefDate == null || prefDate == '' ) {
            stringDate = Datetime.now().date().format();
        } else {
            stringDate = prefDate;
        }
        refDate = Date.parse( stringDate ).addDays(-1);
    }

    /**
    * Retrieves contacts and their fields
    * @param Database.BatchableContext BC
    */
    global Database.QueryLocator start( Database.BatchableContext BC ) {
        String req = 'Select id, crta__CT_Matricule__c, Birthdate, crta__Age_batch__c, crta__Nombre_de_repos_compensateurs__c, crta__Anciennete_Batch__c, ' +
                     'crta__CT_Exit_date__c, crta__CT_Date_of_entry_to_the_society__c, date_chgt_categ__c, crta__Date_de_passage_cdi__c, crta__Date_de_passage_temps_plein__c, ' +
                     'crta__CT_BU1__c, crta__CT_BU2__c, crta__CT_BU3__c, crta__CT_BU4__c, crta__CT_BU5__c, crta__Contrat_pret__c, crta__Categorie_professionnelle__c, ' +
                     'crta__CT_Gross_fiscal_annual_salary__c, crta__Level__c, crta__CT_Classification__c, Date_Anciennete_Groupe_CA__c From Contact';
        if (Test.isRunningTest()) {
            return Database.getQueryLocator( req + ' Limit 50');
        } else {
            return Database.getQueryLocator( req );
        }
    }

    /**
    * Updates the contacts with the latest infos from their children tables
    * @param Database.BatchableContext BC
    * @param List<SObject>             scope         List of contacts to update
    */

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        Map<String, Contact_categories> contactMap = new Map<String, Contact_categories>();
        Integer refYear = refDate.year();
        // Custom setting for Effectif permenant
        Transient String contractTypes = [Select crta__Types_de_contrat_effectif_permanent__c From crta__Param_calc_auto__c].crta__Types_de_contrat_effectif_permanent__c;

        //Custom setting for repos compensateur
        Transient String reposTypes = [Select crta__Nom_Repos_compensateur__c From crta__Param_calc_auto__c].crta__Nom_Repos_compensateur__c;
        List<String> reposArray = reposTypes.split(',');

        for ( SObject s : scope ) {
            Contact sal = (Contact)s;
            sal.crta__Stagiaire__c = true ; // on déclare tout le monde stagiaire
            sal.crta__Date_de_passage_cdi__c = null;
            sal.crta__Date_de_passage_temps_plein__c = null;
            
            //sal.crta__Categorie_professionnelle_de_depart__c = null ;
            sal.Categorie_professionnelle_de_depart__c = null ; 
            sal.Classe_de_Depart__c =null ;
            sal.Classification_de_Depart__c =null ;
            //sal.Niveau_de_Depart__c = null ;
            sal.crta__Qualification_detaillee_de_depart__c =null ;
            sal.crta__Temps_de_travail_de_depart__c = null ;
            //sal.crta__Type_de_contrat_de_depart__c = null ;
            sal.Type_de_contrat_de_depart_pl__c = null ;
            sal.Categorie_professionnelle_derniere_affec__c = null;
            sal.Classification_derniere_affectation__c = null;
            sal.Niveau_derniere_affectation__c = null;
            sal.Type_de_contrat_derniere_affectation__c = null;

            
            contactMap.put( s.Id, new Contact_categories( sal, new Map<String, Date>()) );
        }

        system.debug('contactMap' + contactMap.keySet());
        //---derniere date de changement de catégorie pour la période considérée: IND01116 anciennetés moyennes dans la catégorie
        List<crta__GS_Affectation_poste__c> orgList = [Select crta__GS_Salarie__c, crta__GS_Date_de_debut__c, crta__Categorie_professionnelle__c
                From crta__GS_Affectation_poste__c
                Where crta__GS_Salarie__c In :contactMap.keySet()
                And crta__GS_Date_de_debut__c <= :refDate];
        for ( crta__GS_Affectation_poste__c org : orgList ) {
            Contact_categories tmp = contactMap.get( org.crta__GS_Salarie__c );
            Date deb_categ = tmp.date_debut_par_categorie.get( org.crta__Categorie_professionnelle__c );
            if (deb_categ == null || deb_categ > org.crta__GS_Date_de_debut__c)
                tmp.date_debut_par_categorie.put( org.crta__Categorie_professionnelle__c, org.crta__GS_Date_de_debut__c );
        }
        Date d1 = Date.newInstance( refDate.year(), 1, 1 );
        Date d2 = Date.newInstance( refDate.year(), 12, 31 );


        for ( SObject s : scope ) {
            //---prendre la dernière catégorie: maximum date
            Map<String, Date> cat = contactMap.get( s.id ).date_debut_par_categorie;
            Date datemax = Date.parse('01/01/1900');
            for ( Date d : cat.values() ) {
                if ( d > datemax ) {
                    datemax = d;
                }
            }
            Contact c = (Contact)s;
            c.date_chgt_categ__c = datemax; //la date de début du changement dans la dernière catégorie

            // To calculate crta__Age_batch__c on the basis of reference date
            Integer ref_year = d2.year();
            Integer birth_year = c.Birthdate.year();
            Integer age = ref_year - birth_year;
            c.crta__Age_batch__c = age;
            System.debug('Age calculated by batch: ' + age);

            // To calculate crta__Anciennete_Batch__c on the basis of the reference date
            if (c.crta__CT_Exit_date__c != null && c.crta__CT_Exit_date__c > d2) {
                c.crta__Anciennete_Batch__c = (d2.year() - c.Date_Anciennete_Groupe_CA__c.year());
            } else if (c.crta__CT_Exit_date__c <= d2) {
                c.crta__Anciennete_Batch__c = (c.crta__CT_Exit_date__c.year() - c.Date_Anciennete_Groupe_CA__c.year());
            } else {
              	if(c.Date_Anciennete_Groupe_CA__c != null)
                	c.crta__Anciennete_Batch__c = (d2.year() - c.Date_Anciennete_Groupe_CA__c.year());
            }
        }

        
        //---met à jour les champs de contact à la date de lancement du batch
        orgList = [Select crta__GS_Salarie__c, crta__Categorie_professionnelle__c, crta__Temps_de_travail__c, crta__Temps_de_travail_en_pourcentage__c, Niveau__c, Classe__c,
                   crta__Type_de_contrat__c, crta__CT_BU1__c, crta__CT_BU2__c, crta__CT_BU3__c, crta__CT_BU4__c, crta__CT_BU5__c, crta__CT_Qualifications_d_taill_es__c , crta__GS_Date_de_debut__c, crta__Code_niveau_1__c
                   From crta__GS_Affectation_poste__c
                   Where crta__GS_Salarie__c In :contactMap.keySet()
                   And crta__GS_Date_de_debut__c <= :refDate
                   And (crta__GS_Date_de_fin__c = null or crta__GS_Date_de_fin__c >= :refDate)
                   order by crta__GS_Date_de_debut__c asc];


        // addeb by Klein B 11/12/2015
          //throw new     MyException('############## crta__GS_Affectation_poste__c org : orgList  ############## '+ orgList );
        
        for ( crta__GS_Affectation_poste__c org : orgList ) {
            Contact_categories tmp = contactMap.get( org.crta__GS_Salarie__c );

            tmp.salarie.crta__CT_BU1__c = org.crta__CT_BU1__c;
            tmp.salarie.crta__CT_BU2__c = org.crta__CT_BU2__c;
            tmp.salarie.crta__CT_BU3__c = org.crta__CT_BU3__c;
            tmp.salarie.crta__CT_BU4__c = org.crta__CT_BU4__c;
            tmp.salarie.crta__CT_BU5__c = org.crta__CT_BU5__c;




            /*  if(org.crta__Type_de_contrat__c.toUpperCase().contains('CDI')) {
                  tmp.salarie.crta__Type_de_contrat_a_date__c = 'CDI';
                   System.debug('>>>>>  #######   BduPreBatchException - org.crta__Type_de_contrat__c : ' + '[' +org.crta__Type_de_contrat__c  + ']' + ' ##### <<<<<<<');
                            // throw new BduPreBatchException('>>>>>  #######   BduPreBatchException - org.crta__Type_de_contrat__c : ' + '[' +org.crta__Type_de_contrat__c  + ']' + ' ##### <<<<<<<');
              } else {
                  tmp.salarie.crta__Type_de_contrat_a_date__c = org.crta__Type_de_contrat__c;
              }
            */

            tmp.salarie.crta__Type_de_contrat_a_date__c = org.crta__Type_de_contrat__c;

            tmp.salarie.crta__Categorie_professionnelle_a_date__c = org.crta__Categorie_professionnelle__c;
            tmp.salarie.crta__Temps_de_travail_a_date__c = org.crta__Temps_de_travail_en_pourcentage__c;
            tmp.salarie.crta__Qualification_detaillee_a_date__c = org.crta__CT_Qualifications_d_taill_es__c;
            tmp.salarie.crta__CT_Classification__c = org.Classe__c;
            //tmp.salarie.crta__Level__c = org.Niveau__c;
            tmp.salarie.crta__Level__c = org.crta__Code_niveau_1__c;
            tmp.salarie.niveau_a_date__c = org.niveau__c;
            tmp.salarie.classification_a_date__c = org.classe__c;
            tmp.salarie.crta__Date_debut_dernier_contrat_en_cours__c = org.crta__GS_Date_de_debut__c;
            tmp.salarie.crta__Contrat_pret__c = org.crta__Type_de_contrat__c;
        }

        //Updating trainings count
        List<AggregateResult> trainingList = [Select Count(Id), crta__CT_Candidate__c From crta__Formation__c Where crta__CT_Candidate__c IN :contactMap.keySet() AND CALENDAR_YEAR(crta__CT_Start_date__c) = :refYear GROUP BY crta__CT_Candidate__c];
        for (AggregateResult training : trainingList) {
            ID contactId = (ID)training.get('crta__CT_Candidate__c');
            Contact_categories tmp = contactMap.get(contactId);
            tmp.salarie.crta__Nombre_de_formations_dans_l_annee__c = Double.valueOf(training.get('expr0'));
        }

        //Updating unpaid trainings count
        trainingList = [Select Count(Id), crta__CT_Candidate__c From crta__Formation__c Where crta__CT_Candidate__c IN :contactMap.keySet() AND CALENDAR_YEAR(crta__CT_Start_date__c) = :refYear AND crta__Conge_formation_non_remunere__c = true GROUP BY crta__CT_Candidate__c];
        for (AggregateResult training : trainingList) {
            ID contactId = (ID)training.get('crta__CT_Candidate__c');
            Contact_categories tmp = contactMap.get(contactId);
            tmp.salarie.crta__Nombre_conges_formations_non_remuneres__c  = Double.valueOf(training.get('expr0'));
        }
		
		
        //Updating repos compensateur count
        List<AggregateResult> leaveList = [Select Count(Id), crta__CT_Salarie__c From crta__BDU_Data_Absence__c Where crta__CT_Salarie__c IN :contactMap.keySet() AND crta__CT_Date_debut__c <= :d2 And (crta__CT_Date_fin__c = null or crta__CT_Date_fin__c <= :d2) AND crta__Type_d_absence__c IN :reposArray GROUP BY crta__CT_Salarie__c];
        
        
        	
        for (AggregateResult leave : leaveList) {
            ID contactId = (ID)leave.get('crta__CT_Salarie__c');
            Contact_categories tmp = contactMap.get(contactId);
            tmp.salarie.crta__Nombre_de_repos_compensateurs__c  = Double.valueOf(leave.get('expr0'));
        }

        //---Pour trouver les salariés permanents: partie à mettre plutôt dans importation car ne fait référence à aucune période, ou trigger sur affectation
        //   en plus la définition d'un stagiaire peut varier d'un client à l'autre
        // To calculate respective dates for Effectif permanent
        date DateDebExercice= refdate.addyears(-1);
        
        orgList = [Select crta__GS_Salarie__c, crta__GS_Date_de_debut__c , crta__Temps_de_travail_en_pourcentage__c, crta__Temps_de_travail__c, crta__GS_Date_de_fin__c, crta__Type_de_contrat__c, crta__Categorie_professionnelle__c,classe__c,niveau__c,crta__CT_Qualifications_d_taill_es__c
                   from crta__GS_Affectation_poste__c
                   Where crta__Type_de_contrat__c != null
                   and crta__GS_Date_de_fin__c<=:refdate
                   and crta__GS_Date_de_debut__c>=:DateDebExercice
                   //and crta__Type_de_contrat__c LIKE '%cdi%'
                   ORDER BY crta__GS_Salarie__c, crta__GS_Date_de_debut__c ASC];
        
        for ( crta__GS_Affectation_poste__c org : orgList ) {
            Contact_categories tmp = contactMap.get( org.crta__GS_Salarie__c );


            // Il suffit qu'ils aient une affectation pour qu'ils ne soient plus stagiaires
            tmp.salarie.crta__Stagiaire__c = false ;
            
            if ( org.crta__Type_de_contrat__c.contains('CDI') )
            {
                if ( tmp != null && tmp.salarie.crta__Date_de_passage_cdi__c == null )
                {
                    tmp.salarie.crta__Date_de_passage_cdi__c = org.crta__GS_Date_de_debut__c;
                }
                if ( tmp != null && org.crta__Temps_de_travail_en_pourcentage__c == 100)
                {
                    if (tmp.salarie.crta__Date_de_passage_temps_plein__c == null || tmp.salarie.crta__Date_de_passage_temps_plein__c > org.crta__GS_Date_de_debut__c)
                        tmp.salarie.crta__Date_de_passage_temps_plein__c = org.crta__GS_Date_de_debut__c;
                } else {
                    tmp.salarie.crta__Date_de_passage_temps_plein__c = null;
                }
            }

            //---crta__Stagiaire__c
                if ( org.crta__GS_Date_de_fin__c == null )
                    org.crta__GS_Date_de_fin__c = Date.parse('31/12/2999');
                if ( (d1 <= org.crta__GS_Date_de_debut__c && org.crta__GS_Date_de_debut__c <= d2) || (d1 <= org.crta__GS_Date_de_fin__c && org.crta__GS_Date_de_fin__c <= d2) ) {
                    if ((org.crta__Type_de_contrat__c != null && org.crta__Type_de_contrat__c.toUpperCase().contains('ST')) || (org.crta__Categorie_professionnelle__c != null && org.crta__Categorie_professionnelle__c.toUpperCase().contains('ST')) ) {
                        tmp.salarie.crta__Stagiaire__c = (org.crta__Type_de_contrat__c.toUpperCase().contains('ST') || org.crta__Categorie_professionnelle__c.toUpperCase().contains('ST')) ? true : false;
                    }
                }

                     
            if(tmp.salarie.crta__CT_Date_of_entry_to_the_society__c.Year() == refDate.Year())
            {
                tmp.salarie.Turn_over_entree_dans_la_periode__c = 1;
            }
            else
            {
                tmp.salarie.Turn_over_entree_dans_la_periode__c = 0;
            }
            
            if(tmp.salarie.crta__CT_Exit_date__c != null)
            {
                if(tmp.salarie.crta__CT_Exit_date__c.Year() == refDate.Year())
                {
                    tmp.salarie.Turn_over_sortie_dans_la_periode__c = 1;
                }
                else
                {
                    tmp.salarie.Turn_over_sortie_dans_la_periode__c = 0;
                }
            }
            else
            {
                tmp.salarie.Turn_over_sortie_dans_la_periode__c = 0;
            }
            
            
            tmp.salarie.Turn_over_present_a_la_fin_de_periode__c = 1;
            
            system.debug('---aff--'+tmp.salarie.crta__CT_matricule__c+'--'+tmp.salarie.crta__CT_Date_of_entry_to_the_society__c+'---'+org.crta__GS_Date_de_debut__c+'---'+org.crta__GS_Date_de_fin__c);
            
            // On charge les champs "de depart"
            if(tmp.salarie.date_des_informations_de_depart__c==null || 
               tmp.salarie.date_des_informations_de_depart__c>org.crta__GS_Date_de_debut__c) {
               
                   tmp.salarie.date_des_informations_de_depart__c=org.crta__GS_Date_de_debut__c ;
                   
                   tmp.salarie.crta__Categorie_professionnelle_de_depart__c = org.crta__Categorie_professionnelle__c;
                   tmp.salarie.Categorie_professionnelle_de_depart__c = org.crta__Categorie_professionnelle__c;
                   tmp.salarie.Classe_de_Depart__c = org.classe__c;
                   tmp.salarie.Niveau_de_Depart__c = org.niveau__c;
                   tmp.salarie.crta__Qualification_detaillee_de_depart__c =org.crta__CT_Qualifications_d_taill_es__c;
                   tmp.salarie.crta__Temps_de_travail_de_depart__c = org.crta__Temps_de_travail_en_pourcentage__c;
                   tmp.salarie.crta__Type_de_contrat_de_depart__c = org.crta__Type_de_contrat__c ;
                   tmp.salarie.Type_de_contrat_de_depart_pl__c = org.crta__Type_de_contrat__c ;
            }
            
            
            
            // On charge les champs "dernière affectation"
            if(tmp.salarie.crta__CT_Exit_date__c != date.parse('31/12/2999'))
            {
                tmp.salarie.Categorie_professionnelle_derniere_affec__c = org.crta__Categorie_professionnelle__c;
                tmp.salarie.Classification_derniere_affectation__c = org.Classe__c;
                tmp.salarie.Niveau_derniere_affectation__c = org.Niveau__c;
                tmp.salarie.Type_de_contrat_derniere_affectation__c = org.crta__Type_de_contrat__c;
            }
        }






        //---Total of crta__CT_Brut_SS__c to calculate crta__CT_Gross_fiscal_annual_salary__c
        for ( AggregateResult sal : [select crta__Salarie__c, sum(crta__CT_Brut_SS__c) sal_annuel from crta__Salaire__c
                                     where crta__Salarie__c In :contactMap.keySet()
                                     and crta__CT_Date_de_remuneration__c >= :d1
                                     and crta__CT_Date_de_remuneration__c <= :d2
                                     group by crta__Salarie__c]) {
            Contact_categories tmp = contactMap.get( String.valueOf(sal.get('crta__Salarie__c')) );
            tmp.salarie.crta__CT_Gross_fiscal_annual_salary__c = (Decimal) sal.get('sal_annuel') ;
        }

        /*/If there is no last affectation until date de sortie delete following values for that contact
        orgList = [Select crta__GS_Salarie__c, crta__GS_Date_de_debut__c , crta__CT_BU1__c, crta__CT_BU2__c,
                   crta__CT_BU3__c, crta__CT_BU4__c, crta__CT_BU5__c,  crta__Temps_de_travail_en_pourcentage__c, crta__GS_Date_de_fin__c, crta__Type_de_contrat__c, crta__Categorie_professionnelle__c
                   from crta__GS_Affectation_poste__c
                   Where crta__GS_Salarie__c in  :contactMap.keySet()
                   order by crta__GS_Salarie__c, crta__GS_Date_de_fin__c desc];

        Transient String mat_compare;
        for( crta__GS_Affectation_poste__c org : orgList )
        {
            Contact_categories tmp = contactMap.get( org.crta__GS_Salarie__c );
            String matricule = tmp.salarie.crta__CT_Matricule__c;
            if(matricule!= mat_compare)
            {
                if ( org.crta__GS_Date_de_fin__c==null )
                     org.crta__GS_Date_de_fin__c = Date.parse('31/12/2999');
                if(org.crta__GS_Date_de_fin__c < d2)
                {
                    tmp.salarie.crta__CT_BU1__c = '';
                    tmp.salarie.crta__CT_BU2__c = '';
                    tmp.salarie.crta__CT_BU3__c = '';
                    tmp.salarie.crta__CT_BU4__c = '';
                    tmp.salarie.crta__CT_BU5__c = '';
                    tmp.salarie.crta__Contrat_pret__c = '';
                    tmp.salarie.crta__CT_Working_time__c = '';
                    tmp.salarie.crta__Categorie_professionnelle__c = '';
                }
            }

            mat_compare = matricule;
        }
        */
//System.debug('############## scope[0] <<<<<<<'+ scope[0]);
        update scope;
    }

    /**
    * Launches the batch splitter after the contacts were updated
    * @param Database.BatchableContext BC
    */
    global void finish( Database.BatchableContext BC ) {
        if (!Test.isRunningTest()) {
            bduCalcAffectations splitter = new bduCalcAffectations( refDate.addDays(+1)  ); // TODO
            Database.executeBatch(splitter, 2000); // TODO
        }
    }

    global void execute( SchedulableContext c ) {
        Database.executeBatch( this, 2000 );
    }
}