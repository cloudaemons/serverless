# 06 TRACK CLIENT - ON CONNECT

## LAB PURPOSE

Add functionality which will be trigger when client first connects to your WebSocket API.

## DEFINITIONS
----

### AWS LAMBDA

AWS Lambda lets you run code without provisioning or managing servers. You pay only for the compute time you consume - there is no charge when your code is not running.

## STEPS

### CREATE LAMBDA FUNCTION

1. Copy the **infrastructure.yaml** file from the previous lab to this directory.

2. You need to create a lambda function which will be triggered when a client first connects to your WebSocket API.

3. The code of the lambda is prepared for you. Go to **./src/functions/connect.js** file and analyze it. 

4. What you have to do right now, is to create a clouformation resource for your lambda. To do so copy first the **infrastructure.yaml** file from the previous lab to this directory. Then add resource listed below. To check what each field represent go to cloudformation documentation **https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-resource-function.html** 

```yaml
  OnConnectFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: ./src/functions/connect.handler
      MemorySize: 256
      Runtime: nodejs12.x
      Environment:
        Variables:
          TABLE_NAME: !Ref TableName
      Policies:
      - DynamoDBCrudPolicy:
          TableName: !Ref TableName

```
5. Install all dependencies

```bash
  npm install
```

6. And deploy cloudformation file

```bash
 aws cloudformation package --template-file infrastructure.yaml --s3-bucket $ARTIFACT_BUCKET --output-template-file serverless-chat-tmp.yaml
```

```bash
 aws cloudformation deploy --template-file serverless-chat-tmp.yaml --stack-name $PROJECT_NAME --capabilities CAPABILITY_NAMED_IAM --parameter-overrides ProjectName=$PROJECT_NAME Environment=$ENVIRONMENT
```

7. Verify if lambda is created


8. Integrate your lambda with the api gateway. To check what each field represent go to cloudformation documentation **https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-apigatewayv2-integration.html** 

```yaml
  IntegrationConnect:
    Type: AWS::ApiGatewayV2::Integration
    Properties:
      ApiId: !Ref ApiGateway
      Description: Connect Integration
      IntegrationType: AWS_PROXY
      IntegrationUri: 
        Fn::Sub:
            arn:aws:apigateway:${AWS::Region}:lambda:path/2015-03-31/functions/${OnConnectFunction.Arn}/invocations

```

9. Upload local artifacts that might be required by your template. To do so, use the command listed below. In response, you should see serverless-chat-tmp.yaml. This is a template after SAM transformation. Open it and familiarize with its structure.

```bash
 aws cloudformation package --template-file infrastructure.yaml --s3-bucket $ARTIFACT_BUCKET --output-template-file serverless-chat-tmp.yaml
```

10. After you package your template's artifacts, run the deploy command to deploy the returned template.

```bash
  aws cloudformation deploy --template-file serverless-chat-tmp.yaml --stack-name $PROJECT_NAME --capabilities CAPABILITY_NAMED_IAM --parameter-overrides ProjectName=$PROJECT_NAME Environment=$ENVIRONMENT
```

11. Go to cloudformation console  https://console.aws.amazon.com/cloudformation, find your stack **serverless-chat**, and verify what resources have been created, to do that, go to section **Resources**. 

12. Go to API Gateway **http://console.aws.amazon.com/apigateway**, find your api, and verify what have been created

13. Create route resource for an API.  To check what each field represent go to cloudformation documentation **https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-apigatewayv2-route.html** 

```yaml
  RouteConnect:
    Type: AWS::ApiGatewayV2::Route
    Properties:
      ApiId: !Ref ApiGateway
      RouteKey: $connect
      AuthorizationType: NONE
      OperationName: RouteConnect
      Target: !Join
        - '/'
        - - 'integrations'
          - !Ref IntegrationConnect
```

14. Add permission which allows to trigger lambda by the API Gateway

```yaml
 OnConnectPermission:
  Type: AWS::Lambda::Permission
  DependsOn:
    - ApiGateway
  Properties:
    Action: lambda:InvokeFunction
    FunctionName: !Ref OnConnectFunction
    Principal: apigateway.amazonaws.com
```


15. Upload local artifacts that might be required by your template. To do so, use the command listed below. In response, you should see serverless-chat-tmp.yaml. This is a template after SAM transformation. Open it and familiarize with its structure.

```bash
 aws cloudformation package --template-file infrastructure.yaml --s3-bucket $ARTIFACT_BUCKET --output-template-file serverless-chat-tmp.yaml
```

16. After you package your template's artifacts, run the deploy command to deploy the returned template.

```bash
  aws cloudformation deploy --template-file serverless-chat-tmp.yaml --stack-name $PROJECT_NAME --capabilities CAPABILITY_NAMED_IAM --parameter-overrides ProjectName=$PROJECT_NAME Environment=$ENVIRONMENT
```