public class MyHttpExecutor implements Queueable, Database.AllowsCallouts {
    private MyHttpRequest myReq;
    private HttpRequest req;
    private String queryParam;
    private String formData;
    private String headers;

    public MyHttpExecutor(MyHttpRequest myReq) {
        this.myReq = myReq;
    }

    public void execute(QueueableContext context) {
        this.executeSync();
    }

    public Id executeAsync() {
       return System.enqueueJob(this);
    }

    public HTTPResponse executeSync() {
        this.prepare();
        Http http = new Http();

        this.myReq.beforeSend();

        DateTime tik = Datetime.now();
        HTTPResponse res = http.send(this.req);
        DateTime tok = Datetime.now();

        if (res.getStatusCode() > 299) {
            this.myReq.error(res);
        } else {
            this.myReq.success(res);
        }
        this.myReq.finish(res);

        if (this.myReq.id == null) {
            this.saveRequest(this.myReq.repeatCondition(res), tik, tok, res);
        }

        return res;
    }

    private void saveRequest(Boolean repeat, Datetime tik, Datetime tok, HTTPResponse res) {
        MyHttpRequest__b myReqToSave = new MyHttpRequest__b(
            Name__c = this.createId(),
            NumberOfAttempts__c = 0,
            StartRepeatDate__c = tik.addMinutes(this.myReq.startAfterInMin),
            LastAttemptDate__c = tik,
            Url__c = this.myReq.url,
            Method__c = this.myReq.method,
            Tik__c = tik,
            Tok__c = tok,
            FormData__c = this.formData,
            QueryParam__c = this.queryParam,
            Headers__c = this.headers,
            Body__c = this.myReq.body,
            Repeat__c = repeat ? 1 : 0,
            ClassName__c = String.valueOf(this.myReq).split(':')[0],
            ResponseBody__c = res.getBody(),
            StatusCode__c = res.getStatusCode()
        );


        if (!Test.isRunningTest()) {
            Database.SaveResult sr = database.insertImmediate(myReqToSave);
            if (!sr.isSuccess()) {
                System.debug(System.logginglevel.WARN, 'Cannot create request: ' + this.myReq.url + '; ' + sr.getErrors());
            }
        }
    }

    private String createId() {
        List<MyHttpRequest__b> lastRequest = [SELECT Name__c FROM MyHttpRequest__b LIMIT 1];

        Datetime dt = Datetime.now();
        String newId;
        if (lastRequest.isEmpty()) {
            newId = '0-' + String.valueOf(dt.getTime());
        } else {
            List<String> lastId = lastRequest[0].Name__c.split('-');
            newId = String.valueOf(Integer.valueOf(lastId[0]) + 1) + '-' + String.valueOf(dt.getTime());
        }

        return newId;
    }

    private void prepare() {
        HttpRequest req = new HttpRequest();
        req.setMethod(this.myReq.method);
        string url = this.myReq.url;

        this.headers = this.prepareData(this.myReq.headers);
        for (string key : this.myReq.headers.keySet()) {
            req.setHeader(key, this.myReq.headers.get(key));
        }

        this.queryParam = this.prepareData(this.myReq.queryParam);
        if (this.queryParam != null) {
            url += ('?' + this.queryParam);
        }

        this.formData = this.prepareData(this.myReq.formData);
        if (this.formData != null) {
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setHeader('Content-Length', String.valueOf(formData.length()));
            req.setBody(this.formData);
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