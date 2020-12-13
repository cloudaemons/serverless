# 02. TERRAFORM

## LAB PURPOSE

Learn to provision infrastructure with HashiCorp Terraform.

## DEFINITIONS
----
### TERRAFORM

Terraform is a tool for building, changing, and versioning infrastructure safely and efficiently. Terraform can manage existing and popular service providers as well as custom in-house solutions.

## STEPS

### INSTALL TERRAFORM

1. Go to **Cloud9** web console.
2. Install **yum-config-manager** to manage your repositories.
```bash
sudo yum install -y yum-utils
```
3. Use **yum-config-manager** to add the official HashiCorp Linux repository.
```bash
 sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
 ```
4. Install Terraform
```bash
sudo yum -y install terraform
```
5. Verify the installation
```bash
terraform -help
```
6. Learn more about the most important subcommand
```bash
terraform -help init
```
```bash
terraform -help plan
```
```bash
terraform -help apply
```
```bash
terraform -help destroy
```