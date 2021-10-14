# APEX http request framework
## Overview

This framework allows you to send easy http requests

**Deploy to Salesforce Org:**
[![Deploy](https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png)](https://githubsfdeploy.herokuapp.com/?owner=gyk088&repo=APEX-http-request-framework&ref=master)

## Usage

Create httpRequest class:

```java
public class MyHttpRequestExample extends MyHttpRequest  {
    public MyHttpRequestExample() {
        super('https://your.url.com', 'POST');
    }
    override public void success(HTTPResponse res) {
        // if Status Code <= 299
        // implement your logic
    }
    override public void error(HTTPResponse res) {
       // if Status Code > 299
       // implement your logic
    }
    override public void beforeSend() {
        // implement your logic
    }
    override public Boolean repeatCondition(HTTPResponse res) {
        // if you need to send a repeat request
        // before sending a repeated request, the condition is checked, which should be described in this method 
        // also you need to set the repeated request time in seconds
        // MyHttpRequestExample req = new MyHttpRequestExample();
        // req.setRepeatTime(5 * 60) // 5 minutes
        // After 5 minutes will be send a repeat request if this condition return true
        // by default this method return false
        // if this method return true - the request will be sent continuously after RepeatTime seconds
    }
}
```
After that you can use your class to send an http request

```java
    MyHttpRequestExample myReq = new MyHttpRequestExample();

    // if you need to send a GET request with query parameters
    myReq.addQueryParam('example1', '1');
    myReq.addQueryParam('example2', '2');

    // if you need to send a POST request with form data parameters
    myReq.addformData('example1', '1');
    myReq.addformData('example2', '2');

    // if you need to send a POST request with body
    myReq.setBody('{"example1": 1, "example2": 2}');

    // if you need to add some headers
    myReq.addHeader('content-type', 'application/json');

    // if you need to send a repeat request in case which you descride in the repeatCondition method
    myReq.setRepeatTime(5 * 60); // after 5 minutes

    // if you need to send a synchronous request
    // in this case you can get a response , but methods beforeSend and success or error methods will also be called
    HTTPResponse myResponse = myReq.executeSync();

    // if you need to send an asynchronous request
    Id jobID = myReq.executeAsync();

    // if you need to schedule a request
    Id jobID = myReq.executeSchedule(5 * 60); // after 5 minutes
    // or
    myReq.setRepeatTime(5 * 60); // after 5 minutes
    Id jobID = myReq.executeSchedule();
```
If you don't need to override success error beforeSend and repeatCondition methods you can use MyHttpRequest to send simple request
```java
    MyHttpRequest myReq = new MyHttpRequest('https://your.url.com', 'GET');

    myReq.addQueryParam('example1', '1');
    myReq.addQueryParam('example2', '2');

    HTTPResponse myResponse = myReq.executeSync();
    // or
    Id jobID = myReq.executeAsync();
    // or
    Id jobID = myReq.executeSchedule(5 * 60);
    // or
    myReq.setRepeatTime(5 * 60); // after 5 minutes
    Id jobID = myReq.executeSchedule();
```
## Overridable Methods
* `public void success(HTTPResponse res)`
* `public void error(HTTPResponse res)`
* `public void beforeSend()`
* `public Boolean repeatCondition(HTTPResponse res)`

## Methods to use
* `void addQueryParam(String key, String value)`
* `void addformData(String key, String value)`
* `void addHeader(String key, String value)`
* `void setBody(String data)`
* `void setRepeatTime(Integer repeatTime)`
* `HTTPResponse executeSync()`
* `Id executeAsync()`
* `Id executeSchedule()`
* `Id executeSchedule(Integer repeatTime)`
