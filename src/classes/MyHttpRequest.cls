public virtual class MyHttpRequest {
    public String url { get; private set; }
    public String method { get; private set; }
    public String body { get; private set; }
    public String id { get; private set; }
    public Integer afterSec { get; private set; }
    public Map<String, String> queryParam { get; private set; }
    public Map<String, String> formData { get; private set; }
    public Map<String, String> headers { get; private set; }
    public Integer startAfterInMin = 10;

    public MyHttpRequest() {
        this.headers = new Map<String, String>();
        this.queryParam = new Map<String, String>();
        this.formData = new Map<String, String>();
    }

    public MyHttpRequest(String url, String method) {
        this.headers = new Map<String, String>();
        this.queryParam = new Map<String, String>();
        this.formData = new Map<String, String>();
        this.url = url;
        this.method = method.toUppercase();
    }

    public void init(MyHttpRequest__b request) {
        this.headers = this.parseDate(request.Headers__c);
        this.queryParam = this.parseDate(request.queryParam__c);
        this.formData = this.parseDate(request.formData__c);
        this.method = request.Method__c;
        this.url = request.Url__c;
        this.body = request.Body__c;
        this.id = request.Name__c;
    }

    private Map<String, String> parseDate (String data) {
        Map<String, String> result = new Map<String, String>();

        if (data == null) {
            return result;
        }

        List<String> chunk = data.split('&');
        for (String keyValue : chunk) {
            List<String> keyValueList = keyValue.split('=');
            result.put(
                EncodingUtil.urlDecode(keyValueList[0], 'UTF-8'),
                EncodingUtil.urlDecode(keyValueList[1], 'UTF-8')
            );
        }

        return result;
    }

    public HTTPResponse executeSync() {
        MyHttpExecutor myExecutor = new MyHttpExecutor(this);
        return myExecutor.executeSync();
    }

    public ID executeAsync() {
        MyHttpExecutor myExecutor = new MyHttpExecutor(this);
        return myExecutor.executeAsync();
    }

    public ID executeSchedule(Integer afterSec) {
        this.afterSec = afterSec;
        MyHttpScheduler m = new MyHttpScheduler(this);
        return m.toSchedule();
    }

    public ID executeSchedule() {
        MyHttpScheduler m = new MyHttpScheduler(this);
        return m.toSchedule();
    }

    public void setBody(String body) {
        this.body = body;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    public void setMethod(String method) {
        this.method = method.toUppercase();
    }

    public void setAfterSec(Integer afterSec) {
        this.afterSec = afterSec;
    }

    public void addQueryParam(String key, String value) {
        this.queryParam.put(key, value);
    }

    public void addformData(String key, String value) {
        this.formData.put(key, value);
    }

    public void addHeader(String key, String value) {
        this.headers.put(key, value);
    }

    public virtual Boolean repeatCondition(HTTPResponse res) {
        return false;
    }

    public virtual void success(HTTPResponse res) {}
    public virtual void error(HTTPResponse res) {}
    public virtual void finish(HTTPResponse res) {}
    public virtual void beforeSend() {}
}
