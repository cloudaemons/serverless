# 01. CLOUDFORMATION

## LAB PURPOSE

Create a cloudformation stack.

## DEFINITIONS
----

### Cloudformatiom

AWS CloudFormation allows you to use programming languages or a simple text file to model and provision, in an automated and secure manner, all the resources needed for your applications across all regions and accounts. This gives you a single source of truth for your AWS and third party resources.
 
### Serlverless Application Model

The AWS Serverless Application Model (SAM) is an open-source framework for building serverless applications. It provides shorthand syntax to express functions, APIs, databases, and event source mappings. With just a few lines per resource, you can define the application you want and model it using YAML. During deployment, SAM transforms and expands the SAM syntax into AWS CloudFormation syntax, enabling you to build serverless applications faster.

## STEPS


## DEPLOY SERVERLESS APPLICATION MODEL

1. Open **infrastructure.yaml** file and familiarize with its structure. It is a simple cloudformation template that will be used for an S3 bucket creation. This bucket will be used later on for processing images. 

2. Set up the following environment variables

```bash
 export ARTIFACT_BUCKET=name-of-the-bucket-from-previous-excercise
 export ENVIRONMENT=dev
 export PROJECT_NAME=image-processor
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

6. End of the lab. Your first cloudformation stack is ready.