public class MyHttpScheduler implements Schedulable {
    private final MyHttpRequest myReq;

    public MyHttpScheduler(MyHttpRequest myReq) {
        this.myReq = myReq;
    }

    public void execute(SchedulableContext SC) {
        MyHttpExecutor myExecutor = new MyHttpExecutor(this.myReq);
        System.enqueueJob(myExecutor);
    }

    public Id toSchedule() {
        if (this.myReq.afterSec == null) {
            return null;
        }

        Datetime dt = Datetime.now();
        dt = dt.addSeconds(this.myReq.afterSec);

        String sch = dt.second() + ' ' + dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' +  dt.month() + ' ? ' + dt.year();

        Long epoch= dt.getTime();
        return system.schedule('MyHttpScheduler will start at: ' + dt.format('MM/dd/yyyy HH:mm:ss'), sch, this);
    }
}
