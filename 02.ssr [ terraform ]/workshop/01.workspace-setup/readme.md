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
5. Select **Create a new instance for environment (EC2)** and pick **t2.small**
6. Select **Amazon Linux 2**
7. Leave all of the environment settings as they are, and go to the **Next step**
8. Click **Create environment**

### DOWNLOAD RESOURCES

Clone the repository to your **Cloud9** environment and start working on code. Run the following command:

```bash
  git clone https://github.com/cloudaemons/serverless/
```

### CREATE BUCKET S3 FOR ARTIFACTS

1. Go to **S3** web console.
2. Click **Create bucket** button
3. Enter DNS-compliant **Bucket name**
4. Choose **Ireland (eu-west-1)** region
5. Leave other settings as default
6. Then click **Create bucket**

### CONFIGURE AWS CREDENTIALS LOCALLY

1. Go to **Cloud9** web console.
2. Click **AWS Cloud9**
3. Go to **Preferences**
4. Go to **AWS Settings**
5. Click **Credentials** 
6. Disable **AWS Managed temporary credenttials**
7. Verify that you have CLI configured properly, to do so run
```bash
aws sts get-caller-identity
```
8. In AWS console go to IAM service, and create user with **AdministratorAccess** policy attached. Download **.csv** file

9. Configure the AWS CLI in the Cloud9 terminal
```bash
aws configure
```
10. Set your admin **AWS Access Key ID** and **AWS Secret Access Key** from the **.csv** file 
11. Set **Default region name** to **eu-west-1**
12. Set **Default output format** to **json**
13. To verify that everything is working run
```bash
aws sts get-caller-identity
```
If you see something similar, you have configured the environment correctly
```json
{
    "Account": "646407006236", 
    "UserId": "AIDAI43XPIK3ZA6O6CMBW", 
    "Arn": "arn:aws:iam::646407006236:user/admin"
}
```
