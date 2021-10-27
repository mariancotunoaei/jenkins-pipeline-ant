@IsTest
public class Test_ENOFormLogic {

    @TestSetup
    static void makeData(){
        B25__System_Setting__c systemSetting = new B25__System_Setting__c();
        systemSetting.Name ='Reservation Form Customizer Class';
        systemSetting.B25__String_Value__c = 'ENOFormLogic';
        Database.insert(systemSetting);
    }

    @IsTest
    private static void testSearch() {
        B25__Service_Type__c servicetype = new B25__Service_Type__c();
        servicetype.Name = 'F&B';
        Database.insert(servicetype);

        B25__Service__c service = new B25__Service__c();
        service.Name = 'a';
        service.B25__Service_Type__c = servicetype.Id;
        Database.insert(service);

        B25.Test_FormHelper.TestFormContext formContext = new B25.Test_FormHelper.TestFormContext();
        formContext.reservation = new B25__Reservation__c(
            B25__StartLocal__c = Datetime.now(),
            B25__EndLocal__c = Datetime.now().addHours(1)
        );

        B25.Test_FormHelper.TestRelatedListEvent changeEvent4 = new B25.Test_FormHelper.TestRelatedListEvent();
        changeEvent4.relatedSObjectType = B25__Service_Reservation__c.SObjectType;
        changeEvent4.addedSObjectId = service.Id;
        changeEvent4.changedRelatedListItem = new B25__Service_Reservation__c(
            B25__Service__c = service.Id
        );
        B25.Test_FormHelper.runRelatedListAddEvent(formContext, changeEvent4);
    }
    
    @isTest private static void testSearchPerformer() {
        B25.Test_FormHelper.TestFormContext formContext = new B25.Test_FormHelper.TestFormContext();
        formContext.reservation = new B25__Reservation__c(
            B25__StartLocal__c = Datetime.now(),
            B25__EndLocal__c = Datetime.now().addHours(1)
        );

        B25.Test_FormHelper.TestSearchContext changeEvent = new B25.Test_FormHelper.TestSearchContext();
        changeEvent.toSearchSObjectType = Performer__c.SObjectType;
        changeEvent.toCreateSObjectType = Reservation_Performer__c.SObjectType;
        changeEvent.searchTerm = 'as';
        changeEvent.fieldName = 'Name';
        B25.Test_FormHelper.runLookupOverrideSearch(formContext, changeEvent);
    }

    @isTest private static void testSearchPerformer2() {
        B25.Test_FormHelper.TestFormContext formContext = new B25.Test_FormHelper.TestFormContext();
        formContext.reservation = new B25__Reservation__c(
            B25__StartLocal__c = Datetime.now(),
            B25__EndLocal__c = Datetime.now().addHours(1)
        );

        B25.Test_FormHelper.TestSearchContext changeEvent = new B25.Test_FormHelper.TestSearchContext();
        changeEvent.toSearchSObjectType = Performer__c.SObjectType;
        changeEvent.toCreateSObjectType = Reservation_Performer__c.SObjectType;
        changeEvent.searchTerm = '-';
        changeEvent.fieldName = 'Name';
        B25.Test_FormHelper.runLookupOverrideSearch(formContext, changeEvent);
    }

    @isTest private static void testSearchPerformer3() {

        Production__c production = new Production__c();
        production.Name = 'a';
        Database.insert(production);

        Run__c run = new Run__c();
        run.Name = 'b';
        run.Production__c = production.Id;
        Database.insert(run);

        B25.Test_FormHelper.TestFormContext formContext = new B25.Test_FormHelper.TestFormContext();
        formContext.reservation = new B25__Reservation__c(
            B25__StartLocal__c = Datetime.now(),
            B25__EndLocal__c = Datetime.now().addHours(1),
            Run__c = run.Id
        );

        B25.Test_FormHelper.TestSearchContext changeEvent = new B25.Test_FormHelper.TestSearchContext();
        changeEvent.toSearchSObjectType = Performer__c.SObjectType;
        changeEvent.toCreateSObjectType = Reservation_Performer__c.SObjectType;
        changeEvent.searchTerm = '-';
        changeEvent.fieldName = 'Name';
        B25.Test_FormHelper.runLookupOverrideSearch(formContext, changeEvent);
    }

