@isTest(SeeAllData=true)
public class bduValuesCalcRequete_test 
{
    public static testMethod void bduBatch_test() 
    {
        /*
        crta__Param_calc_auto__c options = new crta__Param_calc_auto__c(crta__publishNewValues__c =false);
        insert options;
        */
        BduValuesCalcRequete.codecoverage();
        BduValuesCalcRequete.codecoverage2();
        BduValuesCalcRequete.codecoverage3();
        BduValuesCalcRequete.codecoverage4();
        
        crta__BDU_Chapitre__c chapitre;
        try {
            chapitre = [Select Id From crta__BDU_Chapitre__c Where Name='Données sociales' Limit 1];
        } catch(Exception e) {
            chapitre = new crta__BDU_Chapitre__c(
                Name='Données sociales',
                crta__CT_Order__c = 1
            );
            insert chapitre; 
        }
        
        crta__BDU_Domaine__c domaine;
        try {
            domaine = [Select Id From crta__BDU_Domaine__c Where Name='Emploi' Limit 1];
        } catch(Exception e) {
            domaine = new crta__BDU_Domaine__c(
                Name='Emploi',
                crta__CT_BDU_Chapitre__c = chapitre.id,
                crta__CT_Affiche__c = true,
                crta__CT_Slug__c = 'emploi'
            );
            insert domaine; 
        }

        crta__BDU_Indicateur__c indic;
        try {
            indic = [Select
            Id, crta__CT_isSOQL__c, crta__CT_wantedColumn__c, crta__ct_columnLabels__c, crta__CT_Afficher_le_tableau__c, crta__CT_Afficher_le_graphique__c, crta__CT_Annuel__c, crta__CT_Semestriel__c, crta__CT_Code__c, crta__CT_Trimestriel__c, crta__CT_Bimestriel__c, crta__CT_Mensuel__c, totaux_a_afficher__c,libelles_elements_tableau__c, totaux_via_batch__c 
             From crta__BDU_Indicateur__c Where crta__CT_Code__c = '--IND01103' Limit 1];
        } catch(Exception e) {
            indic = new crta__BDU_Indicateur__c(
                Name = 'Effectif total au 31/12 (tous salariés)',
                crta__CT_Libelle__c = 'Effectif total au 31/12 (tous salariés)',
                crta__CT_Article__c = 'Art.R.2323-17',
                crta__CT_BDU_Domaine__c = domaine.Id,
                crta__CT_Code__c = '--IND01103',
                crta__CT_Code_Applicable__c = 'Code du travail',
                crta__CT_Description__c = 'Par catégorie et par sexe.             1 salarié compte 1, quel que soit son temps de travail.          CDI, CDD, Apprentissage et alternance ; hors stagiaires)',
                crta__CT_Emplacement__c = 'Bilan Social',
                crta__CT_Unite_de_mesure__c = 'ETP, effectif',
                crta__CT_Affiche__c = true,
                crta__CT_Afficher_le_tableau__c = true, 
                crta__CT_Afficher_le_graphique__c = true,
                crta__CT_Annuel__c = true,
                crta__CT_Semestriel__c = true,
                crta__CT_Trimestriel__c = true,
                crta__CT_Bimestriel__c = true,
                crta__CT_Mensuel__c = true,
                crta__CT_isSOQL__c = false,
                totaux_a_afficher__c = null
            );
            insert indic; 
        }

        List<crta.bduBatchParam> param = new List<crta.bduBatchParam>();
        Date debut = Date.newInstance(1990,01,01);
        Date fin = Date.newInstance(2090,12,31);
        param.add(new crta.bduBatchParam(indic, 'Societe A', null, null, null, null, debut, fin, 2014, 1, 1, 1, 1 ));

        bduBatchRequete batch = new bduBatchRequete( param );
        Database.executeBatch( batch, 1 );  
        crta__BDU_Indicateur__c indic2;
        try {
            indic2 = [Select 
                Id, crta__CT_isSOQL__c, crta__CT_wantedColumn__c, crta__ct_columnLabels__c, crta__CT_Afficher_le_tableau__c, crta__CT_Afficher_le_graphique__c, crta__CT_Annuel__c, crta__CT_Semestriel__c, crta__CT_Code__c, crta__CT_Trimestriel__c, crta__CT_Bimestriel__c, crta__CT_Mensuel__c, totaux_a_afficher__c,libelles_elements_tableau__c, totaux_via_batch__c
             From crta__BDU_Indicateur__c Where crta__CT_Code__c = 'IND01123' Limit 1];
        } catch(Exception e) {
            indic2 = new crta__BDU_Indicateur__c(
                Name = 'Effectif total au 31/12 (tous salariés)',
                crta__CT_Libelle__c = 'Effectif total au 31/12 (tous salariés)',
                crta__CT_Article__c = 'Art.R.2323-17',
                crta__CT_BDU_Domaine__c = domaine.Id,
                crta__CT_Code__c = 'IND01123',
                crta__CT_Code_Applicable__c = 'Code du travail',
                crta__CT_Description__c = 'Par catégorie et par sexe.             1 salarié compte 1, quel que soit son temps de travail.          CDI, CDD, Apprentissage et alternance ; hors stagiaires)',
                crta__CT_Emplacement__c = 'Bilan Social',
                crta__CT_Unite_de_mesure__c = 'ETP, effectif',
                crta__CT_Affiche__c = true,
                crta__CT_Afficher_le_tableau__c = true, 
                crta__CT_Afficher_le_graphique__c = true,
                crta__CT_Annuel__c = true,
                crta__CT_Semestriel__c = true,
                crta__CT_Trimestriel__c = true,
                crta__CT_Bimestriel__c = true,
                crta__CT_Mensuel__c = true,
                crta__CT_isSOQL__c = false,
                totaux_a_afficher__c=null
            );
            insert indic2; 
        }

        List<crta.bduBatchParam> param2 = new List<crta.bduBatchParam>();
        Date debut2 = Date.newInstance(1990,01,01);
        Date fin2 = Date.newInstance(2090,12,31);
        param2.add(new crta.bduBatchParam(indic2, 'Societe A', null, null, null, null, debut2, fin2, 2014, 1, 1, 1, 1 ));

        bduBatchRequete batch2 = new bduBatchRequete( param2 );
        Database.executeBatch( batch2, 1 );  

        crta__BDU_Indicateur__c indic3;
        try {
            indic3 = [Select 
                Id, crta__CT_isSOQL__c, crta__CT_wantedColumn__c, crta__ct_columnLabels__c, crta__CT_Afficher_le_tableau__c, crta__CT_Afficher_le_graphique__c, crta__CT_Annuel__c, crta__CT_Semestriel__c, crta__CT_Code__c, crta__CT_Trimestriel__c, crta__CT_Bimestriel__c, crta__CT_Mensuel__c, totaux_a_afficher__c,libelles_elements_tableau__c,totaux_via_batch__c
             From crta__BDU_Indicateur__c Where crta__CT_Code__c = '--IND01119' Limit 1];
        } catch(Exception e) {
            indic3 = new crta__BDU_Indicateur__c(
                Name = 'Effectif total au 31/12 (tous salariés)',
                crta__CT_Libelle__c = 'Effectif total au 31/12 (tous salariés)',
                crta__CT_Article__c = 'Art.R.2323-17',
                crta__CT_BDU_Domaine__c = domaine.Id,
                crta__CT_Code__c = '--IND01119',
                crta__CT_Code_Applicable__c = 'Code du travail',
                crta__CT_Description__c = 'Par catégorie et par sexe.             1 salarié compte 1, quel que soit son temps de travail.          CDI, CDD, Apprentissage et alternance ; hors stagiaires)',
                crta__CT_Emplacement__c = 'Bilan Social',
                crta__CT_Unite_de_mesure__c = 'ETP, effectif',
                crta__CT_Affiche__c = true,
                crta__CT_Afficher_le_tableau__c = true, 
                crta__CT_Afficher_le_graphique__c = true,
                crta__CT_Annuel__c = true,
                crta__CT_Semestriel__c = true,
                crta__CT_Trimestriel__c = true,
                crta__CT_Bimestriel__c = true,
                crta__CT_Mensuel__c = true,
                crta__CT_isSOQL__c = false,
                totaux_a_afficher__c=null
            );
            insert indic3; 
        }

        List<crta.bduBatchParam> param3 = new List<crta.bduBatchParam>();
        Date debut3 = Date.newInstance(1990,01,01);
        Date fin3 = Date.newInstance(2090,12,31);
        param3.add(new crta.bduBatchParam(indic3, 'Societe A', null, null, null, null, debut3, fin3, 2014, 1, 1, 1, 1 ));

        bduBatchRequete batch3 = new bduBatchRequete( param3 );
        Database.executeBatch( batch3, 1 );  

        crta__BDU_Indicateur__c indic4;
        try {
            indic4 = [Select  
                Id, crta__CT_isSOQL__c, crta__CT_wantedColumn__c, crta__ct_columnLabels__c, crta__CT_Afficher_le_tableau__c, crta__CT_Afficher_le_graphique__c, crta__CT_Annuel__c, crta__CT_Semestriel__c, crta__CT_Code__c, crta__CT_Trimestriel__c, crta__CT_Bimestriel__c, crta__CT_Mensuel__c, totaux_a_afficher__c,libelles_elements_tableau__c,totaux_via_batch__c
            From crta__BDU_Indicateur__c Where crta__CT_Code__c = '--IND01101' Limit 1];
        } catch(Exception e) {
            indic4 = new crta__BDU_Indicateur__c(
                Name = 'Effectif total au 31/12 (tous salariés)',
                crta__CT_Libelle__c = 'Effectif total au 31/12 (tous salariés)',
                crta__CT_Article__c = 'Art.R.2323-17',
                crta__CT_BDU_Domaine__c = domaine.Id,
                crta__CT_Code__c = '--IND01101',
                crta__CT_Code_Applicable__c = 'Code du travail',
                crta__CT_Description__c = 'Par catégorie et par sexe.             1 salarié compte 1, quel que soit son temps de travail.          CDI, CDD, Apprentissage et alternance ; hors stagiaires)',
                crta__CT_Emplacement__c = 'Bilan Social',
                crta__CT_Unite_de_mesure__c = 'ETP, effectif',
                crta__CT_Affiche__c = true,
                crta__CT_Afficher_le_tableau__c = true,
                crta__CT_Afficher_le_graphique__c = true,
                crta__CT_Annuel__c = true,
                crta__CT_Semestriel__c = true,
                crta__CT_Trimestriel__c = true,
                crta__CT_Bimestriel__c = true,
                crta__CT_Mensuel__c = true,
                crta__CT_isSOQL__c = false,
                totaux_a_afficher__c=null
            );
            insert indic4; 
        }
        List<crta.bduBatchParam> param4 = new List<crta.bduBatchParam>();
        Date debut4 = Date.newInstance(1990,01,01);
        Date fin4 = Date.newInstance(2090,12,31);
        param4.add(new crta.bduBatchParam(indic4, 'Societe A', null, null, null, null, debut4, fin4, 2014, 1, 1, 1, 1 ));

        bduBatchRequete batch4 = new bduBatchRequete( param4 );
        Database.executeBatch( batch4, 1 );  


        crta__BDU_Indicateur__c indic5;
        try {
            indic5 = [Select 
                Id, crta__CT_isSOQL__c, crta__CT_wantedColumn__c, crta__ct_columnLabels__c, crta__CT_Afficher_le_tableau__c, crta__CT_Afficher_le_graphique__c, crta__CT_Annuel__c, crta__CT_Semestriel__c, crta__CT_Code__c, crta__CT_Trimestriel__c, crta__CT_Bimestriel__c, crta__CT_Mensuel__c, totaux_a_afficher__c,libelles_elements_tableau__c,totaux_via_batch__c 
            From crta__BDU_Indicateur__c Where crta__CT_Code__c = '--IND01117' Limit 1];
        } catch(Exception e) {
            indic5 = new crta__BDU_Indicateur__c(
                Name = 'Effectif total au 31/12 (tous salariés)',
                crta__CT_Libelle__c = 'Effectif total au 31/12 (tous salariés)',
                crta__CT_Article__c = 'Art.R.2323-17',
                crta__CT_BDU_Domaine__c = domaine.Id,
                crta__CT_Code__c = '--IND01117',
                crta__CT_Code_Applicable__c = 'Code du travail',
                crta__CT_Description__c = 'Par catégorie et par sexe.             1 salarié compte 1, quel que soit son temps de travail.          CDI, CDD, Apprentissage et alternance ; hors stagiaires)',
                crta__CT_Emplacement__c = 'Bilan Social',
                crta__CT_Unite_de_mesure__c = 'ETP, effectif',
                crta__CT_Affiche__c = true,
                crta__CT_Afficher_le_tableau__c = true, 
                crta__CT_Afficher_le_graphique__c = true,
                crta__CT_Annuel__c = true,
                crta__CT_Semestriel__c = true,
                crta__CT_Trimestriel__c = true,
                crta__CT_Bimestriel__c = true,
                crta__CT_Mensuel__c = true,
                crta__CT_isSOQL__c = false,
                totaux_a_afficher__c = null
            );
            insert indic5; 
        }

        List<crta.bduBatchParam> param5 = new List<crta.bduBatchParam>();
        Date debut5 = Date.newInstance(1990,01,01);
        Date fin5 = Date.newInstance(2090,12,31);
        param5.add(new crta.bduBatchParam(indic5, 'Societe A', null, null, null, null, debut5, fin5, 2014, 1, 1, 1, 1 ));

        bduBatchRequete batch5 = new bduBatchRequete( param5 );
        Database.executeBatch( batch5, 1 );  
    }
}