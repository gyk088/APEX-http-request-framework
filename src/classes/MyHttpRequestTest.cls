@isTest
public class MyHttpRequestTest {
    @isTest
    static void addDataTest() {
        Test.setMock(HttpCalloutMock.class, new MyHttpMockFactory(200, 'test'));
        MyHttpRequest myReq = new MyHttpRequest();
        myReq.addQueryParam('test', '1');
        myReq.addFormData('test', '1');
        myReq.setBody('test');
        myReq.addHeader('content-type', 'application/json');
        myReq.setAfterSec(5 * 60);
        myReq.setUrl('https://test.url');
        myReq.setMethod('get');

        Test.startTest();
        MyHttpRetryBatch testBatch = new MyHttpRetryBatch('test', true);
        testBatch.toSchedule(1);
        Test.stopTest();

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

        list<MyHttpRequest__b> myReqToInit = MyHttpMockFactory.getRequestsToTest(1);

        MyHttpRequest myReq = new MyHttpRequest();
        myReq.init(myReqToInit[0]);
        HttpResponse response = myReq.executeSync();

        Test.startTest();
        MyHttpRetryBatch repeatBatch = new MyHttpRetryBatch();
        repeatBatch.toSchedule(1);
        Test.stopTest();

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
    static void executeSuccessTest() {
        Test.setMock(HttpCalloutMock.class, new MyHttpMockFactory(200, 'test'));

        MyHttpRequest myReq = new MyHttpRequest('https://test.url', 'POST');
        myReq.addFormData('test', '1');
        myReq.addFormData('test2', '1');
        myReq.addHeader('content-type', 'application/json');
        myReq.addQueryParam('test', '1');
        myReq.setBody('test');
        HttpResponse response = myReq.executeSync();

        Test.startTest();
        myReq.executeAsync();
        myReq.executeSchedule();
        myReq.executeSchedule(5);
        MyHttpRetryBatch clearBatch = new MyHttpRetryBatch('clear');
        clearBatch.toSchedule(1);
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
        MyHttpRetryBatch clearAllBatch = new MyHttpRetryBatch('clearall');
        clearAllBatch.toSchedule(1);
        myReq.executeAsync();
        myReq.executeSchedule();
        myReq.executeSchedule(5);
        Test.stopTest();

        System.assertEquals(response.getStatusCode(), 400, 'status code is wrong.');
        System.assertEquals(response.getBody(), 'test', 'body is wrong.');
    }

    @isTest
    static void getRequestsTest() {

        Test.startTest();
            List<MyHttpRequest__b> requests1 = MyHttpController.getRequests(null, false);
            List<MyHttpRequest__b> requests2 = MyHttpController.getRequests('2022-06-22 13:15:44', false);
        Test.stopTest();

        System.assertEquals(requests1.size(), 0, 'size is not correct');
        System.assertEquals(requests2.size(), 0, 'size is not correct');
    }

    @isTest
    static void sendRequestTest() {
        Test.setMock(HttpCalloutMock.class, new MyHttpMockFactory(200, 'test'));

        Test.startTest();
            MyHttpController.sendRequest('{"url":"https://test.url","method":"GET", "body":"test","headers":[{"name":"test","value":"test"}],"formData":[{"name":"test","value":"test"}],"queryParams":[{"name":"test","value":"test"}]}');
        Test.stopTest();
    }

    @isTest
    static void runBatchTest() {
        Test.setMock(HttpCalloutMock.class, new MyHttpMockFactory(200, 'test'));

        Test.startTest();
            MyHttpController.runBatch('REPEAT', 10, false);
            List<CronTrigger> batches = MyHttpController.getListOfBatches();
            MyHttpController.stopBatch(batches[0].Id);
        Test.stopTest();

        System.assertEquals(batches.size(), 1, 'size is not correct');
    }
}