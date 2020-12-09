# 01. WORKSPACE PREPARATION

## LAB PURPOSE

Create developer tools for the workshop

## DEFINITIONS
----
### CLOUD9

AWS Cloud9 is a cloud-based integrated development environment (IDE) that lets you write, run, and debug your code with just a browser. It includes a code editor, debugger, and terminal.

## STEPS

### CLOUD9 SETUP

1. Go to **Cloud9** web console.
2. At the top right corner of the console, make sure you’re using **Ireland (eu-west-1)** region.
3. Select **Create environment**
4. Name it **Workshop**, and go to the **Next step**
5. Select **Create a new instance for environment (EC2)** and pick **t3.small**
6. Select **Amazon Linux 2**
7. Leave all of the environment settings as they are, and go to the **Next step**
8. Click **Create environment**

### DOWNLOAD RESOURCES

Clone the repository to your **Cloud9** environment and start working on code. Run the following command:

```bash
  git clone https://github.com/cloudaemons/serverless
```

### INSTALL & UPDATE RESOURCES

1. Install the AWS Amplify CLI
```bash
npm install -g @aws-amplify/cli@4.37.1
```
2. Install jq
```bash
sudo yum install jq -y
```