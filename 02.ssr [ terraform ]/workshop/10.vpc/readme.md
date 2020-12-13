# 10. VPC

## LAB PURPOSE

Create VPC

## DEFINITIONS
----
### VPC

VPC is a logically isolated section of the AWS Cloud where you can launch AWS resources in a virtual network that you define.

### Subnet

A part of VPC with specified IP addresses.

### Route Table

A Route table contains a set of rules, called routes, that are used to determine where network traffic is directed.

### Route

Specifies a route in a Route table within a VPC.

### Internet Gateway

Internet Gateway is a VPC component that allows communication between instances in your VPC and the internet

### Nat Gateway

Enable instances in a private subnet to connect to the internet or other AWS services, but prevent the internet from initiating a connection with those instances.

### Elastic IP

IP address associated with your AWS account which could be easily assigned to any instance in your account.

## STEPS

### CREATE VPC


1. Inside **modules**  directory create **vpc** directory

2. Inside **vpc** directory create three files **vpc.tf** and **variables.tf** and **outputs.tf**

3. Define variables for the the cdn module in the **variables.tf** file

```terraform
variable "application" {
  type        = string
  description = "Application name"
}

variable "environment" {
  type        = string
  description = "Environment (e.g. `prod`, `dev`, `staging`)"
  default     = "dev"
}

variable "region" {
  type        = string
  description = "Region where vpc should be deployed"
  default     = "eu-central-1"
}

variable "vpc_cidr_block" {
  type        = string
  description = "Network cidr block"
  default     = "10.0.0.0/16"
}

variable "subnet_private_one_cidr_block" {
  type        = string
  description = "Private subnet 1 - cidr block"
  default     = "10.0.0.0/24"
}

variable "subnet_private_two_cidr_block" {
  type        = string
  description = "Private subnet 2 - cidr block"
  default     = "10.0.1.0/24"
}

variable "subnet_public_one_cidr_block" {
  type        = string
  description = "Public subnet 1 - cidr block"
  default     = "10.0.2.0/24"
}

variable "subnet_public_two_cidr_block" {
  type        = string
  description = "Public subnet 2 - cidr block"
  default     = "10.0.3.0/24"
}

variable "logs_retention_in_days" {
  type        = number
  description = "VPC flow logs retention period"
  default     = 14
}
```

4. In the **vpc.tf** add all resources required to build a VPC: private subnets, public subnets, internet gateway, nat gatewys

```terraform
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-${var.environment}-${var.application}"
  }
}

resource "aws_subnet" "subnet_private_one" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_private_one_cidr_block
  availability_zone = data.aws_availability_zones.az.names[0]

  tags = {
    Name = "subnet-priv-one-${var.environment}-${var.application}"
  }
}

resource "aws_subnet" "subnet_private_two" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_private_two_cidr_block
  availability_zone = data.aws_availability_zones.az.names[1]

  tags = {
    Name = "subnet-priv-two-${var.environment}-${var.application}"
  }
}

resource "aws_subnet" "subnet_public_one" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_public_one_cidr_block
  availability_zone = data.aws_availability_zones.az.names[0]

  tags = {
    Name = "subnet-public-one-${var.environment}-${var.application}"
  }
}

resource "aws_subnet" "subnet_public_two" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_public_two_cidr_block
  availability_zone = data.aws_availability_zones.az.names[1]

  tags = {
    Name = "subnet-public-two-${var.environment}-${var.application}"
  }
}

data "aws_availability_zones" "az" {
  state = "available"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "igw-${var.environment}-${var.application}"
  }
}

resource "aws_eip" "nat_one" {
  vpc = true
}

resource "aws_eip" "nat_two" {
  vpc = true
}

resource "aws_route_table" "rt_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "rt-public-${var.environment}-${var.application}"
  }
}

resource "aws_nat_gateway" "nat_one" {
  allocation_id = aws_eip.nat_one.id
  subnet_id     = aws_subnet.subnet_public_one.id

  tags = {
    Name = "nat-one-${var.environment}-${var.application}"
  }
}

resource "aws_nat_gateway" "nat_two" {
  allocation_id = aws_eip.nat_two.id
  subnet_id     = aws_subnet.subnet_public_two.id

  tags = {
    Name = "nat-two-${var.environment}-${var.application}"
  }
}

resource "aws_route_table" "rt_private_one" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_one.id
  }

  tags = {
    Name = "rt-private-one-${var.environment}-${var.application}"
  }
}

resource "aws_route_table" "rt_private_two" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_two.id
  }

  tags = {
    Name = "rt-private-two-${var.environment}-${var.application}"
  }
}

resource "aws_route_table_association" "public_assoc_one" {
  subnet_id      = aws_subnet.subnet_public_one.id
  route_table_id = aws_route_table.rt_public.id
}

resource "aws_route_table_association" "public_assoc_two" {
  subnet_id      = aws_subnet.subnet_public_two.id
  route_table_id = aws_route_table.rt_public.id
}

resource "aws_route_table_association" "private_assoc_one" {
  subnet_id      = aws_subnet.subnet_private_one.id
  route_table_id = aws_route_table.rt_private_one.id
}

resource "aws_route_table_association" "private_assoc_two" {
  subnet_id      = aws_subnet.subnet_private_two.id
  route_table_id = aws_route_table.rt_private_two.id
}
```

5. Create default security group, to do so create **sg.tf** file and add following resource

```terraform
resource "aws_security_group" "sg" {
  name   = "task-sg-${var.environment}-${var.application}"
  vpc_id = aws_vpc.vpc.id

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

6. In the file **outputs.tt** add

```terraform

output "sg_id" {
  description = "Security groups"
  value       = aws_security_group.sg.id
}

output "vpc_id" {
  description = "VPC id"
  value       = aws_vpc.vpc.id
}

output "vpc_cidr" {
  description = "VPC cidr block"
  value       = var.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value = [
    aws_subnet.subnet_private_one.id,
    aws_subnet.subnet_private_two.id
  ]
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value = [
    aws_subnet.subnet_public_one.id,
    aws_subnet.subnet_public_two.id
  ]
}

output "nat_ips" {
  description = "NAT IPs"
  value = [
    "${aws_eip.nat_one.public_ip}/32",
    "${aws_eip.nat_two.public_ip}/32",
  ]
}

```

7. Go to **main.tf** file in **ssr** directory and create module **vpc**

```terraform
module "vpc" {
  source      = "./modules/vpc"
  environment = local.environment
  application = var.application
  region      = var.aws_region
}
```

8. Go to **ssr** directory and deploy the infrastructure

```terraforrm
terraform init
```

```terraforrm
terraform plan
```

```terraforrm
terraform apply
```

9. Go to AWS console and verify if VPC is created
