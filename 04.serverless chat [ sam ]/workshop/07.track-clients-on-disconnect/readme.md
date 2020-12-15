# 07 TRACK CLIENT - ON DISCONNECT

## LAB PURPOSE

Add functionality that will be trigger when client is disconnected

## DEFINITIONS
----

### AWS LAMBDA

AWS Lambda lets you run code without provisioning or managing servers. You pay only for the compute time you consume - there is no charge when your code is not running.

## STEPS

### 

1. Copy the **infrastructure.yaml** file from the previous lab to this directory.

2. Proceed as in the previous section, add lambda, integration, route and permissions for lambda which will be triggered when client is disconneted. You can find the code of the lanmbda here: **./src/functions/disconnect.js** 
