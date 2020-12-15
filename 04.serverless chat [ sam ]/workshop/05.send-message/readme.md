# 05 SEND MESSAGE

## LAB PURPOSE

Add endpoint responsible for receiving the data sent by one of the clients,  verifing all the currently connected clients, and sending the provided data to each of them

## DEFINITIONS
----

### AWS LAMBDA

AWS Lambda lets you run code without provisioning or managing servers. You pay only for the compute time you consume - there is no charge when your code is not running.


## STEPS

### CREATE LAMBDA FUNCTION

1. Copy the **infrastructure.yaml** file from the previous lab to this directory.

2. You need to create a lambda function to send and recive messages 

3. The code of the lambda is prepared for you. Go to **./src/functions/send-message.js** file and analyze it. 

4. What you have to do right now, is to create a clouformation resource for your lambda. To do so copy first the **infrastructure.yaml** file from the previous lab to this directory. Then add resource listed below. To check what each field represent go to cloudformation documentation **https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-resource-function.html** 

```yaml
  SendMessageFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: ./src/functions/send-message.handler
      MemorySize: 256
      Runtime: nodejs12.x
      Environment:
        Variables:
          TABLE_NAME: !Ref TableName
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

8. Grant permission for lambda that allows it access to the database and triggers the API gateway. To check what each field represent go to cloudformation documentation **https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-resource-function.html** 

```yaml
  SendMessageFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: ./src/functions/send-message.handler
      MemorySize: 256
      Runtime: nodejs12.x
      Environment:
        Variables:
          TABLE_NAME: !Ref TableName
      Policies:
      - DynamoDBCrudPolicy:
          TableName: !Ref TableName
      - Statement:
        - Effect: Allow
          Action:
          - 'execute-api:ManageConnections'
          Resource:
          - !Sub 'arn:aws:execute-api:${AWS::Region}:${AWS::AccountId}:${ApiGateway}/*'
```

9. Integrate your lambda with the api gateway. To check what each field represent go to cloudformation documentation **https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-apigatewayv2-integration.html** 

```yaml
  IntegrationSendMessage:
    Type: AWS::ApiGatewayV2::Integration
    Properties:
      ApiId: !Ref ApiGateway
      Description: Send Integration
      IntegrationType: AWS_PROXY
      IntegrationUri: 
        Fn::Sub:
            arn:aws:apigateway:${AWS::Region}:lambda:path/2015-03-31/functions/${SendMessageFunction.Arn}/invocations

```

10. Upload local artifacts that might be required by your template. To do so, use the command listed below. In response, you should see serverless-chat-tmp.yaml. This is a template after SAM transformation. Open it and familiarize with its structure.

```bash
 aws cloudformation package --template-file infrastructure.yaml --s3-bucket $ARTIFACT_BUCKET --output-template-file serverless-chat-tmp.yaml
```

11. After you package your template's artifacts, run the deploy command to deploy the returned template.

```bash
  aws cloudformation deploy --template-file serverless-chat-tmp.yaml --stack-name $PROJECT_NAME --capabilities CAPABILITY_NAMED_IAM --parameter-overrides ProjectName=$PROJECT_NAME Environment=$ENVIRONMENT
```

12. Go to cloudformation console  https://console.aws.amazon.com/cloudformation, find your stack **serverless-chat**, and verify what resources have been created, to do that, go to section **Resources**. 

13. Go to API Gateway **http://console.aws.amazon.com/apigateway**, find your api, and verify what have been created

14. Create route resource for an API.  To check what each field represent go to cloudformation documentation **https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-apigatewayv2-route.html** 

```yaml
 RouteSendMessage:
  Type: AWS::ApiGatewayV2::Route
  Properties:
    ApiId: !Ref ApiGateway
    RouteKey: sendmessage
    AuthorizationType: NONE
    OperationName: RouteSendMessage
    Target: !Join
      - '/'
      - - 'integrations'
        - !Ref IntegrationSendMessage
```

15. Add permission which allows to trigger lambda by the API Gateway

```yaml
 SendMessagePermission:
  Type: AWS::Lambda::Permission
  DependsOn:
    - ApiGateway
  Properties:
    Action: lambda:InvokeFunction
    FunctionName: !Ref SendMessageFunction
    Principal: apigateway.amazonaws.com
```


16. Upload local artifacts that might be required by your template. To do so, use the command listed below. In response, you should see serverless-chat-tmp.yaml. This is a template after SAM transformation. Open it and familiarize with its structure.

```bash
 aws cloudformation package --template-file infrastructure.yaml --s3-bucket $ARTIFACT_BUCKET --output-template-file serverless-chat-tmp.yaml
```

17. After you package your template's artifacts, run the deploy command to deploy the returned template.

```bash
  aws cloudformation deploy --template-file serverless-chat-tmp.yaml --stack-name $PROJECT_NAME --capabilities CAPABILITY_NAMED_IAM --parameter-overrides ProjectName=$PROJECT_NAME Environment=$ENVIRONMENT
```