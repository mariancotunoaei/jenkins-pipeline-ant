/**
 * Created by sgrigorescu on 8/6/2021.
 */

@IsTest
public with sharing class MockHttpResponseGenerator implements HttpCalloutMock{
    HttpResponse defaultResponse;
    Map<String, HttpResponse> responseByEndpoint;

    public MockHttpResponseGenerator(HttpResponse r, Map<String, HttpResponse> responseByEndpoint) {
        defaultResponse = r;
        this.responseByEndpoint = responseByEndpoint;
    }

    public HttpResponse respond(HttpRequest req) {
        if (responseByEndpoint == null) {
            return defaultResponse;
        }
        else {
            if (responseByEndpoint.containsKey(req.getEndpoint())) {
                return responseByEndpoint.get(req.getEndpoint());
            }
        }
        return defaultResponse;
    }

    public static void setTestMockResponse(Integer statusCode, String status, String body) {
        setTestMockResponse(statusCode, status, body, null);
    }

    public static void setTestMockResponse(Integer statusCode, String status, String body, Map<String, HttpResponse> responseByEndpoint) {
        HttpResponse mockResp = new HttpResponse();

        if (statusCode != null) {
            mockResp.setStatusCode(statusCode);
        }

        if (status != null) {
            mockResp.setStatus(status);
        }

        if (body != null) {
            mockResp.setBody(body);
        }

        test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResp, responseByEndpoint));
    }
}