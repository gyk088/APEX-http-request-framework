@isTest
global class MyHttpMockFactory implements HttpCalloutMock {
    public Integer code {get; set;}
    public String body {get; set;}

    public MyHttpMockFactory(Integer code, String body) {
        this.code = code;
        this.body = body;
    }

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setBody(this.body);
        res.setStatusCode(this.code);
        return res;
    }
}