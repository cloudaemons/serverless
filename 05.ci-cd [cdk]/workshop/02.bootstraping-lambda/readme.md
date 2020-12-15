# 01. Bootstraping

## LAB PURPOSE

Create CDK based project with simple lambda stack.

# 02. Boostraping project

1. Create project directory:
    ```bash
    mkdir pipeline && cd pipeline
    ```
2. Init project:
    ```bash
    cdk init app --language=typescript
    ```
    
    Select `app`

3. Adjust credentials file
    Modify `~/.aws/credentials` to rename the profile to cdk
    `vi ~/aws/credentials`
    `i`

4. Bootstrap the project, replace your account number in the string below. 

    Run `aws sts get-caller-identity` to get the account number.
    
    ```bash
    cdk bootstrap aws://365033952998/eu-west-1
    ```

5. Modify package.json by copying provided `package.json`.

6. Create infrastructure code

    1. Create `lambda-stack.ts` in lib directory.
    2. Copy `lambda-stack.ts` contents into the created file.

    3. Run `npm install`.

    4. Create src directory.
    5. Copy src contents to the created location.

    6. If not exist create bin/lambda.ts file and fill with:
        
        ```
        #!/usr/bin/env node
        import 'source-map-support/register';
        import * as cdk from '@aws-cdk/core';
        import { LambdaStack } from '../lib/lambda-stack';
        
        const app = new cdk.App();
        new LambdaStack(app, 'LambdaStack',{
            functionName: 'LambdaExample'
        });
        
        ```
7. Deploy infrastructure with:
    ```bash
    run aws cdk deploy --all --profile cdk
    ```
    Confirm with `y`

8. Test rest endpoint from terminal output.

