# 09 TEST API

## LAB PURPOSE

Test Websocket API

## DEFINITIONS
----

### WebSocket API

To test the WebSocket API, you can use wscat, an open-source, command line tool.

## STEPS

### TEST API


1. Install wscat:
 ```bash
  npm install -g wscat
 ```

2. On the console, connect to your published API endpoint by executing the following command:
 ```bash
  wscat -c wss://{YOUR-API-ID}.execute-api.{YOUR-REGION}.amazonaws.com/{STAGE}
 ```

3.  To test the sendMessage function, send a JSON message like the following example. The Lambda function sends it back using the callback URL:
```json
 {"action":"sendmessage", "data":"hello world"}
```