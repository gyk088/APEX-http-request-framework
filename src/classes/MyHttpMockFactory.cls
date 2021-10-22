@isTest
global class MyHttpMockFactory implements HttpCalloutMock {
    public Integer code {get; set;}
    public String body {get; set;}

    public MyHttpMockFactory(Integer code, String body) {
        this.code = code;
        this.body = body;
    }

    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setBody(this.body);
        res.setStatusCode(this.code);
        return res;
    }

    public static List<MyHttpRequest__b> getRequestsToTest(integer count) {
        List<MyHttpRequest__b> myReqList = new List<MyHttpRequest__b>();
        DateTime dt = Datetime.now();

        for (Integer i = 0; i < count; i++) {
            MyHttpRequest__b myReq = new MyHttpRequest__b(
                Name__c = i + '-test',
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

            myReqList.add(myReq);
        }

        return myReqList;
    }
}