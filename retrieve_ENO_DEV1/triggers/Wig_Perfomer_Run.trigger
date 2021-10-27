trigger Wig_Perfomer_Run on Wig_Performer_Run__c (before insert, after insert, before update, after update, before delete, after delete) {
    Trigger_Wig_Perfomer_Run.run();
}