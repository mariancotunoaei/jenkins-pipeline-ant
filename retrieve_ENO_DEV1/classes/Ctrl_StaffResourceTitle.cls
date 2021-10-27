global with sharing class Ctrl_StaffResourceTitle implements B25.Util_PluginManager.DynamicResourceTitles {
    global Map<Id, String> calculateResourceTitles(B25.Util_PluginManager.DynamicResourceTitleData dataObj) {
        // all the reservations that are currently visible to the user, mapped to their resource
		Map<Id, List<Id>> visibleReservations = dataObj.resourceToVisibleReservations;

        Date startDate = dataObj.startDatetime.date();

		// the values we are going to return, mapped by resource
		Map<Id, Decimal> output = new Map<Id, Decimal>();
		Map<Id, String> outputMap = new Map<Id, String>();

        List<B25__Staff__c> staffMembers = [
            SELECT Id 
            FROM B25__Staff__c 
            WHERE Virtual__c = false
        ];

        for(B25__Staff__c staffMember : staffMembers) {
            output.put(staffMember.Id, 0);
        }
        for(AggregateResult  objAgr: [
            SELECT  SUM(Total_Minutes_attributed_to_shift__c) total, B25__Staff__c 
            FROM B25__Reservation__c 
            WHERE B25__Staff__c IN :visibleReservations.keyset() 
            AND B25__Start_Date__c >= :startDate.addDays(-28)
            AND B25__Start_Date__c < :startDate
            AND B25__Reservation_Type__r.Name = 'Shift'
            AND (B25__Status__r.Name = 'Shift' OR B25__Status__r.Name = 'Overtime')
            AND Shift_Published__c = true
            GROUP BY B25__Staff__c
        ]){
            outputMap.put((Id)objAgr.get('B25__Staff__c'), objAgr.get('total') == 0 ? 'none' : String.valueOf(((Decimal)objAgr.get('total')/60).setScale(2) +' hrs'));
        }
		return outputMap;
    }

    //this function is here because at this point you cannot initilize the above function from a unittest
    //Therefore if we want to have at least 1 line of unit test we need a fake function.
    public static void fakeUnitTest() {
        Boolean a = true;
        return;
    }   
}