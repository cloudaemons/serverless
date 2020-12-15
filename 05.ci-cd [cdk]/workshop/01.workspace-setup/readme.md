# 01. WORKSPACE PREPARATION

## LAB PURPOSE

Create developer tools for the workshop

## DEFINITIONS
----
### CLOUD9

AWS Cloud9 is a cloud-based integrated development environment (IDE) that lets you write, run, and debug your code with just a browser. It includes a code editor, debugger, and terminal.

### AWS CDK

The AWS Cloud Development Kit (AWS CDK) is an open source software development framework to define your cloud application resources using familiar programming languages.

## STEPS

### CLOUD9 SETUP

1. Go to **Cloud9** web console.
2. At the top right corner of the console, make sure you’re using **Ireland (eu-west-1)** region.
3. Select **Create environment**
4. Name it **Workshop**, and go to the **Next step**
5. Select **Create a new instance for environment (EC2)** and pick **t2.small**
6. Select **Amazon Linux 2**
7. Leave all of the environment settings as they are, and go to the **Next step**
8. Click **Create environment**

### DOWNLOAD RESOURCES

Clone the repository to your **Cloud9** environment and start working on code. Run the following command:

```bash
  git clone https://github.com/cloudaemons/serverless
```

### Install CDK and TypeScript

1. Install TypeScript with:
```bash
    npm -g install typescript
```
2. Verify CDK is present in the environment:
```bash
    cdk --version
```
3. Verify CDK is correctly installed with:
```bash
    cdk --version
```
