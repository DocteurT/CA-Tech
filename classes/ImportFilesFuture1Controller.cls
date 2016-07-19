public with sharing class ImportFilesFuture1Controller {
    class MyException extends Exception {}
    public class ImportDataException extends Exception {}




//  ------------------------------ Import Contacts 02 ------------------------------

    @future
    public Static void importContacts(List<String> csvFileLines, date dateImportsup) {
        Transient String separator_line = ';';

        ID id_account ;

        Account []  accounts = [select id from Account where Name = 'CA Technologie'];
        if (accounts.size() > 0) {
            id_account = accounts[0].id;
        }

        ID SalarieRecordType = [Select Id  from RecordType where name = 'Salarié' ].id;

        Transient Map<String, Contact> contact_map = new Map<String, Contact>();

        for (Contact cnt : [Select Id, crta__CT_BU1__c, crta__CT_BU2__c, crta__CT_Matricule__c, lastName, firstName, crta__Nationalite__c, birthdate,
                                crta__Sexe__c, crta__CT_Handicape__c, crta__Categorie_professionnelle__c, crta__Poste__c, crta__Contrat_pret__c,
                                crta__CT_Date_of_entry_to_the_society__c, crta__CT_Exit_date__c, crta__RC_Annees_d_experience__c,
                                crta__CT_Length_of_service__c, crta__Motif_de_depart__c, crta__Temps_de_travail_en_pourcentage__c,
                                crta__CT_Date_fin_dernier_contrat_en_cours__c, crta__CT_Service__c
                                from Contact]) {
            contact_map.put(cnt.crta__CT_Matricule__c, cnt);
        }
        for (Integer i = 1; i < csvFileLines.size(); i++) {
            if (csvFileLines[i] != null && csvFileLines[i] != '') {
                Transient String[] csvRecordData = csvFileLines[i].split(separator_line);
                if (csvRecordData.size() > 1 )
                {
                    Date dateEntree = null;

                    //Si cette ligne est avant les données déjà importés, on ne l'importe pas
                    if(csvRecordData[11] != '')
                    {
                        if(date.parse(csvRecordData[11]).year() < dateImportSup.year())
                        {
                            continue;
                        }
                    }
                    
                    String matricule = csvRecordData[0];
                    String nom = csvRecordData[2];
                    String prenom = csvRecordData[3];
                    String sexe = csvRecordData[5];
                    String categ_professionnelle = csvRecordData[4];
                    Date dateNaiss = Date.parse(csvRecordData[6].replace('.', '/'));
                    dateEntree = (csvRecordData.size() > 7 && csvRecordData[7] != '') ? Date.parse(csvRecordData[7]) : null;
                    Date dateAnc = (csvRecordData.size() > 8 && csvRecordData[8] != '') ? Date.parse(csvRecordData[8]) : null;
                    String nat = csvRecordData[9];
                    Date Date_Fin_Previsionnelle = (csvRecordData.size() > 10 && csvRecordData[10] != '') ? Date.parse(csvRecordData[10]) : null;
                    Date dateSortie = (csvRecordData.size() > 11 && csvRecordData[11] != '') ? Date.parse(csvRecordData[11]) : null;
                    String motifDep = csvRecordData[12];
                    Boolean handi =  (csvRecordData.size() > 13 && csvRecordData[13].equals('Oui')) ? true : false;
                    Boolean detacheAvant = (csvRecordData.size() > 14 && csvRecordData[14].equals('Oui')) ? true : false;
                    
                    
                    
                    if (categ_professionnelle == 'CLASSE III')  {
                        categ_professionnelle = 'Cadre';
                    } else if (categ_professionnelle == 'CLASSE II') {
                        categ_professionnelle = 'Techniciens';
                    } else if (categ_professionnelle == 'CLASSE I') {
                        categ_professionnelle = 'Employé';
                    }


                    Contact cnt = contact_map.get(matricule);
                    if (contact_map.containsKey(matricule))
                    {
                        cnt.crta__CT_Matricule__c = matricule;
                        cnt.lastName = nom;
                        cnt.firstName = prenom;
                        cnt.crta__Sexe__c = sexe;
                        cnt.crta__Categorie_professionnelle__c = categ_professionnelle;
                        cnt.birthdate = dateNaiss;
                        cnt.crta__CT_Date_of_entry_to_the_society__c = dateEntree;
                       // cnt.crta__CT_Length_of_service__c = dateAnc;
                        cnt.Date_Anciennete_Groupe_CA__c = dateAnc ; 
                        cnt.Date_d_anciennete__c = dateAnc ;
                        cnt.crta__Date_d_anciennete__c= dateAnc; 
                        cnt.Date_Fin_Previsionnelle__c = Date_Fin_Previsionnelle;
                        cnt.crta__Nationalite__c = nat;
                        cnt.crta__CT_Exit_date__c = dateSortie;
                        cnt.crta__Motif_de_depart__c = motifDep;
                        cnt.crta__CT_Handicape__c = handi;
                        cnt.Detache_Avant__c = detacheAvant;
                    } else
                        {
                        cnt = new Contact(
                            accountId = id_account,
                            recordtypeid = SalarieRecordType,
                            crta__CT_Matricule__c = matricule,
                            lastName = nom,
                            firstName = prenom,
                            birthdate = dateNaiss,
                            crta__Sexe__c = sexe,
                            crta__Categorie_professionnelle__c = categ_professionnelle,
                            crta__CT_Date_of_entry_to_the_society__c = dateEntree,
                       //     crta__CT_Length_of_service__c = dateAnc,
                            Date_Anciennete_Groupe_CA__c = dateAnc , 
                            Date_d_anciennete__c = dateAnc ,
                            crta__Date_d_anciennete__c= dateAnc, 
                            Date_Fin_Previsionnelle__c = Date_Fin_Previsionnelle,
                            crta__Nationalite__c = nat,
                            crta__CT_Exit_date__c = dateSortie,
                            crta__Motif_de_depart__c = motifDep,
                            crta__CT_Handicape__c = handi,
                            Detache_Avant__c = detacheAvant
                        );
                        contact_map.put(matricule, cnt);

                    }
                }
            }
        }
        system.debug('##### taille de la liste : ' + contact_map.size());
        upsert contact_map.values();
    }
    
    //  ------------------------------ END Import Contact 02 ------------------------------
    
    
   //  ------------------------------ Import Affection 02------------------------------
   // C'est le même programme pour tous les fichiers qui impactent la table Affectation
    @future
    public Static void importAffec(List<String> csvFileLines,string typeimport, date dateImportInf, date dateImportsup) {
        Transient String separator_line = ';';

        Transient String[] csvRecordData;
        Transient decimal Horaire_moyen_mensuel_Temp_plein = [Select Horaire_moyen_mensuel_Temp_plein__c From crta__Param_calc_auto__c].Horaire_moyen_mensuel_Temp_plein__c;

        Transient Set<String> contactFilter = new Set<String>();
        String temp;
        for(String line: csvFileLines) {
            temp = (line.split(separator_line))[0];
            if(!(contactFilter.contains(temp))) {
                contactFilter.add(temp);
            }
        }

        // On charge les contacts pour pouvoir retrouver les ID
        Transient Map<String, Contact> contact_map = new Map<String, Contact>();
        for (Contact contact : [Select Id, crta__CT_Matricule__c,crta__CT_Date_of_entry_to_the_society__c, crta__CT_Exit_date__c,crta__Categorie_professionnelle__c, Date_d_anciennete__c from Contact where crta__CT_Matricule__c IN :contactFilter ])
        {
            contact_map.put(contact.crta__CT_Matricule__c, contact);
        }

        // On charge les affectations pour pouvoir travailler dessus
        // La clé sera le matricule suivi de la date de début. On doit avoir une ligne affectation pour 
        // chaque salarié et pour chaque mois depuis la date de début jusqu'à la date de fin
        Transient Map<String, crta__GS_Affectation_poste__c> affec_map = new Map<String, crta__GS_Affectation_poste__c>();
        for (crta__GS_Affectation_poste__c aff : [Select crta__GS_Salarie__r.crta__CT_Matricule__c,crta__GS_date_de_debut__c,crta__GS_date_de_fin__c,crta__Type_de_contrat__c,Motif_CDD__c,
                                                         crta__libelle_filiere__c, crta__CT_BU1__c, crta__CT_BU2__c, crta__CT_BU3__c,crta__CT_BU4__c,crta__Code_niveau_1__c, Position_Conventionnelle__c ,crta__Categorie_professionnelle__c,
                                                         crta__Temps_de_travail_en_pourcentage__c,classe__c, niveau__c,crta__CT_Qualifications_d_taill_es__c,
                                                         changement_Categorie__c, changement_de_classe__c, changement_de_niveau__c,changement_qualif_detaillee__c,changement_de_position_conventionnelle__c,Nombre_de_changement_de_pce__c
                                                    from crta__GS_Affectation_poste__c
                                                   where crta__GS_date_de_debut__c>=:dateimportInf
                                                   and crta__GS_Salarie__r.crta__CT_Matricule__c IN :contactFilter]){
            affec_map.put(aff.crta__GS_Salarie__r.crta__CT_Matricule__c+string.valueof(aff.crta__GS_date_de_debut__c), aff);
        }
        
        string texte_error = ''; 
        //transient List<crta__GS_Affectation_poste__c> maj_affectation = new List<crta__GS_Affectation_poste__c>();
        // On est obligé d'en passer par une map et pas par une list, car il peut y avoir des doublons
        Transient Map<String, crta__GS_Affectation_poste__c> maj_affectation = new Map<String, crta__GS_Affectation_poste__c>();
        
        for (Integer i = 1; i < csvFileLines.size() && maj_affectation.size()<8000  ; i++)
        {
             
            if (csvFileLines[i] == null || csvFileLines[i] == '')
            {
                continue ;
            }     
              
            csvRecordData = csvFileLines[i].split(separator_line);

            if (csvRecordData.size() <= 1)
            {
                continue;
            }
             
                         
            //Si l'année de l'affectation est avant le debut de référence, on n'a pas besoin d'importer la ligne
            if(csvRecordData[2] != '')
            {
                if(date.parse(csvRecordData[2]) > dateImportSup)
                {
                    continue;
                }
            }

            if(csvRecordData[3] != '')
            {
                if(date.parse(csvRecordData[3]) < dateImportinf)
                {
                    continue;
                }
            }
            
            Transient String matricule = csvRecordData[0];
            
            if (!(contact_map.containsKey(matricule)))
            {
                //texte_error = texte_error + 'Matricule inconnu ' + matricule +'<br>';
                continue ; 
            }
            
            //On importe pas si la personne est sortie avant la date concernée
            if(contact_map.get(matricule).crta__CT_Exit_date__c != null && dateImportinf > contact_map.get(matricule).crta__CT_Exit_date__c)
            {
                continue;
            }

            date date_deb = (csvRecordData.size() > 2 && !csvRecordData[2].equals('')) ? Date.parse(csvRecordData[2]) : null ;
            date date_fin = (csvRecordData.size() > 3 && !csvRecordData[3].equals('')) ? Date.parse(csvRecordData[3]) : date.newinstance(2999, 12, 31); 
            
            //if(contact_map.get(matricule).Date_d_anciennete__c<dateImportInf)
            if(contact_map.get(matricule).crta__CT_Date_of_entry_to_the_society__c <dateImportInf)
            {
                 if(date_deb<dateImportInf)
                 {
                        date_deb=dateImportInf;
                 }
                 else
                 {
                      date_Deb=date.newinstance(date_deb.year(), date_deb.month(), 1);
                 }
            }
            else
            {
                 //date_deb= contact_map.get(matricule).Date_d_anciennete__c;
                 date_deb= contact_map.get(matricule).crta__CT_Date_of_entry_to_the_society__c;
            }
            
            
            //On pose comme limite la date de fin saisie lors de l'import
            if(contact_map.get(matricule).crta__CT_Exit_date__c<dateImportSup)
            {
                 date_fin=contact_map.get(matricule).crta__CT_Exit_date__c;
            }
			else
            {
                 if(date_fin>dateImportSup )
                 {
                      date_fin=dateImportSup  ;
                 }
            }

            date dateAff = date.newinstance(date_deb.year(), date_deb.month(), 1);
            dateAff = dateaff.toStartOfMonth().addMonths(1).addDays(-1);

            date date_deb_sauv = date_deb;
            
            // On va vérifier que l'on a bien toutes les lignes Affectation dont on aura besoin par la suite
            //date date1 = date_deb ;
            do  {
            	//Creating proper key
            	String dateDay = (String.valueOf(date_deb.day()).length() == 1) ? '0'+String.valueOf(date_deb.day()) : String.valueOf(date_deb.day());
            	String dateMonth = (String.valueOf(date_deb.month()).length() == 1) ? '0'+String.valueOf(date_deb.month()) : String.valueOf(date_deb.month());
            	string affecKey = matricule + date_deb.year() + '-' + dateMonth + '-' + dateDay;
                if (!(affec_map.containsKey(affecKey))) {
                    // la ligne n'existe pas, on va la créer
                    //date date2=date1.adddays(-1).addmonths(1);
                     
                    dateaff = date.newinstance(date_deb.year(), date_deb.month(), 1);
                    dateAff = date_deb.toStartOfMonth().addMonths(1).addDays(-1);
                    
                    if(dateAff>contact_map.get(matricule).crta__CT_Exit_date__c) 
                         dateAff=contact_map.get(matricule).crta__CT_Exit_date__c;
                    
                    
                    crta__GS_Affectation_poste__c aff = new crta__GS_Affectation_poste__c(
                        crta__GS_Salarie__c = contact_map.get(matricule).id,
                        crta__GS_Date_de_debut__c = date_deb,
                        crta__GS_Date_de_fin__c = dateAff,
                        crta__Horaire_moyen_mensuel__c = 0
                    );
                  
                    affec_map.put(matricule+string.valueof(date_deb), aff); 
                }
                // Je suis sûr que la ligne est bien créée dans la map, je peux donc la mettre à jour
                crta__GS_Affectation_poste__c aff1 = affec_map.get(matricule+string.valueof(date_deb));

                boolean maj = false ;                 
                if(typeimport=='affectation') {
                     string type_de_contrat = (csvRecordData.size() > 4 && !csvRecordData[4].equals('')) ? csvRecordData[4] : null;
                     string motif_CDD = (csvRecordData.size() > 5 && !csvRecordData[5].equals('')) ? csvRecordData[5] : null ;
                     string categorie_professionnelle = contact_map.get(matricule).crta__Categorie_professionnelle__c ;
                     
                     
                     if ((type_de_contrat == 'CDD') && (motif_CDD == 'Contrat apprentissage'))
                     {
                     	type_de_contrat = 'Apprenti';
                     }
                     
                     if ((type_de_contrat == 'CDD') && (motif_CDD == 'Contrat de Professionnalisation'))
                     {
                     	type_de_contrat = 'Contrat pro';
                     } 


                     
                     if (aff1.crta__Type_de_contrat__c != type_de_contrat) {
                          aff1.crta__Type_de_contrat__c = type_de_contrat ; 
                          maj = true ; 
                     }
                     if (aff1.Motif_CDD__c != motif_CDD) {
                          aff1.Motif_CDD__c = motif_CDD ;
                          maj = true ; 
                     } 
                     if (aff1.crta__Categorie_professionnelle__c != categorie_professionnelle) {
                          aff1.crta__Categorie_professionnelle__c = Categorie_professionnelle ;
                          maj = true ; 
                     
                     }
                     
                     
                }
                if(typeimport=='organisation') {
                     string libelle_filiere = (csvRecordData.size() > 5 && !csvRecordData[5].equals('')) ? csvRecordData[5] : null ; 
                     
                     if (aff1.crta__libelle_filiere__c != libelle_filiere) {
                          aff1.crta__libelle_filiere__c = libelle_filiere ; 
                          maj = true ; 
                     }
                }
                
                if(typeimport=='etablissement')
                {
            		string BU1 = 'CHSCT - ' + csvRecordData[5];
                     
                    if (aff1.crta__CT_BU1__c != BU1)
                    {
                    	aff1.crta__CT_BU1__c = BU1; 
                        maj = true ; 
                    }
                }
                
                if(typeimport=='classification') {
                      string Code_niveau_1 = (csvRecordData.size() > 4 && !csvRecordData[4].equals('')) ? csvRecordData[4] : null ;
                      decimal Position_Conventionnelle = (csvRecordData.size() > 6 && !csvRecordData[6].equals('')) ? decimal.valueof(csvRecordData[6]) : null ;
                      
                      if(aff1.crta__Code_niveau_1__c !=Code_niveau_1) {
                           aff1.crta__Code_niveau_1__c = Code_niveau_1;
                           maj = true ; 
                      }
                      if(aff1.Position_Conventionnelle__c !=Position_Conventionnelle) {
                           aff1.Position_Conventionnelle__c = Position_Conventionnelle;
                           maj = true ; 
                      }
                
                }
                if(typeimport=='temps de travail') {
                      decimal Percent = (csvRecordData.size() > 4 && !csvRecordData[4].equals('')) ? Decimal.valueOf(csvRecordData[4].replaceAll(',', '.').trim().replace(' ', '')) : 0;
                      //decimal Percent = (csvRecordData.size() > 4 && !csvRecordData[4].equals('')) ? Decimal.valueOf(csvRecordData[4]) : null;
                      
                      if(aff1.crta__Temps_de_travail_en_pourcentage__c !=Percent) {
                           aff1.crta__Temps_de_travail_en_pourcentage__c  = Percent;
                           aff1.crta__Horaire_moyen_mensuel__c = (percent * Horaire_moyen_mensuel_Temp_plein) / 100 ;
                           maj = true ; 
                      }
                
                }



                if (maj) {
                     maj_affectation.put(matricule+string.valueof(date_deb), aff1); 
                }
                

                affec_map.put(matricule+string.valueof(date_deb), aff1); 

                date_deb  = date_deb.addmonths(1);
                date_deb = date.newinstance(date_deb.year(), date_deb.month(), 1);
                dateAff = date_deb.addMonths(1).addDays(-1);

            } while (date_deb < date_fin  );
            
            
            
           // On va refaire un tour de la map pour le salarié pour voir si il n'y a pas des changement des catégories et autres
            date_deb = dateImportInf ;
            integer j=0 ;
            string changement_categorie;
            string Changement_de_Classe ;
            string Changement_de_niveau ;
            string Changement_de_qualif_detaille ;
            decimal changement_de_position_conventionnelle ; 

            boolean maj = false ;

            system.debug('------------');
           do  {
                 system.debug('-----matricule dans la boucle changement---'+matricule+string.valueof(date_deb));
                 if(!affec_map.containsKey(matricule+string.valueof(date_deb))) {
                      date_deb  = date_deb.addmonths(1);
                      date_deb = date.newinstance(date_deb.year(), date_deb.month(), 1);
                      continue ; 
                 }
                 crta__GS_Affectation_poste__c aff2 = affec_map.get(matricule+string.valueof(date_deb));
                 if(j==0) {
                     changement_categorie=aff2.crta__Categorie_professionnelle__c;
                     Changement_de_Classe = aff2.classe__c ;
                     Changement_de_niveau = aff2.niveau__c ;
                     Changement_de_qualif_detaille = aff2.crta__CT_Qualifications_d_taill_es__c ;
                     Changement_de_position_conventionnelle = aff2.position_conventionnelle__c ;
                 }
                 if(changement_categorie!=aff2.crta__Categorie_professionnelle__c) {
                       if(!aff2.changement_Categorie__c) {
                            aff2.changement_Categorie__c=true;
                            system.debug('---on y est A1---');
                            maj=true ;
                       }
                 } else {
                       if(aff2.changement_Categorie__c) {
                            aff2.changement_Categorie__c=false;
                            system.debug('---on y est A2---');
                            maj=true ;
                       }
                 } 

                 if(changement_de_classe!=aff2.Classe__c) {
                       if(!aff2.changement_de_classe__c) {
                            system.debug('---on y est b1---');
                            aff2.changement_de_classe__c=true;
                            maj=true ;
                       }
                 } else {
                       if(aff2.changement_de_classe__c) {
                            aff2.changement_de_Classe__c=false;
                            system.debug('---on y est B2---');                            
                            maj=true ;
                       }
                 }

                 if(changement_de_niveau!=aff2.niveau__c) {
                       if(!aff2.changement_de_niveau__c) {
                            aff2.changement_de_niveau__c=true;
                            system.debug('---on y est C1---');                            
                            maj=true ;
                       }
                 } else {
                       if(aff2.changement_de_niveau__c) {
                            aff2.changement_de_niveau__c=false;
                            system.debug('---on y est C2---');                            
                            maj=true ;
                       }
                 }
                 if(Changement_de_qualif_detaille!=aff2.crta__CT_Qualifications_d_taill_es__c) {
                       if(!aff2.changement_qualif_detaillee__c) {
                            aff2.changement_qualif_detaillee__c=true;
                            system.debug('---on y est D1---');                            
                            maj=true ;
                       }
                 } else {
                       if(aff2.changement_qualif_detaillee__c) {
                            aff2.changement_qualif_detaillee__c=false;
                            system.debug('---on y est D2---');                            
                            maj=true ;
                       }
                 }
                 if(Changement_de_position_conventionnelle!=aff2.position_conventionnelle__c) {
                       if(!aff2.changement_de_position_conventionnelle__c) {
                            aff2.changement_de_position_conventionnelle__c=true;
                            system.debug('---on y est E1---');
                            maj=true ;
                            aff2.Nombre_de_changement_de_pce__c = 1;
                       }
                 } else {
                       if(aff2.changement_de_position_conventionnelle__c) {
                            aff2.changement_de_position_conventionnelle__c=false;
                            system.debug('---on y est E2---');
                            maj=true ;
                            aff2.Nombre_de_changement_de_pce__c = 1;
                       }
                 }


                 changement_categorie=aff2.crta__Categorie_professionnelle__c;
                 Changement_de_Classe = aff2.classe__c ;
                 Changement_de_niveau = aff2.niveau__c ;
                 Changement_de_qualif_detaille = aff2.crta__CT_Qualifications_d_taill_es__c ;
                 changement_de_position_conventionnelle = aff2.position_conventionnelle__c;
                 
                 if (maj) {
                     maj_affectation.put(matricule+string.valueof(date_deb), aff2); 
                     system.debug('---on fait la maj---');
                     maj=false ; 
                 }
                
                 affec_map.put(matricule+string.valueof(date_deb), aff2); 

                 date_deb  = date_deb.addmonths(1);
                 date_deb = date.newinstance(date_deb.year(), date_deb.month(), 1);
                 j++;

            } while (date_deb < dateImportSup  );
            
            
       }
       
     
        
       // on envoie le mail de fin
       List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
       Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    
       List<String> sendTo = new List<String>();
       sendTo.add(UserInfo.getUserEmail());  // A modifier
       mail.setToAddresses(sendTo);
           

       upsert maj_affectation.values();
       mail.setSubject('Import '+typeimport+' : Sans erreur ');
       string s ;
       if  (maj_affectation.size()<8000) {
             s='Plus besoin de tourner';
       } else {
            s='tout n a pas pu être traité, il faut relancer. On en a traité ' +maj_affectation.size() ;
       }
       s=s+'<br>';
       s=s+'On a eu des données pour les personnes suivantes, mais on ne les a pas en machine<br>';
       s=s+'ce message est purement informatif<br>';
       mail.setHtmlBody(s);            

      mails.add(mail);
      Messaging.sendEmail(mails);

    }
    //  End -----Import Type de Affectation 02 ----------------///


    // ---------------------  Import Salaires annuels---------------------------------------//
    @future
    public Static void importSalairesAnnuels(List<String> csvFileLines) {
        Transient String separator_line = ';';
        ID id_account ;

        Account []  accounts = [select id from Account where Name = 'CA Technologie'];
        if (accounts.size() > 0) {
            id_account = accounts[0].id;
        }
        Transient List<Salaire_Annuel__c> salairesAnnuels = new List<Salaire_Annuel__c>();
        Transient Map<String, Contact> contactsMap = new Map<String, Contact>();


        Transient List<Contact> contacts = [Select Id, crta__CT_Matricule__c from Contact];

        for (Contact contact : contacts) {
            contactsMap.put(contact.crta__CT_Matricule__c, contact);
        }

        for (Integer i = 1; i < csvFileLines.size(); i++) {
            //system.debug('index csvFileLines:' + i);
            if (!String.isBlank(csvFileLines[i])) {
                Transient String[] csvRecordData = csvFileLines[i].split(separator_line);

                Transient String matricule;
                if (csvRecordData.size() > 1) {
                    matricule = csvRecordData[0];


                    if (!contactsMap.containsKey(matricule)) {
                        system.debug('>>>  ####  Contact not found - contact matricule  : ' + matricule  + ' At CSV line : ' + i + ' ##### <<<<<<<');
                        //throw new ImportDataException('>>>>>  #######   Numero de Badge not found: '+ '[' + matricule  + ']' + ' At CSV line : ' + i + ' ##### <<<<<<<');
                    } else {
                        try {

                            Transient Contact contact = contactsMap.get(matricule);
                            Transient Salaire_Annuel__c salaireAnnuel = new Salaire_Annuel__c();

                            salaireAnnuel.salarie__c = contact.Id;

                            salaireAnnuel.TempsPlein_TempsPartiel__c =   csvRecordData[2];
                            salaireAnnuel.temps_de_travail_en_pourcentage__c = (csvRecordData.size() > 3 && csvRecordData[3] != '') ? Decimal.valueOf(csvRecordData[3].replaceAll(',', '.').trim().replace(' ', '')) : 0;
                            salaireAnnuel.RCP__c = (csvRecordData.size() > 4 && csvRecordData[4] != '') ? Decimal.valueOf(csvRecordData[4].replaceAll(',', '.').trim().replace(' ', '')) : 0;
                            salaireAnnuel.RCI__c = (csvRecordData.size() > 5 && csvRecordData[5] != '') ? Decimal.valueOf(csvRecordData[5].replaceAll(',', '.').trim().replace(' ', '')) : 0;
                            salaireAnnuel.RCCR__c = (csvRecordData.size() > 6 && csvRecordData[6] != '') ? Decimal.valueOf(csvRecordData[6].replaceAll(',', '.').trim().replace(' ', '')) : 0;
                            salaireAnnuel.dont_RCCR_12_Mois__c = (csvRecordData.size() > 7 && csvRecordData[7] != '') ? Decimal.valueOf(csvRecordData[7].replaceAll(',', '.').trim().replace(' ', '')) : 0;
                            salaireAnnuel.dont_RCCR_13_Mois__c = (csvRecordData.size() > 8 && csvRecordData[8] != '') ? Decimal.valueOf(csvRecordData[8].replaceAll(',', '.').trim().replace(' ', '')) : 0;
                            salaireAnnuel.dont_RCCR_Specif_DIR__c = (csvRecordData.size() > 9 && csvRecordData[9] != '') ? Decimal.valueOf(csvRecordData[9].replaceAll(',', '.').trim().replace(' ', '')) : 0;
                            salaireAnnuel.salaire_Annuel_Theorique__c = (csvRecordData.size() > 10 && csvRecordData[10] != '') ? Decimal.valueOf(csvRecordData[10].replaceAll(',', '.').trim().replace(' ', '')) : 0;
                            salaireAnnuel.montant_Theo_Base_REC_100__c = (csvRecordData.size() > 11 && csvRecordData[11] != '') ? Decimal.valueOf(csvRecordData[11].replaceAll(',', '.').trim().replace(' ', '')) : 0;
                            salaireAnnuel.RCC__c = (csvRecordData.size() > 12 && csvRecordData[12] != '') ? Decimal.valueOf(csvRecordData[12].replaceAll(',', '.').trim().replace(' ', '')) : 0;
                            salaireAnnuel.dont_RCC_ENF__c = (csvRecordData.size() > 13 && csvRecordData[13] != '') ? Decimal.valueOf(csvRecordData[13].replaceAll(',', '.').trim().replace(' ', '')) : 0;
                            salaireAnnuel.dont_RCC_FAM__c = (csvRecordData.size() > 14 && csvRecordData[14] != '') ? Decimal.valueOf(csvRecordData[14].replaceAll(',', '.').trim().replace(' ', '')) : 0;
                            salaireAnnuel.dont_RCC_Autres__c = (csvRecordData.size() > 15 && csvRecordData[15] != '') ? Decimal.valueOf(csvRecordData[15].replaceAll(',', '.').trim().replace(' ', '')) : 0;
                            salaireAnnuel.dont_RCC_Specif_DIR__c = (csvRecordData.size() > 16 && csvRecordData[16] != '') ? Decimal.valueOf(csvRecordData[16].replaceAll(',', '.').trim().replace(' ', '')) : 0;


                            salairesAnnuels.add(salaireAnnuel);


                        } catch (Exception e) {
                            System.debug('>>>###### ImportFilesFutureController - Error At CSV line :  ' + i + ' e.getMessage() : ' + e.getMessage() + ' #################<<<<<' );
                            System.debug('>>>###### ImportFilesFutureController - Error At CSV line :  ' + i + ' e.getCause():  ' + e.getCause() + ' #################<<<<<' );
                            System.debug('>>>###### ImportFilesFutureController - Error At CSV line :  ' + i + ' e.getStackTraceString() : ' + e.getStackTraceString() + ' #################<<<<<' );
                        }
                    }

                }
            }
        }


        System.debug('>>>### salairesAnnuels.size() : ' + salairesAnnuels.size()); // TODO Clean
        System.debug('>>>### salairesAnnuels : ' + salairesAnnuels); // TODO Clean
        Database.insert(salairesAnnuels, false);


    }

    // --------------------- END Import Import Salaires annuels ----------------------------------//



// ---------------------  Import Formation---------------------------------------//
    @future
    public Static void importFormation(List<String> csvFileLines) {


        Transient String separator_line = ';';

        ID id_account = [select id from Account where Name = 'CA Technologie'].id;
        ID FormationSalarieRecordType = [Select Id  from RecordType where name = 'Formation Salarié' ].id;        

        Transient List<crta__Formation__c> formations = new List<crta__Formation__c>();
        Transient Map<String, Contact> contactsMap = new Map<String, Contact>();
        List<Contact> contactsToUpdate = new List<Contact>();

        Transient List<Contact> contacts = [Select Id, crta__CT_Matricule__c from Contact];

        for (Contact contact : contacts) {
            contactsMap.put(contact.crta__CT_Matricule__c, contact);
        }

        for (Integer i = 1; i < csvFileLines.size(); i++) {
            if (csvFileLines[i] != null && csvFileLines[i] != '') {
                Transient String[] csvRecordData = csvFileLines[i].split(separator_line);

                if (csvRecordData.size() > 1) {
                    Transient String matricule = csvRecordData[0];

                    if (!contactsMap.containsKey(matricule)) {
                        system.debug('>>>  ####  Contact not found - contact matricule  : ' + matricule  + ' At CSV line : ' + i + ' ##### <<<<<<<');
                    } else  {
                        Transient Contact contact = contactsMap.get(matricule);


                        crta__Formation__c formation = new crta__Formation__c();

                        formation.recordtypeid = formationSalarieRecordType ;
                        formation.crta__CT_Candidate__c = contact.Id;
                        formation.crta__CT_Start_date__c = date.parse(csvRecordData[2]); // Date.valueof(csvRecordData[2]);
                        formation.crta__Duree_en_heures__c = (csvRecordData.size() > 3 && csvRecordData[3] != '') ? Decimal.valueOf(csvRecordData[3].replaceAll(',', '.').trim().replace(' ', '')) : 0;
                        formation.crta__CT_Duration__c = csvRecordData[4]+ ' ' + csvRecordData[5];
                        formation.type_de_formation__c = csvRecordData[6];                            
                        formation.categorie_formation__c = csvRecordData[7];                            
                        formation.finalite_formation__c = csvRecordData[8];                            
                        formation.name = csvRecordData[9];                            
                        formation.crta__CT_Training_organization__c = csvRecordData[10]; 
                        formation.imputable_fiscalement__c = csvRecordData[11];    
                        formation.Nb_Hrs_In_Tps_Trav__c = (csvRecordData.size() > 12 && csvRecordData[12] != '') ? Decimal.valueOf(csvRecordData[12].replaceAll(',', '.').trim().replace(' ', '')) : 0;                                                     
                        formation.Dt_Nb_Hrs_In_Tps_Trav_DIF_CPF__c = (csvRecordData.size() > 13 && csvRecordData[13] != '') ? Decimal.valueOf(csvRecordData[13].replaceAll(',', '.').trim().replace(' ', '')) : 0;                                                     
                        formation.Nb_Hrs_Hors_Tps_Trav__c = (csvRecordData.size() > 14 && csvRecordData[14] != '') ? Decimal.valueOf(csvRecordData[14].replaceAll(',', '.').trim().replace(' ', '')) : 0;                                                                                                             
                        formation.Dt_Nb_Hrs_Hors_Tps_Trav_DIF_CPF__c = (csvRecordData.size() > 15 && csvRecordData[15] != '') ? Decimal.valueOf(csvRecordData[15].replaceAll(',', '.').trim().replace(' ', '')) : 0;                                                                                 
                        formation.domaine_du_stage__c= csvRecordData[16];
                        formation.theme_du_stage__c= csvRecordData[17];
                        formation.Interne_Externe__c = csvRecordData[34];

                        formations.add(formation);

                    }

                }
            }
        }

        System.debug('>>>####### formations.size() : ' + formations.size());
        System.debug('>>>####### formations  : ' + Json.serialize(formations)) ;
        Database.insert(formations, false);


    }

// --------------------- END Import formation---------------------------------------//


// ---------------------  Import medecine Du Travail---------------------------------------//
    @future
    public Static void importMedecineDuTravail(List<String> csvFileLines) {


        Transient String separator_line = ';';

        ID id_account = [select id from Account where Name = 'CA Technologie'].id;

        Transient List<crta__BDU_Data_M_decine_du_travail__c> medecineDuTravails = new List<crta__BDU_Data_M_decine_du_travail__c>();
        Transient Map<String, Contact> contactsMap = new Map<String, Contact>();
        Set<Contact> cont_set_ucf = new Set<Contact>();
        List<Contact> contactsToUpdate = new List<Contact>();

        Transient List<Contact> contacts = [Select Id, crta__CT_Matricule__c from Contact];

        for (Contact contact : contacts) {
            contactsMap.put(contact.crta__CT_Matricule__c, contact);
        }

        for (Integer i = 1; i < csvFileLines.size(); i++) {
            if (csvFileLines[i] != null && csvFileLines[i] != '') {
                Transient String[] csvRecordData = csvFileLines[i].split(separator_line);

                if (csvRecordData.size() > 1) {
                    Transient String matricule = csvRecordData[0];

                    if (!contactsMap.containsKey(matricule)) {
                        system.debug('>>>  ####  Contact not found - contact matricule  : ' + matricule  + ' At CSV line : ' + i + ' ##### <<<<<<<');
                    } else  {
                        Transient Contact contact = contactsMap.get(matricule);

                        try {

                            crta__BDU_Data_M_decine_du_travail__c medecineDuTravail = new crta__BDU_Data_M_decine_du_travail__c();

                            medecineDuTravail.crta__Salarie__c = contact.Id;
                            medecineDuTravail.crta__CT_Date_de_la_visite__c = Date.parse(csvRecordData[2]);
                            medecineDuTravail.type_de_test__c = csvRecordData[3];
                            medecineDuTravail.motif_visite__c = csvRecordData[4];
                            medecineDuTravail.resultat_visite__c = csvRecordData[5];
                            medecineDuTravail.Statut_visite__c = csvRecordData[6];
                            medecineDuTravails.add(medecineDuTravail);

                            contact.AccountId = id_account;
                            cont_set_ucf.add(contact);

                        } catch (Exception e) {
                            System.debug('>>>###### ImportFilesFutureController - e.getMessage() : ' + e.getMessage() + ' At CSV line : ' + i + ' ##### <<<<<<<');
                        }
                    }

                }
            }
        }
        contactsToUpdate.addAll(cont_set_ucf);
        System.debug('>>>####### medecineDuTravails.size() : ' + medecineDuTravails.size());
        System.debug('>>>####### medecineDuTravails  : ' + Json.serialize(medecineDuTravails)) ;
        Database.insert(medecineDuTravails, false);
        update contactsToUpdate;

    }

// --------------------- END Import medecine Du Travail---------------------------------------//



// --------------------- CA   Import  Absence---------------------------------------//
    @future
    public Static void importAbsenceExtractionsituation(List<String> csvFileLines) {




        Transient    Map<String, String>  typeDAbsenceMap = new Map<String, String> {
            'MAL : ALLAITEMENT' => 'Absence grossesse',
            'MAL : GROSSESSE PATHOLOGIQUE' => 'Absence grossesse',
            'MAL : HOSPITALISATION' => 'Absence maladie',
            'MAL : MALADIE' => 'Absence maladie',
            'MAL : MALADIE CONJOINT OU ENFANTS PAYEE' => 'Absence maladie',
            'MAL : MALADIE SANS CERTIFICAT REMUNEREE' => 'Absence maladie',
            'SAN : DISPONIBILITE MALADIE' => 'Absence maladie',
            'SAN : MALADIE CONJOINT OU ENFANTS SANS SOLDE' => 'Absence maladie',
            'SAN : MALADIE NON REMUNEREE' => 'Absence maladie',
            'NON : ABSENCE NON JUSTIFIEE' => 'Absence non-justifiée',
            'MAL : ACCIDENT DE TRAJET' => 'Accident de travail',
            'MAL : ACCIDENT DE TRAVAIL' => 'Accident de travail',
            'MAL : MALADIE PROFESSIONNELLE' => 'Accident de travail',
            'AUT : AUTRES ABSENCES SANS IMPACT AJC' => 'Autre',
            'AUT : CONGES DECES' => 'Autre',
            'AUT : CONGES NAISSANCE' => 'Autre',
            'AUT : DECES ASC DESC 1er DEGRE CONJOINT' => 'Autre',
            'AUT : DECES BEAUX-FRERES BELLES-SOEURS AGENT' => 'Autre',
            'AUT : DECES GRD PARENT PT-ENFANTS FRERE SOEUR' => 'Autre',
            'AUT : DECES PARENT OU ENFANT' => 'Autre',
            'AUT : DEMENAGEMENT' => 'Autre',
            'AUT : JURE D\'ASSISE' => 'Autre',
            'AUT : MARIAGE ENFANT AGENT' => 'Autre',
            'AUT : MARIAGE FRERE/SOEUR AGENT' => 'Autre',
            'AUT : MARIAGE SALARIE' => 'Autre',
            'AUT : REMARIAGE SALARIE' => 'Autre',
            'CON : AUTRES JOURS DE CONGES (RTT)' => 'Autre',
            'CON : Compte Epargne Temps' => 'Autre',
            'DEL : DELEGUE CMSA (AG)' => 'Autre',
            'FOR : CONGES AGECIFCAMA' => 'Autre',
            'SAN : CONGES AGECIFCAMA SANS SOLDE' => 'Autre',
            'SAN : CONGES SANS SOLDE' => 'Autre',
            'SAN : CONGES SANS SOLDE COURT' => 'Autre',
            'SAN : JOUR DE GREVE' => 'Autre',
            'SAN : MISE A PIED DISCIPLINAIRE' => 'Autre',
            'FOR : ANIMATION FORMATION' => 'Formation',
            'FOR : CONGES FORMATION ALTERNANCE' => 'Formation',
            'FOR : FORMATION OU EXAMEN' => 'Formation',
            'MAL : MATERNITE LIMITEE A 112 JOURS' => 'Congés maternité',
            'SAN : CONGES PARENTAL' => 'Congés maternité',
            'SAN : CONGES PRESENCE PARENTALE SANS SOLDE' => 'Congés maternité',
            'MAL : PATERNITE LIMITEE A 11 JOURS' => 'Congés paternité',
            'SAN : PATERNITE SANS SOLDE' => 'Congés paternité',
            'CON : CONGES PAYES ANNUELS' => 'Congés payés',
            'MAL : LONGUE MALADIE' => 'Longue maladie',
            'AUT : DISPENSE D\'EXECUTION PREAVIS PAYE' => 'Préavis',
            'CON : RECUPERATION HEURES SUPPLEMENTAIRES' => 'Repos compensateur'
        };

        Transient String separator_line = ';';

        ID id_account = [select id from Account where Name = 'CA Technologie'].id;

        //Transient List<crta__BDU_Data_Absence__c> add_absence_ucf = new List<crta__BDU_Data_Absence__c>();
        Transient List<crta__BDU_Data_Absence__c> absences = new List<crta__BDU_Data_Absence__c>();
        Transient Map<String, Contact> contactsMap = new Map<String, Contact>();
        Set<Contact> cont_set_ucf = new Set<Contact>();
        //List<Contact> cont_update_ucf = new List<Contact>();
        List<Contact> contactsToUpdate = new List<Contact>();

        Transient List<Contact> contacts = [Select Id, crta__CT_Matricule__c from Contact];

        for (Contact contact : contacts) {
            contactsMap.put(contact.crta__CT_Matricule__c, contact);
        }

        for (Integer i = 1; i < csvFileLines.size(); i++) {
            if (csvFileLines[i] != null && csvFileLines[i] != '') {
                Transient String[] csvRecordData = csvFileLines[i].split(separator_line);

                if (csvRecordData.size() > 1) {
                    Transient String matricule = csvRecordData[0];

                    if (!contactsMap.containsKey(matricule)) {
                        system.debug('>>>>>  #######  Contact not found - contact matricule : ' + matricule + ' ##### <<<<<<<');
                    } else  {
                        Transient Contact contact = contactsMap.get(matricule);
                        
                        system.debug('typeDAbsenceMap : ' + typeDAbsenceMap);
                        String typeAbscence =  typeDAbsenceMap.get(csvRecordData[5]) ;
                        if (String.isBlank(typeAbscence)) {
                            system.debug('>>>  ####  typeAbscence not found - typeAbscence : ' + typeAbscence  + ' At CSV line : ' + i + ' ##### <<<<<<<');
                        }
                        try {
                            crta__BDU_Data_Absence__c absence = new crta__BDU_Data_Absence__c();

                            absence.crta__CT_Salarie__c = contact.Id;
                            absence.crta__CT_Date_debut__c = Date.parse(csvRecordData[2]);
                            absence.crta__CT_Date_fin__c = Date.parse(csvRecordData[3]);
                            absence.type_d_absence_detaillee__c = csvRecordData[5];
                            absence.crta__Type_d_absence__c = typeAbscence;
                            absences.add(absence);
                            //absence.nb_jours__c  =  // ???Integer noOfDays = startDate.daysBetween(endDate);
                            contact.AccountId = id_account;
                            cont_set_ucf.add(contact);

                        } catch (Exception e) {
                            System.debug('>>>###### ImportFilesFutureController - e.getMessage() : ' + e.getMessage() + ' #################<<<<<');
                        }
                    }

                }
            }
        }
        contactsToUpdate.addAll(cont_set_ucf);
        System.debug('>>>####### absences.size() : ' + absences.size());
        Database.insert(absences, false);
        update contactsToUpdate;

    }

// --------------------- END CA   Import Absence---------------------------------------//




// --------------------- CA Import Salariale---------------------------------------// //    crta__Brut_fiscal__c TODO

    @future
    public Static void importSalarialeCATechnologies(List<String> csvFileLines) {
        Transient String separator_line = ';';

        ID id_account = [select id from Account where Name = 'CA Technologie'].id;

        Transient List<crta__Salaire__c> add_sal_ucf = new List<crta__Salaire__c>();
        Transient Map<String, Contact> contact_map_ucf = new Map<String, Contact>();
        Transient Set<Contact> cont_set_ucf = new Set<Contact>();
        Transient List<Contact> cont_update_ucf = new List<Contact>();

        Transient List<Contact> contacts = [Select Id, crta__CT_Matricule__c from Contact];

        for (Contact contact : contacts) {
            contact_map_ucf.put(contact.crta__CT_Matricule__c, contact);
        }

        for (Integer i = 1; i < csvFileLines.size(); i++) {
            system.debug('index csvFileLines:' + i);
            if (!String.isBlank(csvFileLines[i])) {
                Transient String[] csvRecordData = csvFileLines[i].split(separator_line);

                Transient String matricule;
                if (csvRecordData.size() > 1) {
                    matricule = csvRecordData[0];


                    if (!contact_map_ucf.containsKey(matricule)) {
                        //  system.debug('>>>>>  #######  Contact not found - contact matricule : ' + matricule + ' ##### <<<<<<<');
                        throw new MyException('>>>>>  #######  Contact not found - contact matricule : ' + matricule + ' ##### <<<<<<<');
                    } else {
                        // system.debug('####################### Matricule : '+matricule);
                        //system.debug('####################" csvRecordData : '+csvRecordData);
                        Transient Contact contact = contact_map_ucf.get(matricule);
                        // try{
                        Transient crta__Salaire__c salariale = new crta__Salaire__c();

                        salariale.crta__Salarie__c = contact.Id;

                        String mois = csvRecordData[2].substring(4, csvRecordData[2].length());
                        String annee = csvRecordData[2].substring(0, csvRecordData[2].length() - 2);

                        String theDate =  '01/' + mois + '/' + annee;
                        // system.debug('####################### theDate : ' +theDate );

                        //system.debug('####################### csvRecordData[2] : ' +csvRecordData[2] );

                        // crta__CT_Date_de_remuneration__c 01= jour à ajouter
                        salariale.crta__CT_Date_de_remuneration__c = Date.parse(theDate);
                        salariale.crta__CT_Brut_SS__c  =  (csvRecordData[3] != '') ? Decimal.valueOf(csvRecordData[3].replaceAll(',', '.').trim().replace(' ', '')) : 0;
                        salariale.crta__CT_Salaire_de_base_mensuel_theorique__c =  (csvRecordData[3] != '') ? Decimal.valueOf(csvRecordData[3].replaceAll(',', '.').trim().replace(' ', '')) : 0;
                        salariale.crta__CT_Charges_salariales_mensuelles__c  = (csvRecordData[4] != '') ? Decimal.valueOf(csvRecordData[4].replaceAll(',', '.').trim().replace(' ', '')) : 0;
                        salariale.crta__CT_Charges_patronales_mensuelles__c = (csvRecordData[5] != '') ? Decimal.valueOf(csvRecordData[5].replaceAll(',', '.').trim().replace(' ', '')) : 0;
                        salariale.crta__CT_Nombre_d_heures_supplementaires__c = (csvRecordData.size() > 7 && csvRecordData[6] != '') ? Decimal.valueOf(csvRecordData[6].replaceAll(',', '.').trim().replace(' ', '')) : 0;
                        salariale.crta__CT_Montant_des_avantages_en_nature__c = (csvRecordData.size() > 7 && csvRecordData[7] != '') ? Decimal.valueOf(csvRecordData[7].replaceAll(',', '.').trim().replace(' ', '')) : 0;



                        add_sal_ucf.add(salariale);
                        contact.AccountId = id_account;
                        cont_set_ucf.add(contact);
                        //   }
                        //atch(Exception e) {
                        //System.debug('>>>###### ImportFilesFutureController - e.getMessage() : ' + e.getMessage() +' #################<<<<<');
                        // }
                    }
                } else
                    throw new MyException('ligne sans colonnes:' + csvFileLines[i]);
            }
            //else
            //  throw new MyException('ligne vide:'+csvFileLines[i] + 'at position '+ i);
        }

        cont_update_ucf.addAll(cont_set_ucf);
        //insert add_sal_ucf;

        System.debug('>>>### add_sal_ucf.size() : ' + add_sal_ucf.size()); // TODO Clean
        System.debug('>>>### add_sal_ucf : ' + add_sal_ucf); // TODO Clean

        insert add_sal_ucf;
        /*
        Database.SaveResult [] saveResSalaires = Database.insert(add_sal_ucf, false);

        for (Database.SaveResult sr : saveResSalaires) {

        // Operation failed, so get all errors
        if (!sr.isSuccess()) {
        for (Database.Error err : sr.getErrors()) {
        System.debug('>>> ##### The following error has occurred. #####<<<');
        System.debug('>>> ##### err.getStatusCode() :: ' + err.getStatusCode() + ' err.getMessage() :: ' + err.getMessage() + '##### <<<');
        System.debug('Remuneration_annuelle__c fields that affected this error:: ' + err.getFields() + '##### <<<');
        }

        }
        }
        //*/
        update cont_update_ucf;

    }


// ---------------------  END Import Salariale---------------------------------------//

// --------------------- CA Import Diplome---------------------------------------// 

    @future
    public Static void importdiplome(List<String> csvFileLines) {
        Transient String separator_line = ';';

        ID id_account = [select id from Account where Name = 'CA Technologie'].id;

        Transient Map<String, Contact> contact_map = new Map<String, Contact>();

        for (Contact contact : [Select Id, crta__CT_Matricule__c,crta__Niveau_de_Diplome__c, Date_du_diplome__c from Contact]) {
            contact_map.put(contact.crta__CT_Matricule__c, contact);
        }

        string texte_error='';
        system.debug('------taille des lignes----'+ csvFileLines.size());

        for (Integer i = 1; i < csvFileLines.size(); i++) {

            system.debug('----step 10---');
            if (!String.isBlank(csvFileLines[i])) {
                Transient String[] csvRecordData = csvFileLines[i].split(separator_line);

                system.debug('----step 20---');
                Transient String matricule;
                if (csvRecordData.size() < 5) 
                      continue ; 

                system.debug('----step 25---');                
                matricule = csvRecordData[0];

                if (!contact_map.containsKey(matricule)) {
                     texte_error = texte_error + 'Matricule inconnu ' + matricule +'\r\n';
                     continue ; 
                }
                
                system.debug('----step 30---');
                contact c = contact_map.get(matricule) ; 
                integer niv1 = 0 ;
                if(csvRecordData[5]!=null && csvRecordData[5]!=' - ' )
                    niv1 = integer.valueof(csvRecordData[5].left(2));

                integer niv2 = 0 ; 
                if(c.crta__Niveau_de_Diplome__c!=null) 
                     niv2 = integer.valueof(c.crta__Niveau_de_Diplome__c.left(2)) ;               

                if(niv1>niv2) {
                     c.crta__Niveau_de_Diplome__c=csvRecordData[5];
                     
                     if(csvRecordData[2] != '')
                     	c.Date_du_diplome__c= date.parse(csvRecordData[2]);
                }

             }
        }
        
        update contact_map.values();
        

        // on envoie le mail de fin
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    
        List<String> sendTo = new List<String>();
        sendTo.add(UserInfo.getUserEmail());  // A modifier
        mail.setToAddresses(sendTo);
           
        if(texte_error.length()>0) {
            // Envoi du mail avec texte_error
            mail.setSubject('Import diplome : Il y a des erreurs ');
            mail.setHtmlBody(texte_error);
        } else {
            // il n'y a pas d'erreur, on peut mettre à jour
            update contact_map.values();
            mail.setSubject('Import Diplome : Sans erreur ');
            mail.setHtmlBody('Plus besoin de tourner');            
       }
       mails.add(mail);
       Messaging.sendEmail(mails);

        

    }


//

    

}