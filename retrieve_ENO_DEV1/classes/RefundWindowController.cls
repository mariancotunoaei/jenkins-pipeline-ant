/**
 * Created by sgrigorescu on 7/15/2021.
 */

public with sharing class RefundWindowController {
    public static final String ENDPOINT = 'https://api.stripe.com';
    public static final String REFUND_ROUTE = '/v1/refunds';
    public static final String TEST_STRIPE_SECRET_KEY = 'sk_test_51J5XJTBFjx2sSQKeGuwyv39m02n6IO0VQV2qlRFJFMLtAimigoPC87I3cJ7GUPEbp7b5QmzGcneoxSojiGjWVfOM000it30Mi5';

    private with sharing class Payload {
        Decimal amount;
        String paymentIntent; // from Installment, not Payment
        String reason;

        public String getEncodedURL()
        {
            String encodedURL = (this.amount == null ? '' : ('amount=' + encodingutil.urlEncode(String.valueOf(this.amount), 'UTF-8') + '&'))
                    + 'payment_intent=' + encodingUtil.urlEncode(this.paymentIntent, 'UTF-8')
                    + (this.reason == null ? '' : ('&reason=' + encodingutil.urlEncode(this.reason, 'UTF-8')));
            return encodedURL;
        }
    }

    @AuraEnabled
    public static void stripeRefund(Decimal amount, Id paymentId, String reason) {
        try {
            system.debug(paymentId);
            cpm__Payment__c payment = [SELECT Id, cpm__Amount__c, cpm__Installment__r.cpm__Payment_Intent_Id__c  FROM cpm__Payment__c WHERE ID =: paymentId];
            system.debug(JSON.serialize(payment));

            // TODO call Stripe API (documentation: https://stripe.com/docs/api/refunds)
            // Authentication (https://stripe.com/docs/api/authentication) basic access auth
            // 'Provide your API key as the basic auth username value. You do not need to provide a password.'
            // POST Create refund; Charge or paymentIntend fields needed
            HttpRequest request = new HttpRequest();
            request.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(TEST_STRIPE_SECRET_KEY)));
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            request.setEndpoint(ENDPOINT + REFUND_ROUTE);
            request.setMethod('POST');

            Payload payload = new Payload();
            payload.amount = amount;
            payload.paymentIntent = payment.cpm__Installment__r.cpm__Payment_Intent_Id__c;
            payload.reason = reason;

            request.setBody(payload.getEncodedURL());

            HttpResponse response = (new Http()).send(request);
            system.debug(JSON.serialize(response.getBody()));
            if (response.getStatusCode() != 200) {
                throw new CalloutException(response.getBody());
            }

            // TODO add refund (?)
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}