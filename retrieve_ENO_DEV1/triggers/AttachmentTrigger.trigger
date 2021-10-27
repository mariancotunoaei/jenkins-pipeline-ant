/**
 * Created by ibuzau on 8/10/2021.
 */

trigger AttachmentTrigger on Attachment (after insert) {

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            System.debug('ATTACHMENT AFTER INSERT');
            List<Id> oppids = new List<Id>(); 
            List<Attachment> attToCreate = new List<Attachment>();
            for (Attachment att : Trigger.new) {
                oppids.add(att.ParentId);
            }
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Name, Id, Document_Generation_Request__c from Opportunity where id in :oppids]);

            for (Attachment att : Trigger.new) {
                if (att.ParentId != null && String.valueOf(att.ParentId).startsWith('006')) {
                    if (oppMap.get(att.ParentId).Document_Generation_Request__c != null) {
                        Attachment newAtt = att.clone();
                        newAtt.ParentId = oppMap.get(att.ParentId).Document_Generation_Request__c;
                        attToCreate.add(newAtt);

                    }

                }

            }
            insert attToCreate;
        }
    }
}