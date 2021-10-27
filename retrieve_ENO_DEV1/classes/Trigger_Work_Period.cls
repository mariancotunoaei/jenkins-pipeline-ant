public class Trigger_Work_Period {
    public static void run() {
		if (!Trigger.isExecuting) {
			return;
		}

        Trigger_Work_Period.setDepartment();
    }

    public static void setDepartment(){
        if(!(Trigger.isBefore && Trigger.isInsert)){
            return;
        }

        String department = [SELECT Department__c From B25__Staff__c Where B25__User__c = :UserInfo.getUserId() LIMIT 1]?.Department__c;

        List<Work_Period__c> iterList = Trigger.new;
        for(Work_Period__c workPeriod : iterList){
            if(workPeriod.Department__c != null){
                continue;
            }
            workPeriod.Department__c = department;
        }
    }
}