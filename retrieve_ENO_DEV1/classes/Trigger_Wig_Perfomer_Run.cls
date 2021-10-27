public class Trigger_Wig_Perfomer_Run {
    public static void run() {
		if (!Trigger.isExecuting) {
			return;
		}

        Trigger_Wig_Perfomer_Run.setPerformersAndRuns();
    }


    public static void setPerformersAndRuns(){
        if(!(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate))){
            return;
        }

        Set<Id> wigIds = new Set<Id>();
        List<Wig_Performer_Run__c> iterList = Trigger.new;
        for(Wig_Performer_Run__c wigPerformerRun : iterList){
            wigIds.add(wigPerformerRun.Wig__c);
        }

        Set<Id> performerIds = new Set<Id>();
        Set<Id> runIds = new Set<Id>();
        List<Wig__c> wigs = [
            SELECT Id, 
            (SELECT Id, Performer__c from Performer_Wigs__r),
            (SELECT Id, Run__c from Run_Wigs__r)
            FROM Wig__c
            WHERE Id IN :wigIds
        ];
        for(Wig__c wig : wigs){

            for(Performer_Wig__c performerWig : wig.Performer_Wigs__r){
                performerIds.add(performerWig.Performer__c);
            }

            for(Run_Wig__c runWig : wig.Run_Wigs__r){
                runIds.add(runWig.Run__c);    
            }
        }   

        List<Performer_Wig__c> performerWigsToInsert = new List<Performer_Wig__c>();
        List<Run_Wig__c> runWigsToInsert = new List<Run_Wig__c>();
        for(Wig_Performer_Run__c wigPerformerRun : iterList){
            if(!performerIds.contains(wigPerformerRun.Performer__c)){
                Performer_Wig__c performerWig = new Performer_Wig__c();
                performerWig.Performer__c = wigPerformerRun.Performer__c;
                performerWig.Wig__c = wigPerformerRun.Wig__c;
                performerWigsToInsert.add(performerWig);
            }
            if(!runIds.contains(wigPerformerRun.Run__c)){
                Run_Wig__c runWig = new Run_Wig__c();
                runWig.Run__c = wigPerformerRun.Run__c;
                runWig.Wig__c = wigPerformerRun.Wig__c;
                runWigsToInsert.add(runWig);
            }
        }

        Database.insert(performerWigsToInsert);
        Database.insert(runWigsToInsert);
    }
}