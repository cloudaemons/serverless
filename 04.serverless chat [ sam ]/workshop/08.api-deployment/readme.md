# 08 API DEPLOYMENT

## LAB PURPOSE

Add resources which allows for API Deployment

## DEFINITIONS
----

### API GATEWAY

Amazon API Gateway is a fully managed service that makes it easy for developers to create, publish, maintain, monitor, and secure APIs at any scale

### API GATEWAY

## STEPS

### CREATE API DEPLOYMENT

1. Copy the **infrastructure.yaml** file from the previous lab to this directory.

2. To deploy an API, you have to create an API deployment and associate it with a stage. A stage is a logical reference to a lifecycle state of your API Below you have cloudformation resource which is responsible for that. You need to add this clloudformation resource to your **infrastructure.yaml** file. Please add it to section **Resources**. If you need any help check how the solution should look like. To check what each field represent go to cloudformation documentation **https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-apigatewayv2-deployment.html**

  ```yaml
  Deployment:
    Type: AWS::ApiGatewayV2::Deployment
    DependsOn:
    - RouteConnect
    - RouteSendMessage
    - RouteDisconnect
    Properties:
      ApiId: !Ref ApiGateway


  Stage:
    Type: AWS::ApiGatewayV2::Stage
    Properties:
      StageName: Prod
      Description: Prod Stage
      DeploymentId: !Ref Deployment
      ApiId: !Ref ApiGateway
  ```


3. Upload local artifacts that might be required by your template. To do so, use the command listed below. In response, you should see serverless-chat-tmp.yaml. This is a template after SAM transformation. Open it and familiarize with its structure.

```bash
 aws cloudformation package --template-file infrastructure.yaml --s3-bucket $ARTIFACT_BUCKET --output-template-file serverless-chat-tmp.yaml
```

4. After you package your template's artifacts, run the deploy command to deploy the returned template.

```bash
  aws cloudformation deploy --template-file serverless-chat-tmp.yaml --stack-name $PROJECT_NAME --capabilities CAPABILITY_NAMED_IAM --parameter-overrides ProjectName=$PROJECT_NAME Environment=$ENVIRONMENT
```