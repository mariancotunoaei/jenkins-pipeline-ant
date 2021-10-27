/**
 * Created by sgrigorescu on 8/6/2021.
 */

@IsTest
public with sharing class RefundWindowControllerTest {
    public static String PAYMENT_INTENT_ID = 'pi_testestt3st';
    public static String LAST_NAME= 'Test';

    public static Decimal AMOUNT = 10;
    public static Decimal REFUND_AMOUNT = 5;

    
    @TestSetup
    public static void setup() {
        contact contact = new Contact(
                LastName = LAST_NAME
        );
        insert contact;

        cpm__Installment__c installment = new cpm__Installment__c(
                cpm__Contact__c = contact.Id,
                cpm__Amount__c = AMOUNT,
                cpm__Payment_Intent_Id__c = PAYMENT_INTENT_ID
        );
        insert installment;

        cpm__Payment__c payment = new cpm__Payment__c(
                cpm__Installment__c = installment.Id,
                cpm__Amount__c = AMOUNT,
                cpm__Collection_Date__c = system.Date.today()
        );
        insert payment;
    }

    public static HttpResponse getStripeRefundResponse(Integer statusCode) {
        HttpResponse mock = new HttpResponse();
        mock.setStatusCode(statusCode);
        return mock;
    }

    @IsTest
    public static void testSuccessfulStripeRefund() {
        Test.startTest();

        cpm__Payment__c payment = [SELECT Id from cpm__Payment__c LIMIT 1];

        Map<String, HttpResponse> responseMap = new Map<String, HttpResponse>();
        responseMap.put(RefundWindowController.ENDPOINT + RefundWindowController.REFUND_ROUTE, getStripeRefundResponse(200));
        MockHttpResponseGenerator.setTestMockResponse(200, '', '', responseMap);

        RefundWindowController.stripeRefund(REFUND_AMOUNT, payment.Id, '');

        Test.stopTest();
    }

    @IsTest
    public static void testUnsuccessfulStripeRefund() {
        Test.startTest();

        cpm__Payment__c payment = [SELECT Id from cpm__Payment__c LIMIT 1];

        Map<String, HttpResponse> responseMap = new Map<String, HttpResponse>();
        responseMap.put(RefundWindowController.ENDPOINT + RefundWindowController.REFUND_ROUTE, getStripeRefundResponse(200));
        MockHttpResponseGenerator.setTestMockResponse(404, '', '', responseMap);

        RefundWindowController.stripeRefund(REFUND_AMOUNT, payment.Id, '');

        Test.stopTest();
    }
}