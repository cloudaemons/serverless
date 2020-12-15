#!/bin/bash

# Usage:
#  ./deploy.sh param1 param2

# * param1: Project name
# * param2: Name of the bucket for lambda artifacts

# Example:
#  ./deploy.sh image-processor abajowski dev

echo -e '\n## INSTALLING NPM DEPENDENCIES:\n'
npm install --quiet

echo -e '\n## AUDITING PACKAGE DEPENDENCIES FOR SECURITY VULNERABILITIES\n'
npm audit

echo -e '\n## REMOVING DEV DEPENDENCIES\n'
npm prune --production

echo -e '\n## CREATING DIRECTORY FOR TEMPORARY FILES\n'
mkdir ./temp

echo -e '\n## DEPLOYING LAMBDAS TO S3 & PERFORMING CLOUDFORMATION TRANSFORMATION\n'
aws cloudformation package --template-file infrastructure.yaml --s3-bucket $2 --output-template-file temp/chat-tmp.yaml

echo -e '\n## DEPLOYING CLOUDFORMATION SCRIPT\n'
aws cloudformation deploy  --template-file temp/chat.yaml --stack-name $1 --capabilities CAPABILITY_NAMED_IAM --parameter-overrides
