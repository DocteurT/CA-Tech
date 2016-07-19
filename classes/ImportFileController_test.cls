@isTest(seeAllData=false)
private with sharing class ImportFileController_test 
{
    static testMethod void test2()
    {
        
        list<string> contact = new List<String>();

        contact.add('Matricule BDU;Alias;Nom usuel;Prénom;Catégorie;Sexe;Date de naissance;Date d entrée GIE;Date Ancienneté Groupe CA;Nationalité;Date Fin Prévisionnelle;Date de sortie ;Motif de Départ;Handicapé');
        contact.add('008 - 0000001;ET00001;JABALLAH;HICHEM;CADRE DE DIRECTION;Masculin;21/11/1959;01/01/2011;01/04/2007;France;;31/12/2999;;Non');
        contact.add('008 - 0000100;ET00100;ABALLAIN;PHILIPPE;CLASSE III;Masculin;24/04/1966;01/01/2011;21/01/1992;France;;31/12/2999;;Non');
        contact.add('008 - 0000101;ET00101;DE LAMBERTERIE ABINAL;HELENE;CLASSE III;Féminin;05/07/1951;01/01/2011;22/07/1974;France;;31/03/2014;Retraite;Non');

        ImportFilesFuture1Controller.importContacts(contact,system.today());



        crta__Param_calc_auto__c a = new crta__Param_calc_auto__c(Horaire_moyen_mensuel_Temp_plein__c=100);
        insert a ; 

        Account acc = new Account(Name='CA Technologie');
        insert acc;

        list<string> orga = new List<String>();       
        orga.add('Matricule BDU;Alias;Date de Début Orga;Date de Fin Orga;Gie;Filière;Direction;Département;Service;Unité organisationnelle;;');
        orga.add('008 - 0000001;ET00001;01/01/2012;;DG GIE;DG GIE;DG GIE;DG GIE;DG GIE;DG GIE;;');
        orga.add('008 - 0000100;ET00100;01/01/2012;30/04/2014;DG GIE;MOE ED;MOE ED CENTRALE ET ACTIVITES SPECIFIQUES;ASR   ARCHITECTURE ET SUPPORT;ASR   ARCHITECTURE OUTILS ET SUPPORT;U7   SUPPORT ET OUTILS;;');

        ImportFilesFuture1Controller.importAffec(orga,'organisation',Date.newInstance(2015, 1, 1),Date.newInstance(2015, 12, 31));


        list<string> affec = new List<String>();       
        affec.add('Matricule BDU;Alias;Date Début Ct GIE;Date Fin Ct;Type de Contrat;Motif Recours CDD;check double');
        affec.add('008 - 0000001;ET00001;01/01/2011;;CDI Titulaire;;');
        affec.add('008 - 0000100;ET00100;01/01/2011;;CDI Titulaire;;');

        ImportFilesFuture1Controller.importAffec(affec,'affectation',Date.newInstance(2015, 1, 1),Date.newInstance(2015, 12, 31));
  

        list<string> classification = new List<String>();       
        classification.add('Matricule BDU;Alias;Date Début Classification GIE;Date Fin Classification;Niveau;Date Effet Pce;Pce');
        classification.add('008 - 0000001;ET00001;01/01/2011;;CADRE DE DIRECTION;01/01/2011;2');
        classification.add('008 - 0000001;ET00001;01/01/2011;;CADRE DE DIRECTION;01/07/2011;2');

        ImportFilesFuture1Controller.importAffec(classification,'classification',Date.newInstance(2015, 1, 1),Date.newInstance(2015, 12, 31));

        list<string> temps = new List<String>();       
        temps.add('Matricule BDU;Alias;Date Effet Tps Ctuel GIE;Date Fin Tps Ctuel;Temps de Travail (%)');
        temps.add('008 - 0000001;ET00001;01/01/2011;;100');
        temps.add('008 - 0000100;ET00100;01/01/2011;;100');

        ImportFilesFuture1Controller.importAffec(temps,'temps de travail',Date.newInstance(2015, 1, 1),Date.newInstance(2015, 12, 31));
           
        
        
        list<string> salaireCAtech = new List<String>();  
        salaireCAtech.add('Matricule BDU;Alias;Année et mois de rémunération;Salaire Mensuel Brut;Charges salariales mensuelles;Charges patronales mensuelles;Nombre d heures supplémentaires/complémentaires;Montant des avantage en nature;;;;');
        salaireCAtech.add('008 - 0000001;ET00001;201401;90034;39;11331;48;46624;17;;;');
        salaireCAtech.add('008 - 0000001;ET00001;201402;18642;65;4728;11;12540;52;;2384;26');
         
        ImportFilesFuture1Controller.importSalarialeCATechnologies (salaireCAtech);           

                   
        
        list<string> absence = new List<String>();  
        absence.add('Matricule BDU;Alias;Date de début absence;Date de fin absence;Motif absence;Libellé Absence;Témoin prolongation;Témoin Matin;Témoin Aprèm');
        absence.add('008 - 0000001;ET00001;06/03/2014;10/03/2014;CPN;CON : CONGES PAYES ANNUELS;;;');
        absence.add('008 - 0000001;ET00001;14/04/2014;18/04/2014;CPN;CON : CONGES PAYES ANNUELS;;;');
         
        ImportFilesFuture1Controller.importAbsenceExtractionsituation (absence);           

           
        list<string> formation = new List<String>();  
        formation.add('Matricule BDU;Alias;Date de début;Durée (heures);Durée;Unité Durée;Type Formation;Catégorie Formation;Finalité Formation;Formation;Organisme;Imputable Fiscalement;Nb Hrs In Tps Trav;Dt Nb Hrs In Tps Trav DIF/CPF;Nb Hrs Hors Tps Trav;Dt Nb Hrs Hors Tps Trav DIF/CPF;Domaine du Stage;Thème du Stage;Coût ADV;Coût AHE;Coût ARE;Coût ATR;Coût FFF;Coût HEB;Coût HON;Coût INS;Coût IRE;Coût REC;Coût REM;Coût RES;Coût RHT;Coût TDI;Coût TIK;Coût à paramétrer si <> 0;Interne / Externe ?');
        formation.add('008 - 0000001;ET00908;03/01/2013;19;19;Heure;Droit Individuel de Formation;Développement des compétences;Acquisition/Entretien/Perfectionnement;08-COM0001 - Anglais;WSI - WALL STREET INSTITUTE;OUI;0;0;19;19;DOM000002 - DEVELOPPEMENT PERSONNEL;TH000041 - LANGUES ETRANGERES;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;Externe');
        formation.add('008 - 0000001;ET00284;07/01/2013;23,4;3;Jour;Plan de Formation;Adaptation au poste travail/maintien emploi;Adaptation;08-TEC1433 - EPTICA Utilisateur;EPTICA - EPTICA;OUI;23,4;0;0;0;DOM000006 - INFORMATIOUE & RESEAU;TH000068 - LOGICIELS - PROGICIELS;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;Interne');         

        ImportFilesFuture1Controller.importformation (formation);           


        list<string> med = new List<String>();  
        med.add('Matricule BDU;Alias;Date d échéance;Type de test;Motif visite;Rsultat visite;Statut visite');
        med.add('008 - 0000001;ET00100;04/02/2014;VISITE MEDICALE ANNUELLE;Périodique;APTE APRES VISITE MEDICALE;Terminé');
        med.add('008 - 0000001;ET00102;24/02/2014;VISITE MEDICALE ANNUELLE;Périodique;APTE APRES VISITE MEDICALE;Terminé');

        ImportFilesFuture1Controller.importMedecineDuTravail (med);           





        ImportFilesController ifc = new ImportFilesController ();
        ifc.csvFileBody= Blob.valueOf(
              'CODE;LIBELLE;PARENT;NIVEAU;CONVENTION COLLECTIVE;DATE OUVERTURE;DATE FERMETURE;ORIGINE\r\n'+
              '08;CIE VOSGIENNE DE LA CHAUSSURE;GRP;SOC;;1949-01-01;;GXP\r\n'+
              '08PRO;CVC PRODUCTION;08;S21;1580;1949-01-01;;GXP\r\n'+
              'P81;PRODUCTION CHAMPIGNEULES;08PRO;S22;;1949-01-01;;GXP\r\n'+
              'P8104;PRODUCTION CHAMPIGNEULLES;P81;S23;;2006-09-01;;GXP\r\n'+
              'P8105;ADMINISTRATION PRODUCTION;P81;S23;;2006-09-01;;GXP\r\n'+
              'P8104001;PRODUCTION;P8104;S24;;2006-09-01;;GXP\r\n'+
              'P8105001;DIRECTION INDUSTRIELLE;P8105;S24;;2006-09-01;;GXP\r\n'+
              '8603081;CONDITIONNEMENT;P8104001;S25;;2006-09-01;;GXP\r\n'+
              '8604081;ANNEXES ILOTS;P8104001;S25;;2006-09-01;;GXP\r\n'
             ); 

        ifc.upload();


// importSalairesAnnuels       
       

   }
}