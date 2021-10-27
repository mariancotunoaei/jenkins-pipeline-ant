@IsTest
private class Test_Wig {
    
    @isTest private static void createWigPerformers(){
        Performer__c performer1 = new Performer__c();
        performer1.Name = 'name';
        Database.insert(performer1);
        
        Performer__c performer2 = new Performer__c();
        performer2.Name = 'name2';
        Database.insert(performer2);

        Wig__c wig = new Wig__c();
        wig.Wig_Label_Ref_Number__c = '1';
        wig.Active_Performer__c = performer1.Id;
        wig.Original_Performer__c = performer2.Id;
        Database.insert(wig);

        System.assertEquals(2, [SELECT ID From Performer_Wig__c].size());

    }

    @isTest private static void createWigPerformerRun() {
        Wig__c wig = new Wig__c();
        wig.Wig_Label_Ref_Number__c = '1';
        Database.insert(wig);
        
        Performer__c performer1 = new Performer__c();
        performer1.Name = 'name';
        Database.insert(performer1);

        Production__c production = new Production__c();
        production.Name = 'production';
        Database.insert(production);

        Run__c run = new Run__c();
        run.Name = 'run';
        run.Production__c = production.Id;
        Database.insert(run);

        Wig_Performer_Run__c wigPerfomerRun = new Wig_Performer_Run__c();
        wigPerfomerRun.Run__c = run.Id;
        wigPerfomerRun.Performer__c = performer1.Id;
        wigPerfomerRun.Wig__c = wig.Id;
        Database.insert(wigPerfomerRun);

        System.assertEquals(1, [SELECT ID From Performer_Wig__c].size());
        System.assertEquals(1, [SELECT ID From Run_Wig__c].size());


        Wig_Performer_Run__c wigPerfomerRun2 = new Wig_Performer_Run__c();
        wigPerfomerRun2.Run__c = run.Id;
        wigPerfomerRun2.Performer__c = performer1.Id;
        wigPerfomerRun2.Wig__c = wig.Id;
        Database.insert(wigPerfomerRun2);

        System.assertEquals(1, [SELECT ID From Performer_Wig__c].size());
        System.assertEquals(1, [SELECT ID From Run_Wig__c].size());

    }
}