@isTest(SeeAllData=true)
public class bduCalcRemunerations_test 
{
    public static testMethod void bduBatch_test()
    {
        String stringDate = '01/01/2015';
        Date refDate = Date.parse( stringDate );
        
        Contact e = [select id from Contact limit 1];
        
        crta__Salaire__c s = new crta__Salaire__c (
            crta__CT_Brut_SS__c = 1566.49,      
            crta__CT_Charges_salariales_mensuelles__c = 668.13, 
            crta__CT_Date_de_remuneration__c = Date.parse('27/01/2014'),
            crta__CT_Nombre_d_heures_theoriques_mensuelles__c = 151.67,
            crta__CT_Prime_equipe_soiree__c = 0.0,
            crta__CT_Salaire_de_base_mensuel_theorique__c = 3345.0,    
            crta__Salarie__c = e.id,
            Net_payer__c = 2474.92
        );
        insert s;
        s = new crta__Salaire__c (
            crta__CT_Brut_SS__c = 1566.49,      
            crta__CT_Charges_salariales_mensuelles__c = 668.13, 
            crta__CT_Date_de_remuneration__c = Date.parse('27/01/2014'),
            crta__CT_Nombre_d_heures_theoriques_mensuelles__c = 151.67,
            crta__CT_Prime_equipe_soiree__c = 0.0,
            crta__CT_Salaire_de_base_mensuel_theorique__c = 3345.0,    
            crta__Salarie__c = e.id,
            Net_payer__c = 2474.92
        );
        insert s;
        s = new crta__Salaire__c (
            crta__CT_Brut_SS__c = 1566.49,      
            crta__CT_Charges_salariales_mensuelles__c = 668.13, 
            crta__CT_Date_de_remuneration__c = Date.parse('27/01/2014'),
            crta__CT_Nombre_d_heures_theoriques_mensuelles__c = 151.67,
            crta__CT_Prime_equipe_soiree__c = 0.0,
            crta__CT_Salaire_de_base_mensuel_theorique__c = 3345.0,    
            crta__Salarie__c = e.id,
            Net_payer__c = 2474.92
        );
        insert s;
        s = new crta__Salaire__c (
            crta__CT_Brut_SS__c = 1566.49,      
            crta__CT_Charges_salariales_mensuelles__c = 668.13, 
            crta__CT_Date_de_remuneration__c = Date.parse('27/01/2014'),
            crta__CT_Nombre_d_heures_theoriques_mensuelles__c = 151.67,
            crta__CT_Prime_equipe_soiree__c = 0.0,
            crta__CT_Salaire_de_base_mensuel_theorique__c = 3345.0,    
            crta__Salarie__c = e.id,
            Net_payer__c = 2474.92
        );
        insert s;
        s = new crta__Salaire__c (
            crta__CT_Brut_SS__c = 1566.49,      
            crta__CT_Charges_salariales_mensuelles__c = 668.13, 
            crta__CT_Date_de_remuneration__c = Date.parse('27/01/2014'),
            crta__CT_Nombre_d_heures_theoriques_mensuelles__c = 151.67,
            crta__CT_Prime_equipe_soiree__c = 0.0,
            crta__CT_Salaire_de_base_mensuel_theorique__c = 3345.0,    
            crta__Salarie__c = e.id,
            Net_payer__c = 2474.92
        );
        insert s;
        s = new crta__Salaire__c (
            crta__CT_Brut_SS__c = 1566.49,      
            crta__CT_Charges_salariales_mensuelles__c = 668.13, 
            crta__CT_Date_de_remuneration__c = Date.parse('27/01/2014'),
            crta__CT_Nombre_d_heures_theoriques_mensuelles__c = 151.67,
            crta__CT_Prime_equipe_soiree__c = 0.0,
            crta__CT_Salaire_de_base_mensuel_theorique__c = 3345.0,    
            crta__Salarie__c = e.id,
            Net_payer__c = 2474.92
        );
        insert s;
        s = new crta__Salaire__c (
            crta__CT_Brut_SS__c = 1566.49,      
            crta__CT_Charges_salariales_mensuelles__c = 668.13, 
            crta__CT_Date_de_remuneration__c = Date.parse('27/01/2014'),
            crta__CT_Nombre_d_heures_theoriques_mensuelles__c = 151.67,
            crta__CT_Prime_equipe_soiree__c = 0.0,
            crta__CT_Salaire_de_base_mensuel_theorique__c = 3345.0,    
            crta__Salarie__c = e.id,
            Net_payer__c = 2474.92
        );
        insert s;
        s = new crta__Salaire__c (
            crta__CT_Brut_SS__c = 1566.49,      
            crta__CT_Charges_salariales_mensuelles__c = 668.13, 
            crta__CT_Date_de_remuneration__c = Date.parse('27/01/2014'),
            crta__CT_Nombre_d_heures_theoriques_mensuelles__c = 151.67,
            crta__CT_Prime_equipe_soiree__c = 0.0,
            crta__CT_Salaire_de_base_mensuel_theorique__c = 3345.0,    
            crta__Salarie__c = e.id,
            Net_payer__c = 2474.92
        );
        insert s;
        s = new crta__Salaire__c (
            crta__CT_Brut_SS__c = 1566.49,      
            crta__CT_Charges_salariales_mensuelles__c = 668.13, 
            crta__CT_Date_de_remuneration__c = Date.parse('27/01/2014'),
            crta__CT_Nombre_d_heures_theoriques_mensuelles__c = 151.67,
            crta__CT_Prime_equipe_soiree__c = 0.0,
            crta__CT_Salaire_de_base_mensuel_theorique__c = 3345.0,    
            crta__Salarie__c = e.id,
            Net_payer__c = 2474.92
        );
        insert s;
        s = new crta__Salaire__c (
            crta__CT_Brut_SS__c = 1566.49,      
            crta__CT_Charges_salariales_mensuelles__c = 668.13, 
            crta__CT_Date_de_remuneration__c = Date.parse('27/01/2014'),
            crta__CT_Nombre_d_heures_theoriques_mensuelles__c = 151.67,
            crta__CT_Prime_equipe_soiree__c = 0.0,
            crta__CT_Salaire_de_base_mensuel_theorique__c = 3345.0,    
            crta__Salarie__c = e.id,
            Net_payer__c = 2474.92
        );
        insert s;
        s = new crta__Salaire__c (
            crta__CT_Brut_SS__c = 1566.49,      
            crta__CT_Charges_salariales_mensuelles__c = 668.13, 
            crta__CT_Date_de_remuneration__c = Date.parse('27/01/2014'),
            crta__CT_Nombre_d_heures_theoriques_mensuelles__c = 151.67,
            crta__CT_Prime_equipe_soiree__c = 0.0,
            crta__CT_Salaire_de_base_mensuel_theorique__c = 3345.0,    
            crta__Salarie__c = e.id,
            Net_payer__c = 2474.92
        );
        insert s;
        s = new crta__Salaire__c (
            crta__CT_Brut_SS__c = 1566.49,      
            crta__CT_Charges_salariales_mensuelles__c = 668.13, 
            crta__CT_Date_de_remuneration__c = Date.parse('27/01/2014'),
            crta__CT_Nombre_d_heures_theoriques_mensuelles__c = 151.67,
            crta__CT_Prime_equipe_soiree__c = 0.0,
            crta__CT_Salaire_de_base_mensuel_theorique__c = 3345.0,    
            crta__Salarie__c = e.id,
            Net_payer__c = 2474.92
        );
        insert s;
        s = new crta__Salaire__c (
            crta__CT_Brut_SS__c = 1566.49,      
            crta__CT_Charges_salariales_mensuelles__c = 668.13, 
            crta__CT_Date_de_remuneration__c = Date.parse('27/01/2014'),
            crta__CT_Nombre_d_heures_theoriques_mensuelles__c = 151.67,
            crta__CT_Prime_equipe_soiree__c = 0.0,
            crta__CT_Salaire_de_base_mensuel_theorique__c = 3345.0,    
            crta__Salarie__c = e.id,
            Net_payer__c = 2474.92
        );
        insert s;
        s = new crta__Salaire__c (
            crta__CT_Brut_SS__c = 1566.49,      
            crta__CT_Charges_salariales_mensuelles__c = 668.13, 
            crta__CT_Date_de_remuneration__c = Date.parse('27/01/2014'),
            crta__CT_Nombre_d_heures_theoriques_mensuelles__c = 151.67,
            crta__CT_Prime_equipe_soiree__c = 0.0,
            crta__CT_Salaire_de_base_mensuel_theorique__c = 3345.0,    
            crta__Salarie__c = e.id,
            Net_payer__c = 2474.92
        );
        insert s;
        s = new crta__Salaire__c (
            crta__CT_Brut_SS__c = 1566.49,      
            crta__CT_Charges_salariales_mensuelles__c = 668.13, 
            crta__CT_Date_de_remuneration__c = Date.parse('27/01/2014'),
            crta__CT_Nombre_d_heures_theoriques_mensuelles__c = 151.67,
            crta__CT_Prime_equipe_soiree__c = 0.0,
            crta__CT_Salaire_de_base_mensuel_theorique__c = 3345.0,    
            crta__Salarie__c = e.id,
            Net_payer__c = 2474.92
        );
        insert s;
        s = new crta__Salaire__c (
            crta__CT_Brut_SS__c = 1566.49,      
            crta__CT_Charges_salariales_mensuelles__c = 668.13, 
            crta__CT_Date_de_remuneration__c = Date.parse('27/01/2014'),
            crta__CT_Nombre_d_heures_theoriques_mensuelles__c = 151.67,
            crta__CT_Prime_equipe_soiree__c = 0.0,
            crta__CT_Salaire_de_base_mensuel_theorique__c = 3345.0,    
            crta__Salarie__c = e.id,
            Net_payer__c = 2474.92
        );
        insert s;

        Test.startTest();
        
        bduCalcRemunerations b1 = new bduCalcRemunerations( refDate ); 
        System.Schedule('b1', '0 51 09 23 3 ? 2080', b1 );

        Test.stopTest();
    } 
}