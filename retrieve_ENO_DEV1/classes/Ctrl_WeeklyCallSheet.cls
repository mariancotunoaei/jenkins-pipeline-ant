public with sharing class Ctrl_WeeklyCallSheet {

    public static Map<Id, List<Reservation_Performer__c>> performerMap = new Map<Id, List<Reservation_Performer__c>>();
    public static Map<Id, List<Reservation_Staff__c>> staffMap = new Map<Id, List<Reservation_Staff__c>>();
    public static Map<String, List<String>> castMemberMap = new Map<String, List<String>>();

    @AuraEnabled
    public static List<Ctrl_WeeklyCallSheet.CallSheet> getWeeklyCallSheetData(Date passedDate){

        Date startDate = Date.today();
        Date endDate = Date.today().addDays(7);
        if(passedDate != null){
            startDate = passedDate;
            endDate = passedDate.addDays(7);
        }

        List<String> excludedResTypes = new List<String>();
        excludedResTypes.add('Commercial Hire');
        excludedResTypes.add('Guest Night');
        excludedResTypes.add('ATS Information');
        excludedResTypes.add('Build');
        excludedResTypes.add('Build/Focus');
        excludedResTypes.add('c/o & Focus');
        excludedResTypes.add('Focus');
        excludedResTypes.add('Get out');
        excludedResTypes.add('LX');
        excludedResTypes.add('LX Rig');
        excludedResTypes.add('Maintenance');
        excludedResTypes.add('NCO');
        excludedResTypes.add('Production Work');
        excludedResTypes.add('Strike & Pack');
        excludedResTypes.add('Tour - Guided Public Tour');
        excludedResTypes.add('Tour - Development');
        excludedResTypes.add('Information Only (e.g.BH, Annual Celebrations)');
        excludedResTypes.add('House Open');
        excludedResTypes.add('N/A');
        excludedResTypes.add('N/A - ENO Work');

        List<B25__Reservation__c> reservations = [
            SELECT Id, Run__r.Production__r.Name, Run__r.Name, B25__Start_Date__c, B25__Title__c,
            B25__Start__c, B25__End__c, Local_Start_End_Time__c, Run__c,
            B25__Local_Start_Time__c, B25__Local_End_Time__c, Reservation_Number__c,
            B25__Resource__r.Abbreviated_venue_name__c, B25__Notes__c, Costume__c,
            B25__Resource__c, B25__Resource__r.Name, B25__Reservation_Type__c,
            B25__Resource__r.B25__Parent__r.Name, Covers_Attend__c, Rehearsal_Content__c,
            Selected_Person_Groups__c, Include_Reservation_on_callsheet__c, 
            B25__Reservation_Type__r.Name,
            (
                SELECT Id, Run__r.Production__r.Name, Run__c, B25__Start_Date__c,
                Selected_Person_Groups__c, B25__Reservation_Type__r.Name, Reservation_Number__c,
                B25__Start__c, B25__End__c, B25__Local_Start_Time__c, B25__Title__c, B25__Notes__c
                FROM Reservations__r
                ORDER BY B25__Start__c
            ),
            (
                SELECT Id, Staff__c, Staff__r.Name,
                Staff__r.How_name_should_appear_on_call_sheet__c
                FROM Reservation_Staffs__r
            ),
            (
                SELECT Id, Performer__c, Performer__r.Name,
                Performer__r.How_name_should_appear_on_call_sheet__c,
                Performer__r.Show_on_callsheet_as_creative__c
                FROM Reservation_Performers__r
            )
            FROM B25__Reservation__c 
            WHERE B25__Start_Date__c >= :startDate 
                AND B25__Start_Date__c < :endDate
                AND Parent_Reservation__c = null
            	AND Is_Shift__c = false
            	AND In_Ghost_Mode__c = false
            	AND Secret__c = false
            	AND B25__Status__r.Name != 'Cancelled'
                AND B25__Reservation_Type__r.Name NOT IN :excludedResTypes	 
            ORDER BY B25__Start__c
        ];

        //Because we cannot do a subquery in a subquery, we need to fire two other queries to get the
        //staff members and permorers of the subreservations.
        Set<Id> childResIds = new Set<Id>();
        for(B25__Reservation__c curParentRes : reservations){
            for(B25__Reservation__c curChildRes : curParentRes.Reservations__r) {
                childResIds.add(curChildRes.Id);
            }
        }
        Ctrl_WeeklyCallSheet.setSubresStaff(childResIds);
        Ctrl_WeeklyCallSheet.setSubresPerformer(childResIds);      

        Set<Id> runIds = new Set<Id>();
        for(B25__Reservation__c curParentRes : reservations){
            runIds.add(curParentRes.Run__c);
        }
        Ctrl_WeeklyCallSheet.setPrimaryCastMembers(runIds);   

        //Start building the file 
        Map<Date, Ctrl_WeeklyCallSheet.CallSheet> weeklyCallSheet = new Map<Date, Ctrl_WeeklyCallSheet.CallSheet>();
        for(B25__Reservation__c res : reservations){
            Date curDate = res.B25__Start_Date__c;

            if(!weeklyCallSheet.containsKey(curDate)){
                weeklyCallSheet.put(curDate, new Ctrl_WeeklyCallSheet.CallSheet(curDate));
            }
            weeklyCallSheet.get(curDate).addReservation(res);       
        }

        List<Ctrl_WeeklyCallSheet.CallSheet> sortedSheets = weeklyCallSheet.values();
        for(Ctrl_WeeklyCallSheet.CallSheet sheet : sortedSheets){
            sheet.setProductionName();
            sheet.sortRuns();
            sheet.sortVenues();
        }
        return sortedSheets;
    }

    public static void setSubresStaff(Set<Id> childResIds){
        List<Reservation_Staff__c> subResStaffs = [
            SELECT Id, Staff__c, Staff__r.Name, Reservation__c,
            Staff__r.How_name_should_appear_on_call_sheet__c
            FROM Reservation_Staff__c
            WHERE Reservation__c IN :childResIds
        ];

        Map<Id, List<Reservation_Staff__c>> staffMap = new Map<Id, List<Reservation_Staff__c>>();
        for(Reservation_Staff__c staffMember : subResStaffs) {
            if(!staffMap.containsKey(staffMember.Reservation__c)){
                staffMap.put(staffMember.Reservation__c, new List<Reservation_Staff__c>());
            }
            staffMap.get(staffMember.Reservation__c).add(staffMember);
        }
        Ctrl_WeeklyCallSheet.staffMap = staffMap;
    }

    public static void setSubresPerformer(Set<Id> childResIds){
        List<Reservation_Performer__c> subResPerformers = [
            SELECT Id, Performer__c, Performer__r.Name, Reservation__c,
            Performer__r.How_name_should_appear_on_call_sheet__c
            FROM Reservation_Performer__c
            WHERE Reservation__c IN :childResIds
        ];

        Map<Id, List<Reservation_Performer__c>> performerMap = new Map<Id, List<Reservation_Performer__c>>();
        for(Reservation_Performer__c resPerformer : subResPerformers) {
            if(!performerMap.containsKey(resPerformer.Reservation__c)){
                performerMap.put(resPerformer.Reservation__c, new List<Reservation_Performer__c>());
            }
            performerMap.get(resPerformer.Reservation__c).add(resPerformer);
        }
        Ctrl_WeeklyCallSheet.performerMap = performerMap;
    }

    public static String createTitle(B25__Reservation__c res){
        if(!String.isEmpty(res.B25__Title__c)){
            return res.B25__Title__c;
        } else {
            String resnr = String.isEmpty(res.Reservation_Number__c) ? '' : ' ' + res.Reservation_Number__c;
            return res.B25__Reservation_Type__r.Name + resnr;
        }
    }

    public static void setPrimaryCastMembers(Set<Id> runIds) {
        List<Cast_Member__c> castMembers = [
            SELECT Id, Performer__c, Performer__r.How_name_should_appear_on_call_sheet__c, Performer__r.Show_on_callsheet_as_creative__c, Run__c
            FROM Cast_Member__c 
            WHERE Run__c IN :runIds
            AND Always_Show_On_Call_Sheet__c = true
        ];

        Map<String, List<String>> castMemberMap = new Map<String, List<String>>();
        for(Cast_Member__c castMember : castMembers){
            String identifier = ''+castMember.Run__c + castMember.Performer__c;
            if(!castMemberMap.containsKey(identifier)){
                castMemberMap.put(identifier,new List<String>());
            }
            castMemberMap.get(identifier).add(castMember.Performer__r.How_name_should_appear_on_call_sheet__c);
        }

        Ctrl_WeeklyCallSheet.castMemberMap = castMemberMap;
    }

    //callsheet with all details.
    public class CallSheet {
        @AuraEnabled public Date callsheetDate {get; private set;}
        @AuraEnabled public String callsheetDateStr {get; private set;}
        private Map<String, Ctrl_WeeklyCallSheet.Run> runMap;
        @AuraEnabled public List<Ctrl_WeeklyCallSheet.Run> runs {get; private set;}

        @AuraEnabled public List<Ctrl_WeeklyCallSheet.Chorus> chorusList {get; private set;}
        @AuraEnabled public List<Ctrl_WeeklyCallSheet.Orchestra> orchestraList {get; private set;}

        private Map<String, Ctrl_WeeklyCallSheet.Venue> venueMap;
        @AuraEnabled public List<Ctrl_WeeklyCallSheet.Venue> venues {get; private set;}
        @AuraEnabled public String productionNames {get; private set;}
        @AuraEnabled public Set<String> productionNamesSet {get; private set;}
        @AuraEnabled public List<Reservation_Staff__c> staffMembers {get; private set;}
        @AuraEnabled public String staffMemberNames {get; private set;}

        public CallSheet(Date dt){
            this.callSheetDate = dt;
            Datetime dtt = Datetime.newInstance(dt, Time.newInstance(12,0,0,0));
            this.callsheetDateStr =  dtt.formatGMT('EEEE d MMMM yyyy');
            this.runMap = new Map<String, Ctrl_WeeklyCallSheet.Run>();
            this.chorusList = new List<Ctrl_WeeklyCallSheet.Chorus>();
            this.orchestraList = new List<Ctrl_WeeklyCallSheet.Orchestra>();
            this.venueMap = new Map<String, Ctrl_WeeklyCallSheet.Venue>();
            this.productionNamesSet = new Set<String>();
        }

        public void addReservation(B25__Reservation__c res){

            List<String> resTypes = new List<String>();
            resTypes.add('Costume/Wigs/Makeup Prep Call');
            resTypes.add('Covers');
            resTypes.add('DR');
            resTypes.add('Music Rehearsal (Opera)');
            resTypes.add('PDR');
            resTypes.add('Production Rehearsal (Opera)');
            resTypes.add('Recording/Filming');
            resTypes.add('Rehearsal');
            resTypes.add('s&o');
            resTypes.add('s&p');
            resTypes.add('Sitz');
            resTypes.add('Technical rehearsal');
            resTypes.add('Coaching');
            resTypes.add('Fitting');
            resTypes.add('Q to Q');
            resTypes.add('Auditions');

            //the following list of restypes only shows when the checkbox Include Reservation on callsheet is enabled
            List<String> includeResTypes = new List<String>();
            includeResTypes.add('Baylis Activity');
            includeResTypes.add('Baylis Activity – Children Present');
            includeResTypes.add('Baylis Activity – Vulnerable Group Present');
            includeResTypes.add('Private Hire');
            includeResTypes.add('Meeting (External)');
            includeResTypes.add('Meeting (Internal)');
            includeResTypes.add('Reception');
            includeResTypes.add('Development Event');
            includeResTypes.add('Pre Performance Talk');
            includeResTypes.add('Concert Performance');

            if(res.Run__c != null && resTypes.contains(res.B25__Reservation_Type__r.Name)){
                String productionName = res.Run__r.Production__r.Name;
                if(!this.runMap.containsKey(productionName)){
                    this.runMap.put(productionName, new Ctrl_WeeklyCallSheet.Run(productionName, res));
                }
                this.runMap.get(productionName).addReservation(res);
            }
            if(res.Run__c != null && includeResTypes.contains(res.B25__Reservation_Type__r.Name) && res.Include_Reservation_on_callsheet__c){
                String productionName = res.Run__r.Production__r.Name;
                if(!this.runMap.containsKey(productionName)){
                    this.runMap.put(productionName, new Ctrl_WeeklyCallSheet.Run(productionName, res));
                }
                this.runMap.get(productionName).addReservation(res);
            }

            if(res.B25__Reservation_Type__r.Name == 'Chorus - Production' || res.B25__Reservation_Type__r.Name == 'Chorus - Rep'){
                this.chorusList.add(new Ctrl_WeeklyCallSheet.Chorus(res));
            }

            if(res.B25__Reservation_Type__r.Name == 'Orchestral'){
                this.orchestraList.add(new Ctrl_WeeklyCallSheet.Orchestra(res));
            }

            if(res.B25__resource__c != null && 
                res.Run__c == null &&
                (
                resTypes.contains(res.B25__Reservation_Type__r.Name) && 
                res.B25__Reservation_Type__r.Name != 'Chorus - Production' &&
                res.B25__Reservation_Type__r.Name != 'Chorus - Rep' && 
                res.B25__Reservation_Type__r.Name != 'Orchestral' && 
                res.B25__Reservation_Type__r.Name != 'Performance (Evening)' && 
                res.B25__Reservation_Type__r.Name != 'Performance (Matinee)' && 
                res.B25__Reservation_Type__r.Name != 'Performance (Evening)' && 
                res.B25__Reservation_Type__r.Name != 'Performance (Matinee)' && 
                res.B25__Reservation_Type__r.Name != 'Pre-show Performance' && 
                res.B25__Reservation_Type__r.Name != 'Commercial Hire - Performance (requires Box Office)'
                )
            ){
                String venueName = res.B25__Resource__r.B25__Parent__r.Name;
                if(!this.venueMap.containsKey(venueName)){
                    this.venueMap.put(venueName, new Ctrl_WeeklyCallSheet.Venue(res));
                }
                this.venueMap.get(venueName).addReservation(res);
            }

            if(res.B25__resource__c != null && res.Run__c == null && includeResTypes.contains(res.B25__Reservation_Type__r.Name) && res.Include_Reservation_on_callsheet__c){
                String venueName = res.B25__Resource__r.B25__Parent__r.Name;
                if(!this.venueMap.containsKey(venueName)){
                    this.venueMap.put(venueName, new Ctrl_WeeklyCallSheet.Venue(res));
                }
                this.venueMap.get(venueName).addReservation(res);
            }

            if(
                res.B25__Reservation_Type__r.Name == 'Performance (Evening)' || 
                res.B25__Reservation_Type__r.Name == 'Performance (Matinee)' || 
                res.B25__Reservation_Type__r.Name == 'Pre-show Performance' || 
                res.B25__Reservation_Type__r.Name == 'Commercial Hire - Performance (requires Box Office)'
                ){
                this.productionNamesSet.add(res.B25__Local_Start_Time__c + ' ' + res.B25__Title__c + ' ' + (String.isBlank(res.B25__Notes__c) ? '' : res.B25__Notes__c));
                List<String> shortStaffMemberNames = new List<String>();
                for(Reservation_Staff__c staffMember : res.Reservation_Staffs__r){
                    shortStaffMemberNames.add(staffMember.Staff__r.How_name_should_appear_on_call_sheet__c);
                }
                //specific performers also show up in the list of staff members.
                for(Reservation_Performer__c resPerformer : res.Reservation_Performers__r){
                    if(resPerformer.Performer__r.Show_on_callsheet_as_creative__c){
                        shortStaffMemberNames.add(resPerformer.Performer__r.How_name_should_appear_on_call_sheet__c); 
                    }
                }
                this.staffMemberNames = String.join(shortStaffMemberNames, ' ');
            }
        }

        public void setProductionName(){
            this.productionNames = 'NO PERFORMANCE';
            if(this.productionNamesSet.size() > 0){
                this.productionNames = String.join(new List<String>(this.productionNamesSet), ' ');
            }
        }

        public void sortRuns(){
            this.runs = this.runMap.values();
            this.runs.sort();
        }

        public void sortVenues(){
            this.venues = this.venueMap.values();
            //this.venues.sort();
        }
    }

    private class Run implements Comparable {
        @AuraEnabled public String productionName {get; private set;}
        @AuraEnabled public String startEndTime {get; private set;}
        @AuraEnabled public String title {get; private set;}
        @AuraEnabled public List<Ctrl_WeeklyCallSheet.RunReservation> reservations {get; private set;}
        @AuraEnabled public List<Ctrl_WeeklyCallSheet.FittingReservation> fittings {get; private set;}

        public Run(String name, B25__Reservation__c res){
            this.productionName = res.Run__r.Name;
            this.startEndTime = res.Local_Start_End_Time__c;
            this.title = Ctrl_WeeklyCallSheet.createTitle(res);
            this.reservations = new List<Ctrl_WeeklyCallSheet.RunReservation>();
            this.fittings = new List<Ctrl_WeeklyCallSheet.FittingReservation>();
        }

        public void addReservation(B25__Reservation__c res){
            if(res.B25__Reservation_Type__r.Name == 'Fitting'){
                this.fittings.add(new Ctrl_WeeklyCallSheet.FittingReservation(res));
            } else {
                this.reservations.add(new Ctrl_WeeklyCallSheet.RunReservation(res));
            }
        }

        public Integer compareTo(Object obj){
            Ctrl_WeeklyCallSheet.Run that = (Ctrl_WeeklyCallSheet.Run)obj;
            return this.productionName < that.productionName ? -1 : 1;
        }
    }

    private class Chorus {
        @AuraEnabled public String startEndTime {get; private set;}
        @AuraEnabled public String venueShort {get; private set;}
        @AuraEnabled public String title {get; private set;}
        @AuraEnabled public B25__Reservation__c reservation {get; private set;}
        @AuraEnabled public String staffMemberNames {get; private set;}
        @AuraEnabled public List<Reservation_Performer__c> performers {get; private set;}
        @AuraEnabled public String performerNames {get; private set;}
        @AuraEnabled public List<Ctrl_WeeklyCallSheet.SubReservation> subReservations {get; private set;}

        public Chorus(B25__Reservation__c res){
            this.startEndTime = res.Local_Start_End_Time__c;
            this.title = Ctrl_WeeklyCallSheet.createTitle(res);
            this.reservation = res;
            this.venueShort = res.B25__Resource__r.Abbreviated_venue_name__c;

            this.performers = res.Reservation_Performers__r;

            if(res.Selected_Person_Groups__c != null && res.Selected_Person_Groups__c != ''){ 
                this.performerNames = res.Selected_Person_Groups__c;
                
                for(Reservation_Performer__c performerMember : res.Reservation_Performers__r){
                    String identifier = ''+res.Run__c+performerMember.Performer__c;
                    if(Ctrl_WeeklyCallSheet.castMemberMap.containsKey(identifier)){
                        this.performerNames += ' ' +performerMember.Performer__r.How_name_should_appear_on_call_sheet__c;
                    }
                }
            } else {
                List<String> shortPerformerNames = new List<String>();
                for(Reservation_Performer__c performerMember : res.Reservation_Performers__r){
                    shortPerformerNames.add(performerMember.Performer__r.How_name_should_appear_on_call_sheet__c);
                }
                this.performerNames = String.join(shortPerformerNames, ', ');
            }

            List<String> shortStaffMemberNames = new List<String>();
            for(Reservation_Staff__c staffMember : res.Reservation_Staffs__r){
                shortStaffMemberNames.add(staffMember.Staff__r.How_name_should_appear_on_call_sheet__c);
            }
            //specific performers also show up in the list of staff members.
            for(Reservation_Performer__c resPerformer : res.Reservation_Performers__r){
                if(resPerformer.Performer__r.Show_on_callsheet_as_creative__c){
                    shortStaffMemberNames.add(resPerformer.Performer__r.How_name_should_appear_on_call_sheet__c); 
                }
            }
            this.staffMemberNames = String.join(shortStaffMemberNames, ' ');

            this.subReservations = new List<Ctrl_WeeklyCallSheet.SubReservation>();
            for(B25__Reservation__c subRes : res.Reservations__r){
                this.subReservations.add(new SubReservation(subRes));
            }
        }
    }

    private class Orchestra {
        @AuraEnabled public String startEndTime {get; private set;}
        @AuraEnabled public String venueShort {get; private set;}
        @AuraEnabled public String title {get; private set;}
        @AuraEnabled public String runName {get; private set;}
        @AuraEnabled public B25__Reservation__c reservation {get; private set;}
        @AuraEnabled public List<Reservation_Staff__c> staffMembers {get; private set;}
        @AuraEnabled public String staffMemberNames {get; private set;}

        public Orchestra(B25__Reservation__c res){
            this.startEndTime = res.Local_Start_End_Time__c;
            this.title = Ctrl_WeeklyCallSheet.createTitle(res);
            this.runName = res.Run__r.Name;
            this.reservation = res;
            this.venueShort = res.B25__Resource__r.Abbreviated_venue_name__c;

            List<String> shortStaffMemberNames = new List<String>();
            for(Reservation_Staff__c staffMember : res.Reservation_Staffs__r){
                shortStaffMemberNames.add(staffMember.Staff__r.How_name_should_appear_on_call_sheet__c);
            }
            //specific performers also show up in the list of staff members.
            for(Reservation_Performer__c resPerformer : res.Reservation_Performers__r){
                if(resPerformer.Performer__r.Show_on_callsheet_as_creative__c){
                    shortStaffMemberNames.add(resPerformer.Performer__r.How_name_should_appear_on_call_sheet__c); 
                }
            }
            this.staffMemberNames = String.join(shortStaffMemberNames, ' ');
        }
    }

    private class Venue implements Comparable{
        @AuraEnabled public String parentVenueName {get; private set;}
        @AuraEnabled public String startEndTime {get; private set;}
        @AuraEnabled public List<Ctrl_WeeklyCallSheet.VenueReservation> reservations {get; private set;}

        public Venue(B25__Reservation__c res){
            this.parentVenueName = res.B25__Resource__r.B25__Parent__r.Name;
            this.startEndTime = res.Local_Start_End_Time__c;
            this.reservations = new List<Ctrl_WeeklyCallSheet.VenueReservation>();
        }

        public void addReservation(B25__Reservation__c res){
            //this.reservations.add(res);
            this.reservations.add(new Ctrl_WeeklyCallSheet.VenueReservation(res));
        }
        
        public Integer compareTo(Object obj){
            Ctrl_WeeklyCallSheet.Venue that = (Ctrl_WeeklyCallSheet.Venue)obj;
            return this.parentVenueName < that.parentVenueName ? -1 : 1;
        }
    }

    private class RunReservation {
        @AuraEnabled public B25__Reservation__c reservation;
        @AuraEnabled public String venueShort {get; private set;}
        @AuraEnabled public String coversAttend {get; private set;}
        @AuraEnabled public String costume {get; private set;}
        @AuraEnabled public String runName {get; private set;}
        @AuraEnabled public String title {get; private set;}
        @AuraEnabled public String rehearsalContent {get; private set;}
        @AuraEnabled public String notes {get; private set;}
        @AuraEnabled public List<Reservation_Staff__c> staffMembers {get; private set;}
        @AuraEnabled public String staffMemberNames {get; private set;}
        @AuraEnabled public List<Reservation_Performer__c> performers {get; private set;}
        @AuraEnabled public String performerNames {get; private set;}
        @AuraEnabled public List<Ctrl_WeeklyCallSheet.SubReservation> subReservations {get; private set;}

        public RunReservation(B25__Reservation__c res){
            this.reservation = res;
            this.venueShort = res.B25__Resource__r.Abbreviated_venue_name__c;
            this.coversAttend = res.Covers_Attend__c ? 'COVERS ATTEND' : '';
            this.rehearsalContent = res.Rehearsal_Content__c;
            this.costume = res.Costume__c;
            this.runName = res.Run__r.Name;
            this.notes = res.B25__Notes__c;
            this.title = Ctrl_WeeklyCallSheet.createTitle(res);
            //this.subReservations = res.Reservations__r;
            this.staffMembers = res.Reservation_Staffs__r;
            this.performers = res.Reservation_Performers__r;

            List<String> shortStaffMemberNames = new List<String>();
            for(Reservation_Staff__c staffMember : res.Reservation_Staffs__r){
                shortStaffMemberNames.add(staffMember.Staff__r.How_name_should_appear_on_call_sheet__c);
            }
            //specific performers also show up in the list of staff members.
            for(Reservation_Performer__c resPerformer : res.Reservation_Performers__r){
                if(resPerformer.Performer__r.Show_on_callsheet_as_creative__c){
                    shortStaffMemberNames.add(resPerformer.Performer__r.How_name_should_appear_on_call_sheet__c); 
                }
            }
            this.staffMemberNames = String.join(shortStaffMemberNames, ' ');

            if(res.Selected_Person_Groups__c != null && res.Selected_Person_Groups__c != ''){ 
                this.performerNames = res.Selected_Person_Groups__c;
                for(Reservation_Performer__c performerMember : res.Reservation_Performers__r){
                    String identifier = ''+res.Run__c+performerMember.Performer__c;
                    if(Ctrl_WeeklyCallSheet.castMemberMap.containsKey(identifier)){
                        this.performerNames += ' ' +performerMember.Performer__r.How_name_should_appear_on_call_sheet__c;
                    }
                }
            } else {
                List<String> shortPerformerNames = new List<String>();
                for(Reservation_Performer__c performerMember : res.Reservation_Performers__r){
                    shortPerformerNames.add(performerMember.Performer__r.How_name_should_appear_on_call_sheet__c);
                }
                this.performerNames = String.join(shortPerformerNames, ', ');
            }

            this.subReservations = new List<Ctrl_WeeklyCallSheet.SubReservation>();
            for(B25__Reservation__c subRes : res.Reservations__r){
                this.subReservations.add(new SubReservation(subRes));
            }
        }
    }

    private class FittingReservation {
        @AuraEnabled public B25__Reservation__c reservation;
        @AuraEnabled public String venueShort {get; private set;}
        @AuraEnabled public String title {get; private set;}
        @AuraEnabled public List<Ctrl_WeeklyCallSheet.SubReservation> subReservations {get; private set;}

        public FittingReservation(B25__Reservation__c res){
            this.reservation = res;
            this.title = Ctrl_WeeklyCallSheet.createTitle(res);
            this.venueShort = res.B25__Resource__r.Abbreviated_venue_name__c;

            this.subReservations = new List<Ctrl_WeeklyCallSheet.SubReservation>();
            for(B25__Reservation__c subRes : res.Reservations__r){
                this.subReservations.add(new SubReservation(subRes));
            }
        }
    }

    private class VenueReservation {
        @AuraEnabled public B25__Reservation__c reservation;
        @AuraEnabled public String venueShort {get; private set;}
        @AuraEnabled public String runName {get; private set;}
        @AuraEnabled public String title {get; private set;}
        @AuraEnabled public List<Reservation_Staff__c> staffMembers {get; private set;}
        @AuraEnabled public String staffMemberNames {get; private set;}

        public VenueReservation(B25__Reservation__c res){
            this.reservation = res;
            this.venueShort = res.B25__Resource__r.Abbreviated_venue_name__c;
            this.staffMembers = res.Reservation_Staffs__r;
            this.runName = res.Run__r.Name;
            this.title = Ctrl_WeeklyCallSheet.createTitle(res);

            List<String> shortStaffMemberNames = new List<String>();
            for(Reservation_Staff__c staffMember : res.Reservation_Staffs__r){
                shortStaffMemberNames.add(staffMember.Staff__r.How_name_should_appear_on_call_sheet__c);
            }
            //specific performers also show up in the list of staff members.
            for(Reservation_Performer__c resPerformer : res.Reservation_Performers__r){
                if(resPerformer.Performer__r.Show_on_callsheet_as_creative__c){
                    shortStaffMemberNames.add(resPerformer.Performer__r.How_name_should_appear_on_call_sheet__c); 
                }
            }
            this.staffMemberNames = String.join(shortStaffMemberNames, ' ');
        }
    }


    private class SubReservation {
        @AuraEnabled public B25__Reservation__c reservation;
        @AuraEnabled public List<Reservation_Performer__c> performers {get; private set;}
        @AuraEnabled public String title {get; private set;}
        @AuraEnabled public String performerNames {get; private set;}

        public subReservation(B25__Reservation__c res){
            this.reservation = res;
            this.performers = new List<Reservation_Performer__c>();
            this.performerNames = '';
            this.title = '';//res.B25__Title__c;

            if(Ctrl_WeeklyCallSheet.performerMap.containsKey(res.Id)){
                if(res.Selected_Person_Groups__c != null && res.Selected_Person_Groups__c != ''){
                    this.performerNames = res.Selected_Person_Groups__c;
                    for(Reservation_Performer__c performerMember : res.Reservation_Performers__r){
                        String identifier = ''+res.Run__c+performerMember.Performer__c;
                        if(Ctrl_WeeklyCallSheet.castMemberMap.containsKey(identifier)){
                            this.performerNames += ' ' +performerMember.Performer__r.How_name_should_appear_on_call_sheet__c;
                        }
                    }
                } else {
                    this.performers = Ctrl_WeeklyCallSheet.performerMap.get(res.Id);
                    List<String> shortPerformerNames = new List<String>();
                    for(Reservation_Performer__c performerMember : Ctrl_WeeklyCallSheet.performerMap.get(res.Id)){
                        shortPerformerNames.add(performerMember.Performer__r.How_name_should_appear_on_call_sheet__c);
                    }
                    this.performerNames = String.join(shortPerformerNames, ', ');
                }
            }
        }
    }
}