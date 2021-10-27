public class Trigger_Wig {
    public static void run() {
		if (!Trigger.isExecuting) {
			return;
		}

        Trigger_Wig.setPerformers();
    }

    public static void setPerformers(){
        if(!(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate))){
            return;
        }

        Set<Id> wigIds = new Set<Id>();
        List<Wig__c> iterList = Trigger.new;
        for(Wig__c wig : iterList){
            wigIds.add(wig.Id);
        }


        Set<Id> performerWigsIds = new Set<Id>();
        List<Performer_Wig__c> performerWigs = [SELECT Wig__c, Performer__c FROM Performer_Wig__c WHERE Wig__c = :wigIds];
        for(Performer_Wig__c pWig : performerWigs){
            performerWigsIds.add(pWig.Performer__c);
        }

        List<Performer_Wig__c> toInsert = new List<Performer_Wig__c>();
        for(Wig__c wig : iterList){
            if(wig.Active_Performer__c != null && 
               !performerWigsIds.contains(wig.Active_Performer__c)
            ){
                Performer_Wig__c newPerformerWig = new Performer_Wig__c();
                newPerformerWig.Wig__c = wig.Id;
                newPerformerWig.Performer__c = wig.Active_Performer__c;
                toInsert.add(newPerformerWig);
            }
            if(wig.Original_Performer__c != wig.Active_Performer__c &&
               wig.Original_Performer__c != null && 
               !performerWigsIds.contains(wig.Original_Performer__c)
            ){
                Performer_Wig__c newPerformerWig = new Performer_Wig__c();
                newPerformerWig.Wig__c = wig.Id;
                newPerformerWig.Performer__c = wig.Original_Performer__c;
                toInsert.add(newPerformerWig);
            }
        }

        Database.insert(toInsert);

    }
}