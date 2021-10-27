# APEX http request framework
## Overview

This framework allows you to send easy http requests</br>
This framework has 95% test coverage

Framework features:
* easy way to create http request
* synchronous requests
* asynchronous requests
* scheduled requests
* repeated requests
* storing requests and response data in the big object (MyHttpRequest__b)

**Deploy to Salesforce Org:**<br />
[![Deploy](https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png)](https://githubsfdeploy.herokuapp.com/?owner=gyk088&repo=APEX-http-request-framework&ref=master)

## Usage
### Create http request and execute it synchronously:

```java
    // Create http request object
    MyHttpRequest myReq = new MyHttpRequest('https://your.url.com', 'GET');
    // or
    MyHttpRequest myReq = new MyHttpRequest();
    myReq.setUrl('https://your.url.com');
    myReq.setMethod('GET');
```
##### Add headers to your http request:
```java
    myReq.addHeader('content-type', 'application/json');
```
##### Add data to your http request:

```java
    // if you need to send a request with query string
    myReq.addQueryParam('example1', '1');
    myReq.addQueryParam('example2', '2');

    // if you need to send a request with form data parameters
    myReq.addFormData('example1', '1');
    myReq.addFormData('example2', '2');

    // if you need to send a request with body
    myReq.setBody('{"example1": 1, "example2": 2}');
```

##### Execute your request synchronously:
```java
    HTTPResponse myResponse = myReq.executeSync();
```

### Create http request and execute it asynchronously:
##### Create a child class:
If you need to handle http response, you should сreate child class. Otherwise you can use the MyHttpRequest class.

```java
public class MyHttpRequestExample extends MyHttpRequest {
    public MyHttpRequestExample() {
        super();
    }
    public MyHttpRequestExample(String url, String method) {
        super(url, method);
    }
    override public void beforeSend() {
        // implement your logic
    }
    override public void success(HTTPResponse res) {
        // if Status Code <= 299
        // implement your logic
    }
    override public void error(HTTPResponse res) {
       // if Status Code > 299
       // implement your logic
    }
    override public void finish(HTTPResponse res) {
        // implement your logic
    }
}
```
##### Then you can use your class to send an http request:

```java
    MyHttpRequestExample myReq = new MyHttpRequestExample('https://your.url.com', 'GET');
    // or
    MyHttpRequestExample myReq = new MyHttpRequestExample();
    myReq.setUrl('https://your.url.com');
    myReq.setMethod('POST');

    // also you can add headers and data
    myReq.addHeader('content-type', 'application/json');
    myReq.setBody('{"example1": 1, "example2": 2}');
```

##### Execute your request asynchronously:
```java
    Id jobID = myReq.executeAsync();
```

### Scheduled requests
##### Create a child class:
If you need to handle http response, you should сreate child class. Otherwise you can use the MyHttpRequest class.
```java
    MyHttpRequest myReq = new MyHttpRequest('https://your.url.com', 'GET');
    // add data
    myReq.addQueryParam('example1', '1');
    // schedule a request in 5 minutes
    Id jobID = myReq.executeSchedule(5 * 60);
    // or
    myReq.setAfterSec(5 * 60); // after 5 minutes
    Id jobID = myReq.executeSchedule();
```

### Repeated requests
##### You have to create your child class and define `repeatCondition` method

If you want to repeat your request, you should create child class.<br />
In your class you have to define the `repeatCondition` method which must return true or false.<br />
Until the `repeatCondition` method returns false, your request will repeat every `RepeatInMin` minutes.<br />
The retry interval is determined when you run the `toSchedule` method in the `MyHttpRetryBatch` class<br />
By default `repeatCondition` method returns false.<br />
Also you can define `startAfterInMin` field to add a delay before the first repeat.<br />
By default `startAfterInMin` = 10 minutes.<br />

```java
public class MyHttpRequestExample extends MyHttpRequest {
    public Integer startAfterInMin = 20;

    public MyHttpRequestExample() {
        super();
    }
    public MyHttpRequestExample(String url, String method) {
        super(url, method);
    }
    override public void beforeSend() {
        // implement your logic
    }
    override public void success(HTTPResponse res) {
        // if Status Code <= 299
        // implement your logic
    }
    override public void error(HTTPResponse res) {
       // if Status Code > 299
       // implement your logic
    }
    override public void finish(HTTPResponse res) {
        // implement your logic
    }
    override public Boolean repeatCondition(HTTPResponse res) {
        // If this method returns true, the request will be resend
        // implement your logic
    }
}
```
##### Then you can use your class to send an http request:
```java
    MyHttpRequestExample myReq = new MyHttpRequestExample('https://your.url.com', 'GET');
    // or
    MyHttpRequestExample myReq = new MyHttpRequestExample();
    myReq.setUrl('https://your.url.com');
    myReq.setMethod('POST');

    // also you can add headers and data
    myReq.addHeader('content-type', 'application/json');
    myReq.setBody('{"example1": 1, "example2": 2}');

    HTTPResponse myResponse = myReq.executeSync();
    // or
    Id jobID = myReq.executeAsync();
    // or
    Id jobID = myReq.executeSchedule(5 * 60);
```
##### Then you have to run `MyHttpRetryBatch`:
```java
    MyHttpRetryBatch myHttpRetryBatch = new MyHttpRetryBatch();
    // or
    MyHttpRetryBatch myHttpRetryBatch = new MyHttpRetryBatch('repeat');
    // repeat every 10 minutes
    Id jobId = myHttpRetryBatch.toSchedule(10);
```

##### Also you can run `MyHttpRetryBatch` to clear your data in the big object (MyHttpRequest__b)
```java
    // In this case you clear all requests that do not need to be repeated
    MyHttpRetryBatch myHttpRetryBatch = new MyHttpRetryBatch('clear');
    // repeat every 10 minutes
    Id jobId = myHttpRetryBatch.toSchedule(10);
    // In this case you clear all requests, even those that need to be repeated
    MyHttpRetryBatch myHttpRetryBatch = new MyHttpRetryBatch('clearall');
    // repeat every 10 minutes
    Id jobId = myHttpRetryBatch.toSchedule(10);
```
# MyHttpRequest
## Constructors
* `public MyHttpRequest()`
* `public MyHttpRequest(String url, String method)`
 ## Overridable Methods
* `public void beforeSend()`
* `public void success(HTTPResponse res)`
* `public void error(HTTPResponse res)`
* `public void finish(HTTPResponse res)`
* `public Boolean repeatCondition(HTTPResponse res)`

## Methods to use
* `void addQueryParam(String key, String value)`
* `void addformData(String key, String value)`
* `void addHeader(String key, String value)`
* `void setBody(String body)`
* `void setAfterSec(Integer afterSec)`
* `HTTPResponse executeSync()`
* `Id executeAsync()`
* `Id executeSchedule()`
* `Id executeSchedule(Integer afterSec)`

# MyHttpRetryBatch
## Constructors
* `public MyHttpRetryBatch()`
* `public MyHttpRetryBatch(string type)`
## Methods to use
* `Id toSchedule(Integer repeatAfterMin)`
