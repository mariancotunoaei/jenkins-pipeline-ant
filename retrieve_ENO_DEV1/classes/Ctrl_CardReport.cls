public with sharing class Ctrl_CardReport {
    public List<TableRow> tableRows {get;set;}
    public Boolean showATS {get;set;}

    public Ctrl_CardReport() {

        Date startDate = Date.today();
        String ghostPlanningVersionId = ''; 
        if(ApexPages.currentPage().getParameters().get('startDate') != null){
            startDate = Date.valueOf(ApexPages.currentPage().getParameters().get('startDate').left(10));
        }

        if(ApexPages.currentPage().getParameters().get('ghostplanningversion') != null && ApexPages.currentPage().getParameters().get('ghostplanningversion') != 'undefined'){
            ghostPlanningVersionId = ApexPages.currentPage().getParameters().get('ghostplanningversion');
        }

        this.showATS = false;
        if(ApexPages.currentPage().getParameters().get('ats') != null && ApexPages.currentPage().getParameters().get('ats') == 'true'){
            this.showATS = true;
        }

        Date endDate = startDate.addYears(1); 

        List<B25__Reservation__c> reservations = this.getReservations(startDate, endDate, ghostPlanningVersionId);
        Map<Date, List<B25__Reservation__c>> dateToReservations = this.getDateToReservations(reservations);
        List<TableRow> tableRows = new List<TableRow>();
        while(startDate < endDate) {
            tableRows.add(new TableRow(startDate, dateToReservations.containsKey(startDate) ? dateToReservations.get(startDate) : null));
            startDate = startDate.addDays(1);
        }
        
        this.tableRows = tableRows;
    }

    @AuraEnabled(Cacheable=true)
    public static List<LookupSearchResult> searchGhostPlanningVersion(String searchTerm, List<String> selectedIds) {

        String searchString = '%' + searchTerm + '%';
        List<Ghost_Planning_Version__c> versions = [
            SELECT Id, Name, Ghost_planning__r.Name
            FROM Ghost_Planning_Version__c 
            WHERE Name LIKE :searchString
            OR Ghost_planning__r.Name LIKE :searchString
        ];

        // Prepare results
        List<LookupSearchResult> results = new List<LookupSearchResult>();

        // Extract Accounts & convert them into LookupSearchResult
        String orderIcon = 'standard:order_item';
        for (Ghost_Planning_Version__c ghostplanningversion : versions) {
            results.add(new LookupSearchResult(ghostplanningversion.Id, 'Ghost Planning Version', orderIcon, ghostplanningversion.Name, ghostplanningversion.Ghost_planning__r.Name));
        }
        return results;
    }

    //filter cancelled
    //show secrets
    private List<B25__Reservation__c> getReservations(Date startDate, Date endDate, String ghostPlanningVersionId){
        if(ghostPlanningVersionId == null) {
            return [
                SELECT Id, B25__Reservation_Type__r.Name, Run__c, Run__r.Name, Run__r.Production__r.Name, Costume__c,
                Run__r.First_Performance_Date__c, Run__r.Last_Performance_Date__c, B25__Start_Date__c, ATS_Notes__c,
                B25__Title__c, Reservation_Number__c, Local_Start_End_Time__c, B25__Resource__r.Name, Card__r.API_Name__c,
                BSL_Signed_performance__c, AM_PM_Eve_Night__c, Reservation_Title__c, B25__Reservation_Type__r.Is_Performance__c,
                Cards_Booking_Title__c, Show_In_Cards_Report__c, B25__Resource__c,
                (
                    SELECT Id, Card__r.API_Name__c FROM Reservation_Cards__r    
                )
                FROM B25__Reservation__c 
                WHERE B25__Start_Date__c >= :startDate
                AND B25__Start_Date__c <= :endDate
                AND Is_Shift__c = false
                AND In_Ghost_Mode__c = false
                AND Parent_Reservation__c = null
                AND B25__Status__r.Name != 'Cancelled'
                AND B25__Reservation_Type__r.Name != 'House Open'
                ORDER BY B25__Start__c
            ];
        } else {
            return [
                SELECT Id, B25__Reservation_Type__r.Name, Run__c, Run__r.Name, Run__r.Production__r.Name, Costume__c,
                Run__r.First_Performance_Date__c, Run__r.Last_Performance_Date__c, B25__Start_Date__c, ATS_Notes__c,
                B25__Title__c, Reservation_Number__c, Local_Start_End_Time__c, B25__Resource__r.Name, Card__r.API_Name__c,
                BSL_Signed_performance__c, AM_PM_Eve_Night__c, Reservation_Title__c, B25__Reservation_Type__r.Is_Performance__c,
                Cards_Booking_Title__c, Show_In_Cards_Report__c, B25__Resource__c,
                (
                    SELECT Id, Card__r.API_Name__c FROM Reservation_Cards__r    
                )
                FROM B25__Reservation__c 
                WHERE B25__Start_Date__c >= :startDate
                AND B25__Start_Date__c <= :endDate
                AND Is_Shift__c = false
                AND (
                    In_Ghost_Mode__c = false
                    OR
                    (In_Ghost_Mode__c = true AND Ghost_Planning_Version__c = :ghostPlanningVersionId)
                ) 
                AND Parent_Reservation__c = null
                AND B25__Status__r.Name != 'Cancelled'
                AND B25__Reservation_Type__r.Name != 'House Open'
                ORDER BY B25__Start__c
            ];
        }
    }

    private Map<Date, List<B25__Reservation__c>> getDateToReservations(List<B25__Reservation__c> reservations){
        Map<Date, List<B25__Reservation__c>> returnMap = new Map<Date, List<B25__Reservation__c>>();
        for(B25__Reservation__c reservation : reservations){
            if(!returnMap.containsKey(reservation.B25__Start_Date__c)){
                returnMap.put(reservation.B25__Start_Date__c, new List<B25__Reservation__c>());
            }
            returnMap.get(reservation.B25__Start_Date__c).add(reservation);
        }
        return returnMap;
    }

    public class TableRow {
        public Date rowDate {get; private set;}
        public List<B25__Reservation__c> performanceReservations {get; private set;}
        public List<B25__Reservation__c> informationReservations {get; private set;}
        public List<B25__Reservation__c> baylisReservations {get; private set;}
        public Map<String, List<B25__Reservation__c>> atsReservations {get; private set;}
        public Map<String, List<B25__Reservation__c>> enoCompanyReservations {get; private set;}
        public Map<String, List<B25__Reservation__c>> stageReservations {get; private set;}
        public Map<String, List<B25__Reservation__c>> orchestraReservations {get; private set;}
        public Map<String, List<B25__Reservation__c>> chorusReservations {get; private set;}
        public Map<String, B25__Reservation__c> musicProductionRehearsalReservations {get; private set;}
        public Map<String, B25__Reservation__c> coversReservations {get; private set;}

        public TableRow(Date rowDate, List<B25__Reservation__c> reservations){
            this.rowDate = rowDate;
            this.performanceReservations = this.getPerformanceDetails(reservations);
            this.informationReservations = this.getInformationDetails(reservations);
            this.baylisReservations = this.getBaylisDetails(reservations);
            this.atsReservations = this.groupByTime('ATS Info', reservations);
            this.enoCompanyReservations = this.groupByTime('ENOCompany', reservations);
            this.stageReservations = this.groupByTime('Stage', reservations);
            this.orchestraReservations = this.groupByTime('Orchestra', reservations);
            this.chorusReservations = this.groupByTime('Chorus', reservations);
            this.musicProductionRehearsalReservations = this.getMusicAndRehearsalDetails(reservations);
            this.coversReservations = this.getCoversDetails(reservations);
        }

        private List<B25__Reservation__c> getPerformanceDetails(List<B25__Reservation__c> reservations){
            if(reservations == null){
                return null;
            }
            List<B25__Reservation__c> returnList = new List<B25__Reservation__c>();
            List<String> recordtypes = new List<String>();
            recordtypes.add('Performance (Evening)');
            recordtypes.add('Performance (Matinee)');
            recordtypes.add('Pre-show Performance');
            recordtypes.add('Guest Night');
            recordtypes.add('Commercial Hire - Performance (requires Box Office)');

            for(B25__Reservation__c reservation :reservations){
                if(recordtypes.contains(reservation.B25__Reservation_Type__r.Name)){
                    returnList.add(reservation);
                }
            }
            return returnList;
        }

        private List<B25__Reservation__c> getInformationDetails(List<B25__Reservation__c> reservations){
            if(reservations == null){
                return null;
            }
            List<B25__Reservation__c> returnList = new List<B25__Reservation__c>();
            List<String> recordtypes = new List<String>();
            recordtypes.add('Information Only (e.g.BH, Annual Celebrations)');

            for(B25__Reservation__c reservation :reservations){
                if(recordtypes.contains(reservation.B25__Reservation_Type__r.Name)){
                    returnList.add(reservation);
                }
            }
            return returnList;
        }

        private List<B25__Reservation__c> getBaylisDetails(List<B25__Reservation__c> reservations){
            if(reservations == null){
                return null;
            }
            List<B25__Reservation__c> returnList = new List<B25__Reservation__c>();
            List<String> recordtypes = new List<String>();
            recordTypes.add('Pre Performance Talk');
            recordTypes.add('Tour - Guided Public Tour');
            recordTypes.add('Tour - Development');
            recordTypes.add('Reception');
            recordTypes.add('Development Event ');
            recordTypes.add('Private Hire');
            recordTypes.add('Baylis Activity - Children Present');
            recordTypes.add('Baylis Activity - Vulnerable Group Present');
            recordTypes.add('Baylis Activity');
            recordtypes.add('Concert Performance');

            for(B25__Reservation__c reservation :reservations){
                if(recordtypes.contains(reservation.B25__Reservation_Type__r.Name)){
                    returnList.add(reservation);
                }
            }
            return returnList;
        }
        private Map<String, B25__Reservation__c> getMusicAndRehearsalDetails(List<B25__Reservation__c> reservations){
            if(reservations == null){
                return null;
            }
            Map<String, B25__Reservation__c> resMap = new Map<String, B25__Reservation__c>();
            List<String> recordtypes = new List<String>();
            recordTypes.add('Music Rehearsal (Opera)');
            recordTypes.add('Production Rehearsal (Opera)');
            //Only get the first of this run.
            for(B25__Reservation__c reservation : reservations){
                if(recordtypes.contains(reservation.B25__Reservation_Type__r.Name) && !resMap.containsKey(reservation.Run__r.Name) && reservation.Show_In_Cards_Report__c){
                    resMap.put(reservation.Run__r.Name, reservation);
                }
            }
            return resMap;
        }

        private Map<String, B25__Reservation__c> getCoversDetails(List<B25__Reservation__c> reservations){
            if(reservations == null){
                return null;
            }
            Map<String, B25__Reservation__c> resMap = new Map<String, B25__Reservation__c>();
            List<String> recordtypes = new List<String>();
            recordTypes.add('Covers');
            //Only get the first of this run.
            for(B25__Reservation__c reservation : reservations){
                if(recordtypes.contains(reservation.B25__Reservation_Type__r.Name) && !resMap.containsKey(reservation.Run__r.Name) && reservation.Show_In_Cards_Report__c){
                    resMap.put(reservation.Run__r.Name, reservation);
                }
            }
            return resMap;
        }

        private Map<String, List<B25__Reservation__c>> groupByTime(String name, List<B25__Reservation__c> reservations){
            if(reservations == null){
                return null;
            }
            Map<String, List<B25__Reservation__c>> returnMap = new Map<String, List<B25__Reservation__c>>();
            for(B25__Reservation__c reservation :reservations){
                if(reservation.Card__r.API_Name__c == name){
                    if(!returnMap.containsKey(reservation.AM_PM_Eve_Night__c)){
                        returnMap.put(reservation.AM_PM_Eve_Night__c, new List<B25__Reservation__c>());
                    }
                    returnMap.get(reservation.AM_PM_Eve_Night__c).add(reservation);
                }

                for(Reservation_Card__c card : reservation.Reservation_Cards__r){
                    if(card.Card__r.API_Name__c == name){
                        if(!returnMap.containsKey(reservation.AM_PM_Eve_Night__c)){
                            returnMap.put(reservation.AM_PM_Eve_Night__c, new List<B25__Reservation__c>());
                        }
                        returnMap.get(reservation.AM_PM_Eve_Night__c).add(reservation);
                    }
                }
            }
            return returnMap;
        }
    }
}