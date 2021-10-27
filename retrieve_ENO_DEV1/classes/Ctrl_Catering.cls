public with sharing class Ctrl_Catering {

    public Id reservationId {get;set;}
    public String serviceType {get;set;}

    //used in LWC
    @AuraEnabled(cacheable=true)
    public static List<B25__Service_Reservation__c> getServices(Id reservationId, Boolean cancelled) {
        List<B25__Service_Reservation__c> serviceReservations = new List<B25__Service_Reservation__c>();
        if(cancelled == null || cancelled == false){
            serviceReservations = [
                SELECT Id, Name, Status__c, Service_Ordered_Within_Notice_Period__c,Within_Notice_Period__c,
                Original_Quantity__c,Service_Name__c, B25__Unit_Price__c, B25__Subtotal__c,
                B25__Quantity__c, B25__Service__r.Name,
                B25__Time__c, B25__Notes__c
                FROM B25__Service_Reservation__c 
                WHERE B25__Reservation__c = :reservationId
                AND Status__c != 'Cancelled'
            ];
        } else {
            serviceReservations = [
                SELECT Id, Name, Status__c, Service_Ordered_Within_Notice_Period__c,Within_Notice_Period__c,
                Original_Quantity__c,Service_Name__c, B25__Unit_Price__c, B25__Subtotal__c,
                B25__Quantity__c, B25__Service__r.Name,
                B25__Time__c, B25__Notes__c
                FROM B25__Service_Reservation__c 
                WHERE B25__Reservation__c = :reservationId
                AND Status__c = 'Cancelled'
            ];
        }
        return serviceReservations;
    } 

    @AuraEnabled
    public static string updateServiceReservations(Object data) {
        system.debug(data);
        List<B25__Service_Reservation__c> servResToUpdate = (List<B25__Service_Reservation__c>)JSON.deserialize(
            JSON.serialize(data),
            List <B25__Service_Reservation__c>.class
        );
        try {
            Database.update(servResToUpdate);
            return 'Success: Service Reservation(s) updated successfully';
        } catch (Exception e) {
            return 'The following exception has occurred: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static void changeServiceReservationStatus(List<B25__Service_Reservation__c> serviceReservationList, String status){
        try {
            for(B25__Service_Reservation__c serviceRes : serviceReservationList){
                serviceRes.Status__c = status;
            }
            Database.update(serviceReservationList);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    //Used in a visualforce component for the email
    public List<B25__Service_Reservation__c> getServicesList() {
        return [
            SELECT Id, Name, Status__c, Service_Ordered_Within_Notice_Period__c,Within_Notice_Period__c,
            Original_Quantity__c,Service_Name__c, B25__Unit_Price__c, B25__Subtotal__c,
            B25__Quantity__c, B25__Service__r.Name,
            B25__Time__c, B25__Notes__c
            FROM B25__Service_Reservation__c 
            WHERE B25__Reservation__c = :reservationId
            AND B25__Service__r.B25__Service_Type__r.Name = :serviceType
        ];
    }

}