    @isTest private static void testSearchPerformerDash() {
        B25.Test_FormHelper.TestFormContext formContext = new B25.Test_FormHelper.TestFormContext();
        formContext.reservation = new B25__Reservation__c(
            B25__StartLocal__c = Datetime.now(),
            B25__EndLocal__c = Datetime.now().addHours(1)
        );
        B25.Test_FormHelper.TestSearchContext changeEvent2 = new B25.Test_FormHelper.TestSearchContext();
        changeEvent2.toSearchSObjectType = Performer__c.SObjectType;
        changeEvent2.toCreateSObjectType = Reservation_Performer__c.SObjectType;
        changeEvent2.fieldName = 'Name';
        changeEvent2.searchTerm = '-';
        B25.Test_FormHelper.runLookupOverrideSearch(formContext, changeEvent2);
    }
    @isTest private static void testSearchPerformerGTE() {

        Person_Group__c pg = new Person_Group__c();
        pg.Name = 'Name';
        pg.Store_in_Selected_Person_Groups__c = true;
        Database.insert(pg);

        Performer__c perf = new Performer__c();
        perf.Name = 'perf';
        perf.Active__c = true;
        Database.insert(perf);  

        Person_Group_Performer__c pgPerf = new Person_Group_Performer__c();
        pgPerf.Performer__c = perf.Id;
        pgPerf.Person_Group__c = pg.Id;
        Database.insert(pgPerf);

        B25.Test_FormHelper.TestFormContext formContext = new B25.Test_FormHelper.TestFormContext();
        formContext.reservation = new B25__Reservation__c(
            B25__StartLocal__c = Datetime.now(),
            B25__EndLocal__c = Datetime.now().addHours(1),
            Selected_Person_Groups__c = 'aa, a'
        );
        B25.Test_FormHelper.TestSearchContext changeEvent3 = new B25.Test_FormHelper.TestSearchContext();
        changeEvent3.toSearchSObjectType = Performer__c.SObjectType;
        changeEvent3.toCreateSObjectType = Reservation_Performer__c.SObjectType;
        changeEvent3.fieldName = 'Name';
        changeEvent3.searchTerm = '>';
        B25.Test_FormHelper.runLookupOverrideSearch(formContext, changeEvent3);


        B25.Test_FormHelper.TestRelatedListEvent changeEvent5 = new B25.Test_FormHelper.TestRelatedListEvent();
        changeEvent5.relatedSObjectType = Reservation_Performer__c.SObjectType;
        changeEvent5.addedSObjectId = pg.Id;
        changeEvent5.changedRelatedListItem = new Reservation_Performer__c(
            Performer__c = perf.Id
        );
        B25.Test_FormHelper.runRelatedListAddEvent(formContext, changeEvent5);
    }

    @isTest private static void testChorusStaff(){
        B25.Test_FormHelper.TestFormContext formContext = new B25.Test_FormHelper.TestFormContext();
        formContext.reservation = new B25__Reservation__c(
            B25__StartLocal__c = Datetime.now(),
            B25__EndLocal__c = Datetime.now().addHours(1)
        );
        Performer__c performer = new Performer__c();
        performer.Name = 'Performer';
        performer.Role__c = 'Chorus (soprano)';
        Database.insert(performer);

        B25.Test_FormHelper.TestRelatedListEvent changeEvent5 = new B25.Test_FormHelper.TestRelatedListEvent();
        changeEvent5.relatedSObjectType = Reservation_Performer__c.SObjectType;
        changeEvent5.addedSObjectId = 'all-chorus';
        changeEvent5.changedRelatedListItem = new Reservation_Performer__c(
            Performer__c = performer.Id
        );
        B25.Test_FormHelper.runRelatedListAddEvent(formContext, changeEvent5);
    }

