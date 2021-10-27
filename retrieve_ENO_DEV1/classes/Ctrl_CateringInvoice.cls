public with sharing class Ctrl_CateringInvoice {
	public List<B25__Reservation__c> reservations {get;set;}
	public Map<Id, B25__Service_Reservation__c> serviceItems {get; private set;}

	public Ctrl_CateringInvoice() {
        
        List<String> ids = new List<String>();
        if(ApexPages.currentPage().getParameters().get('id') != null){
            ids.add(ApexPages.currentPage().getParameters().get('id'));
        } else if(ApexPages.currentPage().getParameters().get('ids') != null){
            ids.addAll(ApexPages.currentPage().getParameters().get('ids').split(','));
        }


		if(!ids.isEmpty()) {
			this.reservations = [SELECT Id, B25__Subtotal__c, B25__StartLocal__c, B25__EndLocal__c,
										B25__Contact__r.Name, B25__Contact__r.Email, B25__Base_Price__c, 
										B25__Resource__r.Name, B25__Account__r.Name,
										B25__Quantity__c, B25__Contact__r.FirstName,
                                        B25__User__r.Name, B25__Notes__c,
                                        Cost_Centre_Code__c, Purchase_Order_Number__c,
										(SELECT Id, B25__Quantity__c, B25__Service__r.Name,
                                                B25__Unit_Price__c, B25__Subtotal__c, 
												B25__Service__c
											FROM B25__ServiceReservations__r
											WHERE B25__Subtotal__c > 0
											ORDER BY B25__Service__r.Name
										)
									FROM B25__Reservation__c
									WHERE Id IN :ids
									ORDER BY B25__StartLocal__c];

			this.serviceItems = new Map<Id, B25__Service_Reservation__c>();
			for(B25__Reservation__c reservation : this.reservations){

				for(B25__Service_Reservation__c sr : reservation.B25__ServiceReservations__r){
			   		if (!this.serviceItems.containsKey(sr.B25__Service__c)) {
						this.serviceItems.put(sr.B25__Service__c, sr);
					}

				}
			}
		} 
	}
}