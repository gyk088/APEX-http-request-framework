public virtual class MyHttpRequest {
    public final String url { get; private set; }
    public final String method { get; private set; }
    public String body { get; private set; }
    public Integer repeatTime { get; private set; }
    public Map<String, String> queryParam { get; private set; }
    public Map<String, String> formData { get; private set; }
    public Map<String, String> headers { get; private set; }


    public MyHttpRequest(String url, String method) {
        this.headers = new Map<String, String>();
        this.queryParam = new Map<String, String>();
        this.formData = new Map<String, String>();
        this.url = url;
        this.method = method.toUppercase();
    }

    public HTTPResponse executeSync() {
        MyHttpExecutor myExecutor = new MyHttpExecutor(this);
        return myExecutor.executeSync();
    }

    public ID executeAsync() {
        MyHttpExecutor myExecutor = new MyHttpExecutor(this);
        return myExecutor.executeAsync();
    }

    public ID executeSchedule(Integer repeatTime) {
        this.repeatTime = repeatTime;
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

    public void setRepeatTime(Integer repeatTime) {
        this.repeatTime = repeatTime;
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
    public virtual void beforeSend() {}
}
