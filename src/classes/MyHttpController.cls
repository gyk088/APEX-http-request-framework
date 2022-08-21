public inherited sharing class MyHttpController {

    @AuraEnabled
    public static List<MyHttpRequest__b> getRequests(String fromDate, Boolean repeat) {
        DateTime dt;
        try {
            dt = DateTime.valueOfGMT(fromDate);
        } catch (Exception ex) {
            dt = DateTime.now();
        }

        Integer showRepeated = repeat ? 1 : 0;
        return [SELECT Body__c, ClassName__c, FormData__c, Headers__c,
                    LastAttemptDate__c, Method__c, Name__c, NumberOfAttempts__c,
                    QueryParam__c, Repeat__c, ResponseBody__c, StartRepeatDate__c,
                    StatusCode__c, Tik__c, Tok__c, Url__c
                FROM MyHttpRequest__b WHERE Repeat__c = :showRepeated AND StartRepeatDate__c > :dt LIMIT 40000];
    }

    @AuraEnabled
    public static void sendRequest(String jsonData) {
        MyHttpRequestWrapper requestWrapper = (MyHttpRequestWrapper) JSON.deserialize(jsonData, MyHttpRequestWrapper.class);
        MyHttpRequest myReq = new MyHttpRequest(requestWrapper.url, requestWrapper.method);

        for (Map<String,String> header : requestWrapper.headers) {
            if (!header.containsKey('name') || !header.containsKey('value')) { continue; }
            myReq.addHeader(header.get('name'), header.get('value'));
        }

        for (Map<String,String> queryParam : requestWrapper.queryParams) {
            if (!queryParam.containsKey('name') || !queryParam.containsKey('value')) { continue; }
            myReq.addQueryParam(queryParam.get('name'), queryParam.get('value'));
        }

        for (Map<String,String> formData : requestWrapper.formData) {
            if (!formData.containsKey('name') || !formData.containsKey('value')) { continue; }
            myReq.addFormData(formData.get('name'), formData.get('value'));
        }

        if (!String.isEmpty(requestWrapper.body)) {
            myReq.setBody(requestWrapper.body);
        }

        myReq.executeSync();
    }

    @AuraEnabled
    public static void stopBatch(Id jobID) {
        System.abortJob(jobID);
    }

    @AuraEnabled
    public static void runBatch(string type, Integer min, Boolean repeat) {
        MyHttpRetryBatch myHttpRetryBatch = new MyHttpRetryBatch(type, repeat);
        myHttpRetryBatch.toSchedule(min);
    }

    @AuraEnabled
    public static List<CronTrigger> getListOfBatches() {
        return [SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType
                FROM CronTrigger
                WHERE CronJobDetail.Name LIKE 'MyHttpBatch (%'];
    }

    public class MyHttpRequestWrapper {
        String url;
        String method;
        String body;
        List<Map<String,String>> headers;
        List<Map<String,String>> queryParams;
        List<Map<String,String>> formData;
    }
}
