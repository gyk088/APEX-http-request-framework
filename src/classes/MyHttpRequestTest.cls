@isTest
public class MyHttpRequestTest {
    @isTest
    static void addDataTest() {
        MyHttpRequest myReq = new MyHttpRequest();
        myReq.addQueryParam('test', '1');
        myReq.addformData('test', '1');
        myReq.setBody('test');
        myReq.addHeader('content-type', 'application/json');
        myReq.setAfterSec(5 * 60);
        myReq.setUrl('https://test.url');
        myReq.setMethod('get');

        System.assertEquals(myReq.queryParam.get('test'), '1', 'queryParam is wrong.');
        System.assertEquals(myReq.formData.get('test'), '1', 'formData is wrong.');
        System.assertEquals(myReq.headers.get('content-type'), 'application/json', 'headers is wrong.');
        System.assertEquals(myReq.afterSec, 5 * 60, 'repeatTime is wrong.');
        System.assertEquals(myReq.body, 'test', 'body is wrong.');
        System.assertEquals(myReq.method, 'GET', 'method is wrong.');
        System.assertEquals(myReq.url, 'https://test.url', 'url is wrong.');
    }

    @isTest
    static void initRequestTest() {
        Test.setMock(HttpCalloutMock.class, new MyHttpMockFactory(200, 'test'));

        DateTime dt = Datetime.now();
        MyHttpRequest__b myReqToInit = new MyHttpRequest__b(
            Name__c = '0-test',
            NumberOfAttempts__c = 0,
            StartRepeatDate__c = dt,
            LastAttemptDate__c = dt,
            Url__c = 'https://test.url',
            Method__c = 'POST',
            Tik__c = dt,
            Tok__c = dt,
            FormData__c = 'test1=1&test2=2',
            QueryParam__c = 'test1=1&test2=2',
            Body__c = 'test',
            Repeat__c = 0,
            ClassName__c = 'MyHttpRequest',
            ResponseBody__c = 'test',
            StatusCode__c = 200
        );

        MyHttpRequest myReq = new MyHttpRequest();
        myReq.init(myReqToInit);
        HttpResponse response = myReq.executeSync();

        System.assertEquals(myReq.queryParam.get('test1'), '1', 'queryParam is wrong.');
        System.assertEquals(myReq.queryParam.get('test2'), '2', 'queryParam is wrong.');
        System.assertEquals(myReq.formData.get('test1'), '1', 'formData is wrong.');
        System.assertEquals(myReq.formData.get('test2'), '2', 'formData is wrong.');
        System.assertEquals(myReq.body, 'test', 'body is wrong.');
        System.assertEquals(myReq.method, 'POST', 'method is wrong.');
        System.assertEquals(myReq.url, 'https://test.url', 'url is wrong.');
        System.assertEquals(myReq.id, '0-test', 'id is wrong.');

        System.assertEquals(response.getStatusCode(), 200, 'status code is wrong.');
        System.assertEquals(response.getBody(), 'test', 'body is wrong.');
    }

    @isTest
    static void executeBatchTest() {
        Test.startTest();
        MyHttpRetryBatch batch = new MyHttpRetryBatch();
        batch.toSchedule();
        Test.stopTest();
    }

    @isTest
    static void executeSuccessTest() {
        Test.setMock(HttpCalloutMock.class, new MyHttpMockFactory(200, 'test'));

        MyHttpRequest myReq = new MyHttpRequest('https://test.url', 'POST');
        myReq.addformData('test', '1');
        myReq.addformData('test2', '1');
        myReq.addHeader('content-type', 'application/json');
        myReq.addQueryParam('test', '1');
        myReq.setBody('test');
        HttpResponse response = myReq.executeSync();

        Test.startTest();
        myReq.executeAsync();
        myReq.executeSchedule();
        myReq.executeSchedule(5);
        Test.stopTest();

        System.assertEquals(response.getStatusCode(), 200, 'status code is wrong.');
        System.assertEquals(response.getBody(), 'test', 'body is wrong.');
    }

    @isTest
    static void executeErorrTest() {
        Test.setMock(HttpCalloutMock.class, new MyHttpMockFactory(400, 'test'));

        MyHttpRequest myReq = new MyHttpRequest('https://test.url', 'POST');
        HttpResponse response = myReq.executeSync();

        Test.startTest();
        myReq.executeAsync();
        myReq.executeSchedule();
        myReq.executeSchedule(5);
        Test.stopTest();

        System.assertEquals(response.getStatusCode(), 400, 'status code is wrong.');
        System.assertEquals(response.getBody(), 'test', 'body is wrong.');
    }
}

