public class MyHttpRetryBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
    private static final String NAME = 'MyHttpRetryBatch@';
    private static final Integer MAX_CALLOUTS_IN_SINGLE_TRANSACTION = 100;

    public List<MyHttpRequest__b> start(Database.BatchableContext context) {
        List<MyHttpRequest__b> repeatedRequests = [
            SELECT
                Url__c, Method__c, Name__c,
                FormData__c, QueryParam__c, Headers__c,
                Body__c, NumberOfAttempts__c, ClassName__c,
                LastAttemptDate__c, Repeat__c, StartRepeatDate__c
            FROM MyHttpRequest__b
            WHERE Repeat__c = 1 AND StartRepeatDate__c < :Datetime.now()
        ];
        return repeatedRequests;
    }

    public void execute(Database.BatchableContext context, List<MyHttpRequest__b> repeatedRequests) {
        List<MyHttpRequest__b> requestsToInsert = new List<MyHttpRequest__b>();
        List<MyHttpRequest__b> requestsToDelete = new List<MyHttpRequest__b>();

        for (MyHttpRequest__b request : repeatedRequests) {
            Type MyHttpRequest = Type.forName(request.ClassName__c);
            MyHttpRequest myReq = (MyHttpRequest)MyHttpRequest.newInstance();
            myReq.init(request);

            DateTime tik = Datetime.now();
            HTTPResponse response = myReq.executeSync();
            DateTime tok = Datetime.now();

            Boolean repeat = myReq.repeatCondition(response);

            MyHttpRequest__b insertRequest = new MyHttpRequest__b(
                Name__c = request.Name__c,
                NumberOfAttempts__c = request.NumberOfAttempts__c + 1,
                Url__c = request.Url__c,
                Method__c = request.Method__c,
                Tik__c = tik,
                Tok__c = tok,
                StartRepeatDate__c = request.StartRepeatDate__c,
                LastAttemptDate__c = tik,
                FormData__c = request.FormData__c,
                QueryParam__c = request.QueryParam__c,
                Headers__c = request.Headers__c,
                Body__c = request.Body__c,
                ClassName__c = request.ClassName__c,
                ResponseBody__c = response.getBody(),
                StatusCode__c = response.getStatusCode(),
                Repeat__c = repeat ? 1 : 0
            );

            MyHttpRequest__b deleteRequest = new MyHttpRequest__b(
                Name__c = request.Name__c,
                StartRepeatDate__c = request.StartRepeatDate__c,
                Repeat__c = request.Repeat__c
            );

            requestsToInsert.add(insertRequest);
            requestsToDelete.add(deleteRequest);
        }

        database.deleteImmediate(requestsToDelete);
        database.insertImmediate(requestsToInsert);
    }

    public void finish(Database.BatchableContext BC) {
        this.toSchedule();
    }

    public Id toSchedule() {
        List<MyHttpRequestSettings__mdt> settings = MyHttpRequestSettings__mdt.getAll().values();
        Integer afterTime = Integer.valueOf(settings[0].RepeatInMin__c);
        if (afterTime == null) {
            return null;
        }

        Datetime dt = Datetime.now();
        dt = dt.addMinutes(afterTime);

        return system.scheduleBatch(this, 'MyHttpBatch will start at: ' + dt.format('MM/dd/yyyy HH:mm:ss'), afterTime, MAX_CALLOUTS_IN_SINGLE_TRANSACTION);
    }
}