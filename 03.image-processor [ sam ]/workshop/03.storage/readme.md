# 03 STORAGE

## LAB PURPOSE

Create a NoSQL database where all images metadata will be stored

## DEFINITIONS
----

### DYNAMODB

Amazon DynamoDB is a fully managed proprietary NoSQL database service that supports key-value and document data structures

## STEPS

### CREATE DYNAMODB TABLE

1. Copy the **infrastructure.yaml** file from the previous lab to this directory.

2. You need to create NoSQL database where all images metadata will be stored. Below you have cloudformation resource which is responsible for that. You need to add this clloudformation resource to your **infrastructure.yaml** file. Please add it to section **Resources**. If you need any help check how the solution should look like. To check what each field represent go to cloudformation documentation **https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-dynamodb-table.html**

  ```yaml
  ImageMetadataDB:
    Type: AWS::DynamoDB::Table
    Properties:
      AttributeDefinitions:
        - AttributeName: id
          AttributeType: S
      KeySchema:
        - AttributeName: id
          KeyType: HASH
      BillingMode: PAY_PER_REQUEST
      StreamSpecification:
        StreamViewType: NEW_AND_OLD_IMAGES
  ```


3. Upload local artifacts that might be required by your template. To do so, use the command listed below. In response, you should see image-processor-tmp.yaml. This is a template after SAM transformation. Open it and familiarize with its structure.

```bash
 aws cloudformation package --template-file infrastructure.yaml --s3-bucket $ARTIFACT_BUCKET --output-template-file image-processor-tmp.yaml
```

4. After you package your template's artifacts, run the deploy command to deploy the returned template.

```bash
  aws cloudformation deploy --template-file image-processor-tmp.yaml --stack-name $PROJECT_NAME --capabilities CAPABILITY_NAMED_IAM --parameter-overrides ProjectName=$PROJECT_NAME Environment=$ENVIRONMENT
```

5. Go to cloudformation console  https://console.aws.amazon.com/cloudformation, find your stack **image-processor**, and verify what resources have been created, to do that, go to section **Resources**. 

6. Go to dynamo db console **https://console.aws.amazon.com/dynamodb**, find your table, and verify what have been created

7. End of the lab. Your first cloudformation stack is ready.