    @isTest private static void testCastStaff(){

        Production__c production = new Production__c();
        production.Name = 'a';
        Database.insert(production);

        Run__c run = new Run__c();
        run.Name = 'b';
        run.Production__c = production.Id;
        Database.insert(run);

        Performer__c performer = new Performer__c();
        performer.Name = 'a';
        performer.Active__c = true;
        Database.insert(performer);

        Cast_Member__c castMember = new Cast_Member__c();
        castMember.Performer__c = performer.Id;
        castMember.Cast_Cover__c = 'Cast A';
        castMember.Run__c = run.Id;
        Database.insert(castMember);

        B25.Test_FormHelper.TestFormContext formContext = new B25.Test_FormHelper.TestFormContext();
        formContext.reservation = new B25__Reservation__c(
            B25__StartLocal__c = Datetime.now(),
            B25__EndLocal__c = Datetime.now().addHours(1),
            Run__c = run.Id
        );
        B25__Staff__c staff = new B25__Staff__c();
        staff.Name = 'staff';
        Database.insert(staff);

        B25.Test_FormHelper.TestRelatedListEvent changeEvent5 = new B25.Test_FormHelper.TestRelatedListEvent();
        changeEvent5.relatedSObjectType = Reservation_Staff__c.SObjectType;
        changeEvent5.addedSObjectId = 'all-castA';
        changeEvent5.changedRelatedListItem = new Reservation_Staff__c(
            Staff__c = staff.Id
        );
        B25.Test_FormHelper.runRelatedListAddEvent(formContext, changeEvent5);
    }


    @isTest private static void testSearchStaff(){
        B25.Test_FormHelper.TestFormContext formContext = new B25.Test_FormHelper.TestFormContext();
        formContext.reservation = new B25__Reservation__c(
            B25__StartLocal__c = Datetime.now(),
            B25__EndLocal__c = Datetime.now().addHours(1)
        );
        B25__Staff__c staff = new B25__Staff__c();
        staff.Name = 'staff';
        Database.insert(staff);

        B25.Test_FormHelper.TestSearchContext changeEvent3 = new B25.Test_FormHelper.TestSearchContext();
        changeEvent3.toSearchSObjectType = B25__Staff__c.SObjectType;
        changeEvent3.toCreateSObjectType = Reservation_Staff__c.SObjectType;
        changeEvent3.fieldName = 'Name';
        changeEvent3.searchTerm = '>';
        B25.Test_FormHelper.runLookupOverrideSearch(formContext, changeEvent3);

        B25.Test_FormHelper.TestRelatedListEvent changeEvent5 = new B25.Test_FormHelper.TestRelatedListEvent();
        changeEvent5.relatedSObjectType = Reservation_Staff__c.SObjectType;
        changeEvent5.addedSObjectId = staff.Id;
        changeEvent5.changedRelatedListItem = new Reservation_Staff__c(
            Staff__c = staff.Id
        );
        B25.Test_FormHelper.runRelatedListAddEvent(formContext, changeEvent5);
    }

