public class MyHttpExecutor implements Queueable, Database.AllowsCallouts {
    private final MyHttpRequest myReq;
    private HttpRequest req;

    public MyHttpExecutor(MyHttpRequest myReq) {
        this.myReq = myReq;
    }

    public void execute(QueueableContext context) {
        this.executeSync();
    }

    public Id executeAsync () {
       return System.enqueueJob(this);
    }

    public HTTPResponse executeSync () {
        this.prepare();
        Http http = new Http();

        this.myReq.beforeSend();
        try {
            HTTPResponse res = http.send(this.req);
            if (res.getStatusCode() > 299) {
                this.myReq.error(res);
            } else {
                this.myReq.success(res);
            }

            if (this.myReq.repeatTime != null && this.myReq.repeatCondition(res)) {
                MyHttpScheduler m = new MyHttpScheduler(this.myReq);
                m.toSchedule();
            }

            return res;
        } catch (Exception e) {
            System.debug(System.logginglevel.WARN, 'Cannot execute request: ' + this.myReq.url + '; ' + e.getMessage());

            if (this.myReq.repeatTime != null) {
                MyHttpScheduler m = new MyHttpScheduler(this.myReq);
                m.toSchedule();
            }
        }

        return null;
    }

    private void prepare() {
        HttpRequest req = new HttpRequest();
        req.setMethod(this.myReq.method);
        string url = this.myReq.url;

        for (string key : this.myReq.headers.keySet()) {
            req.setHeader(key, this.myReq.headers.get(key));
        }

        String queryData = this.prepareData(this.myReq.queryParam);
        if (queryData != null) {
            url += ('?' + queryData);
        }

        String formData = this.prepareData(this.myReq.formData);
        if (formData != null) {
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setHeader('Content-Length', String.valueOf(formData.length()));
            req.setBody(formData);
        }

        if (this.myReq.body != null) {
            req.setBody(this.myReq.body);
        }

        req.setEndpoint(url);
        this.req = req;
    }

    private string prepareData(Map<String, String> data) {
        if (data.isEmpty()) {
            return null;
        }

        String stringData = '';
        Set<String> keySet = data.keySet();
        integer i = 0;
        integer last = keySet.size() - 1;
        for (string key : keySet) {
            String encoded = EncodingUtil.urlEncode(data.get(key), 'UTF-8');
            if (i == last) {
                stringData += (key + '=' + encoded);
            } else {
                stringData += (key + '=' + encoded + '&');
            }
            i++;
        }

        return stringData;
    }
}


