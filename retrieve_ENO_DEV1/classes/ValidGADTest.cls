/**
 * Created by amacari on 7/8/2021.
 */

@IsTest
private class ValidGADTest {

    @TestSetup
    static void testSetup() {
        Financial_Settings__c financialSettings = new Financial_Settings__c(
                Annual_Non_VAT__c = 5,
                Gift_Aid_Percent__c = 0.25,
                VAT_Value__c = 1.2
        );
        insert financialSettings;

        Contact contact = new Contact();
        contact.FirstName = 'Test';
        contact.LastName = 'ValidGAD';
        contact.CRM_ID_Backend__c = 12345;
        insert contact;

        gaid__Gift_Aid_Declaration__c gad = new gaid__Gift_Aid_Declaration__c();
        gad.gaid__Contact__c = contact.Id;
        gad.gaid__Start_Date__c = System.today();
        gad.gaid__End_Date__c = System.today().addYears(1);
        gad.gaid__Active__c = TRUE;
        gad.gaid__Date_Made__c = System.today();
        insert gad;
    }

    @IsTest
    public static void hasValidGADNowTest(){
        Test.startTest();
        ValidGAD.hasValidGADNow();
        Test.stopTest();
    }

}