    @isTest private static void testSearchStaff2(){
        B25.Test_FormHelper.TestFormContext formContext = new B25.Test_FormHelper.TestFormContext();
        formContext.reservation = new B25__Reservation__c(
            B25__StartLocal__c = Datetime.now(),
            B25__EndLocal__c = Datetime.now().addHours(1)
        );
        B25__Staff__c staff = new B25__Staff__c();
        staff.Name = 'staff';
        Database.insert(staff);

        B25.Test_FormHelper.TestSearchContext changeEvent3 = new B25.Test_FormHelper.TestSearchContext();
        changeEvent3.toSearchSObjectType = B25__Staff__c.SObjectType;
        changeEvent3.toCreateSObjectType = Reservation_Staff__c.SObjectType;
        changeEvent3.fieldName = 'Name';
        changeEvent3.searchTerm = 'asd';
        B25.Test_FormHelper.runLookupOverrideSearch(formContext, changeEvent3);

        B25.Test_FormHelper.TestRelatedListEvent changeEvent5 = new B25.Test_FormHelper.TestRelatedListEvent();
        changeEvent5.relatedSObjectType = Reservation_Staff__c.SObjectType;
        changeEvent5.addedSObjectId = staff.Id;
        changeEvent5.changedRelatedListItem = new Reservation_Staff__c(
            Staff__c = staff.Id
        );
        B25.Test_FormHelper.runRelatedListAddEvent(formContext, changeEvent5);
    }
    @isTest private static void testSearchStaff3(){
        Work_Period__c workPeriod = new Work_Period__c();
        workPeriod.Department__c = 'Costume';
        Database.insert(workPeriod);

        B25.Test_FormHelper.TestFormContext formContext = new B25.Test_FormHelper.TestFormContext();
        formContext.reservation = new B25__Reservation__c(
            B25__StartLocal__c = Datetime.now(),
            B25__EndLocal__c = Datetime.now().addHours(1),
            Work_Period__c = workPeriod.Id
        );
        B25__Staff__c staff = new B25__Staff__c();
        staff.Name = 'staff';
        staff.Department__c = 'Costume';
        Database.insert(staff);

        B25.Test_FormHelper.TestSearchContext changeEvent3 = new B25.Test_FormHelper.TestSearchContext();
        changeEvent3.toSearchSObjectType = B25__Staff__c.SObjectType;
        changeEvent3.toCreateSObjectType = Shift_Staff__c.SObjectType;
        changeEvent3.fieldName = 'Name';
        changeEvent3.searchTerm = 'staff';
        B25.Test_FormHelper.runLookupOverrideSearch(formContext, changeEvent3);

        B25.Test_FormHelper.TestRelatedListEvent changeEvent5 = new B25.Test_FormHelper.TestRelatedListEvent();
        changeEvent5.relatedSObjectType = Shift_Staff__c.SObjectType;
        changeEvent5.addedSObjectId = staff.Id;
        changeEvent5.changedRelatedListItem = new Shift_Staff__c(
            Staff__c = staff.Id
        );
        B25.Test_FormHelper.runRelatedListAddEvent(formContext, changeEvent5);
    }

    @isTest private static void testResource(){
        B25__Resource_type__c resourceType = new B25__Resource_type__c();
        resourceType.Name = 'test';
        Database.insert(resourceType);

        B25__Resource__c resource = new B25__Resource__c();
        resource.NAme = 'Stage';
        resource.B25__Resource_type__c = resourceType.Id;
        Database.insert(resource);
        
        B25.Test_FormHelper.TestFormContext formContext = new B25.Test_FormHelper.TestFormContext();
        formContext.reservation = new B25__Reservation__c(
            B25__StartLocal__c = Datetime.now(),
            B25__EndLocal__c = Datetime.now().addHours(1),
            B25__Resource__c = resource.Id
        );

        B25.Test_FormHelper.TestChangeEvent changeEvent = new B25.Test_FormHelper.TestChangeEvent();
        changeEvent.sObjectField = B25__Reservation__c.B25__Resource__c;
        changeEvent.newValue = resource.Id;
        changeEvent.previousValue = null;
        B25.Test_FormHelper.runFieldChangeEvent(formContext, changeEvent);
    }

    @isTest private static void testServiceReservationChange(){
        B25__Service_Type__c servicetype = new B25__Service_Type__c();
        servicetype.Name = 'F&B';
        Database.insert(servicetype);

        B25__Service__c service = new B25__Service__c();
        service.Name = 'a';
        service.B25__Service_Type__c = servicetype.Id;
        Database.insert(service);

        B25.Test_FormHelper.TestFormContext formContext = new B25.Test_FormHelper.TestFormContext();
        formContext.reservation = new B25__Reservation__c(
            B25__StartLocal__c = Datetime.now(),
            B25__EndLocal__c = Datetime.now().addHours(1)
        );

        B25.Test_FormHelper.TestChangeEvent changeEvent = new B25.Test_FormHelper.TestChangeEvent();
        changeEvent.sObjectField = B25__Service_Reservation__c.Original_Quantity__c;
        changeEvent.newValue = 2;
        changeEvent.previousValue = 1;
        B25.Test_FormHelper.runFieldChangeEvent(formContext, changeEvent);
    }
    @isTest private static void fakeTitleTest() {
        Ctrl_StaffResourceTitle.fakeUnitTest();
    }
}