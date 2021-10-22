public class MyHttpRetryBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
    private static final String NAME = 'MyHttpRetryBatch@';
    private static final Integer MAX_CALLOUTS_IN_SINGLE_TRANSACTION = 100;

    public enum BatchType { REPEAT, CLEAR, CLEARALL, TEST }

    private BatchType currentType;

    public MyHttpRetryBatch() {
        this.currentType = BatchType.REPEAT;
    }

    public MyHttpRetryBatch(string type) {
        this.currentType = BatchType.valueOf(type);
    }

    private List<MyHttpRequest__b> getRequestsToRepeat() {
        return [
            SELECT
                Url__c, Method__c, Name__c,
                FormData__c, QueryParam__c, Headers__c,
                Body__c, NumberOfAttempts__c, ClassName__c,
                LastAttemptDate__c, Repeat__c, StartRepeatDate__c
            FROM MyHttpRequest__b
            WHERE Repeat__c = 1 AND StartRepeatDate__c < :Datetime.now()
        ];
    }

    private List<MyHttpRequest__b> getRequestsToClear() {
        return [
            SELECT
                Repeat__c, StartRepeatDate__c, Name__c
            FROM MyHttpRequest__b
            WHERE Repeat__c = 0
        ];
    }

    private List<MyHttpRequest__b> getAllRequestsToClear() {
        return [
            SELECT
                Repeat__c, StartRepeatDate__c, Name__c
            FROM MyHttpRequest__b
        ];
    }

    public List<MyHttpRequest__b> start(Database.BatchableContext context) {
        switch on this.currentType {
            when REPEAT {
                return this.getRequestsToRepeat();
            }
            when CLEAR {
                return this.getRequestsToClear();
            }
            when CLEARALL {
                return this.getAllRequestsToClear();
            }
            when TEST {
                return MyHttpMockFactory.getRequestsToTest(MAX_CALLOUTS_IN_SINGLE_TRANSACTION);
            } when else {
                return new List<MyHttpRequest__b>();
            }
        }
    }

    public void execute(Database.BatchableContext context, List<MyHttpRequest__b> requests) {
        switch on this.currentType {
            when REPEAT {
                this.repeatRequests(requests);
            }
            when CLEAR, CLEARALL {
                this.clearRequests(requests);
            }
            when TEST {
                this.repeatRequests(requests);
                this.clearRequests(requests);
            }
        }
    }

    private void clearRequests(List<MyHttpRequest__b> clearRequests) {
        List<MyHttpRequest__b> requestsToDelete = new List<MyHttpRequest__b>();

        for (MyHttpRequest__b request : clearRequests) {
            MyHttpRequest__b deleteRequest = new MyHttpRequest__b(
                Name__c = request.Name__c,
                StartRepeatDate__c = request.StartRepeatDate__c,
                Repeat__c = request.Repeat__c
            );

            requestsToDelete.add(deleteRequest);
        }

        if (!Test.isRunningTest()) {
            database.deleteImmediate(requestsToDelete);
        }
    }

    private void repeatRequests(List<MyHttpRequest__b> repeatedRequests) {
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

        if (!Test.isRunningTest()) {
            database.deleteImmediate(requestsToDelete);
            database.insertImmediate(requestsToInsert);
        }
    }

    public void finish(Database.BatchableContext BC) {
        if (!Test.isRunningTest()) {
            this.toSchedule();
        }
    }

    public Id toSchedule() {
        List<MyHttpRequestSettings__mdt> settings = MyHttpRequestSettings__mdt.getAll().values();
        Integer afterTime = Integer.valueOf(settings[0].RepeatInMin__c);
        if (afterTime == null) {
            System.debug(System.logginglevel.WARN, 'Cannot schedule batch: set RepeatInMin__c in MyHttpRequestSettings__mdt');
            return null;
        }

        Datetime dt = Datetime.now();
        dt = dt.addMinutes(afterTime);

        return system.scheduleBatch(this, 'MyHttpBatch (' + this.currentType.name() + ') will start at: ' + dt.format('MM/dd/yyyy HH:mm:ss'), afterTime, MAX_CALLOUTS_IN_SINGLE_TRANSACTION);
    }
}