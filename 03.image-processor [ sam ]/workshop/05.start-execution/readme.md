# 05 START EXECUTION

## LAB PURPOSE

Start execution of Step Function when the image is uploaded to S3 Bucket

## DEFINITIONS
----

### AWS LAMBDA

AWS Lambda lets you run code without provisioning or managing servers. You pay only for the compute time you consume - there is no charge when your code is not running.

### AMAZON S3 EVENT NOTIFICATION

The Amazon S3 notification feature enables you to receive notifications when certain events happen in your bucket

## STEPS

### CREATE LAMBDA FUNCTION

1. To run your state machine you need to have a lambda which will be triggered by S3 event notification

2. The code of the lambda is prepared for you. Go to **./src/functions/start-execution.js** file and analyze it. This is a function which takes as an input event from s3 bucket and runs the state machine

3. What you have to do right now, is to create a clouformation resource for your lambda. To do so copy first the **infrastructure.yaml** file from the previous lab to this directory. Then add resource listed below


```yaml
StartExecutionFunction:
  Type: AWS::Serverless::Function
  Properties:
    Handler: ./src/functions/start-execution.handler
    Environment:
      Variables:
        STATE_MACHINE_ARN: !Ref StateMachine

    Policies:
      - Version: 2012-10-17
        Statement:
          - Effect: Allow
            Action:
              - s3:Get*
              - s3:List*
            Resource: '*'
      - Version: 2012-10-17
        Statement:
          - Effect: Allow
            Action:
              - states:DescribeExecution
              - states:GetExecutionHistory
              - states:ListExecutions
              - states:StartExecution
              - states:StopExecution
            Resource:
              - !Ref StateMachine
```

4. Before you will deploy lambda do the cloud, you have to install all dependencies. To do run:

```bash
 npm install
```

5. Deploy your lambda to the cloud

```bash
 aws cloudformation package --template-file infrastructure.yaml --s3-bucket $ARTIFACT_BUCKET --output-template-file image-processor-tmp.yaml
```

```bash
  aws cloudformation deploy --template-file image-processor-tmp.yaml --stack-name $PROJECT_NAME --capabilities CAPABILITY_NAMED_IAM --parameter-overrides ProjectName=$PROJECT_NAME Environment=$ENVIRONMENT
```

6. Go to **http://console.aws.amazon.com/lambda **, find your function, open it, and click test it. As an **Event template** choose **Amazon S3 PUT**

7. Go to **http://console.aws.amazon.com/states** and verify if your state machine was run

8. Now is time to add a trigger to your function, which will be invoking lambda whenever the image will be uploaded to S3 bucket. The event you can create by adding to your function:
```yaml
  Events:
    BucketImageProcessorS3Bucket:
      Type: S3
      Properties:
        Bucket: !Ref ImageProcessorS3Bucket
        Events: s3:ObjectCreated:*
```


7. Your lambda should look like code listed bellow

```yaml
StartExecutionFunction:
  Type: AWS::Serverless::Function
  Properties:
    Handler: ./src/functions/start-execution.handler
    Environment:
      Variables:
        STATE_MACHINE_ARN: !Ref StateMachine

    Policies:
      - Version: 2012-10-17
        Statement:
          - Effect: Allow
            Action:
              - s3:Get*
              - s3:List*
            Resource: '*'
      - Version: 2012-10-17
        Statement:
          - Effect: Allow
            Action:
              - states:DescribeExecution
              - states:GetExecutionHistory
              - states:ListExecutions
              - states:StartExecution
              - states:StopExecution
            Resource:
              - !Ref StateMachine
    Events:
      BucketImageProcessorS3Bucket:
        Type: S3
        Properties:
          Bucket: !Ref ImageProcessorS3Bucket
          Events: s3:ObjectCreated:*
```

8. Deploy your code once again

```bash
 aws cloudformation package --template-file infrastructure.yaml --s3-bucket $ARTIFACT_BUCKET --output-template-file image-processor-tmp.yaml
```

```bash
 aws cloudformation deploy --template-file image-processor-tmp.yaml --stack-name $PROJECT_NAME --capabilities CAPABILITY_NAMED_IAM --parameter-overrides ProjectName=$PROJECT_NAME Environment=$ENVIRONMENT
```

9. Go to S3 bucket, upload image, and verify if state machine has started