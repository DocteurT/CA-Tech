public with sharing class ImportFilesController 
{
    public Blob csvFileBody {get; set;}
    public Transient String[] csvFileLines {get; set;}
    public String selectedFile {get; set;}
    //public String selectedBU{get;set;}
     public static Date dateDeLancement {get; set;}
     public static Date dateImportInf {get; set;}
     public static Date dateImportSup {get; set;}
     
     
    public ImportFilesController() {
        csvFileLines = new String[] {};
    }

    public PageReference upload() 
    {
        Transient String csvFileBody_string = csvFileBody.toString();
        if (csvFileBody_string.contains('\r\n')) 
        {
            csvFileLines = safeSplit(csvFileBody_string, '\r\n');
        } 
        else if (csvFileBody_string.contains('\n')) 
        {
            csvFileLines = safeSplit(csvFileBody_string, '\n');
        } 
        else if (csvFileBody_string.contains('\r')) 
        {
            csvFileLines = safeSplit(csvFileBody_string, '\r');
        }

        //Check for type of file
        if ( selectedFile=='Contacts' ) 
        {
            ImportFilesFuture1Controller.importContacts( csvFileLines, dateImportsup );
        } 
        else if ( selectedFile=='Affectation' ) 
        {
            System.debug('Called Affectations');
            ImportFilesFuture1Controller.importAffec( csvFileLines,'affectation', dateImportInf, dateImportsup );
        } 
        else if ( selectedFile=='Organisation' ) 
        {
            ImportFilesFuture1Controller.importAffec( csvFileLines,'organisation', dateImportInf, dateImportsup );        
        }
        else if ( selectedFile=='Classification' ) 
        {
            ImportFilesFuture1Controller.importAffec( csvFileLines,'classification', dateImportInf, dateImportsup );                
        } 
        else if ( selectedFile=='Temps de travail' ) 
        {
            ImportFilesFuture1Controller.importAffec( csvFileLines,'temps de travail', dateImportInf, dateImportsup );                
        }
        else if ( selectedFile=='Etablissement' ) 
        {
            ImportFilesFuture1Controller.importAffec( csvFileLines,'etablissement', dateImportInf, dateImportsup );                
        }
        else if ( selectedFile=='Diplome' ) 
        {
            ImportFilesFuture1Controller.importdiplome( csvFileLines );                
        }
        else if ( selectedFile=='Salaires' ) 
        {
            System.debug('Called Salaires');
            ImportFilesFuture1Controller.importSalarialeCATechnologies( csvFileLines );
        } 
        else if ( selectedFile=='Absence' ) 
        {
            System.debug('Called Absence');
            ImportFilesFuture1Controller.importAbsenceExtractionsituation( csvFileLines );
        }
      //  else if ( selectedFile=='Pce' ) 
      //  {
      //      ImportFilesFuture1Controller.importChange_Pce_CATechno( csvFileLines );
      //  } 
        else if ( selectedFile=='Medecine Du Travail' ) 
        {
            ImportFilesFuture1Controller.importMedecineDuTravail( csvFileLines ); 
        }
        else if ( selectedFile=='Salaires Annuels' ) 
        {
            ImportFilesFuture1Controller.importSalairesAnnuels( csvFileLines );
        }
        else if ( selectedFile=='Formation' ) 
        {
            ImportFilesFuture1Controller.importFormation( csvFileLines );
        }
        return null;
    }
        public void lancementDuBatch() {
        System.debug('>>> ##### ImportFilesController - lancementDuBatch() ::  '   + dateDeLancement + ' ##### <<<');

        String theDate = dateDeLancement.day() + '/' + dateDeLancement.month() + '/' + dateDeLancement.year();
        System.debug('>>> ##### ImportFilesController - theDate ::  '   + theDate + ' ##### <<<');

        if (theDate != null ) {
            bduPreBatch splitter = new bduPreBatch(  theDate  );
           Database.executeBatch(splitter, 2000);
        }
    }

    /**
    * Split a string of any size, while avoiding the dreaded 'Regex too complicated'
    * error, which the String.split(String) method causes on some large inputs.
    * Note that this method does not avoid other errors, such as those related to
    * excess heap size or CPU time.
    */

    public static List<String> safeSplit(String inStr, String delim) {
        Integer regexFindLimit = 100;
        Integer regexFindCount = 0;

        List<String> output = new List<String>();

        Matcher m = Pattern.compile(delim).matcher(inStr);

        Integer lastEnd = 0;

        while (!m.hitEnd()) {
            while (regexFindCount < regexFindLimit && !m.hitEnd()) {
                if (m.find()) {
                    output.add(inStr.substring(lastEnd, m.start()));
                    lastEnd = m.end();
                } else {
                    output.add(inStr.substring(lastEnd));
                    lastEnd = inStr.length();
                }
                regexFindCount++;
            }

            /** Note: Using region() to advance instead of substring() saves
            drastically on heap size. Nonetheless, we still must reset the
            (unmodified) input sequence to avoid a 'Regex too complicated'
            error. **/

            m.reset(inStr);
            m.region(lastEnd, m.regionEnd());

            regexFindCount = 0;
        }

        return output;
    }
}