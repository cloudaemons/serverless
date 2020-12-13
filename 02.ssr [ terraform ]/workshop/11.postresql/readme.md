# 11. POSTGRESQL

## LAB PURPOSE

Creae PostgreSQL dattabase

## DEFINITIONS
----

### AURORA SERVERLESS

Amazon Aurora Serverless is an on-demand, auto-scaling configuration for Amazon Aurora. It automatically starts up, shuts down, and scales capacity up or down based on your application's needs. It enables you to run your database in the cloud without managing any database capacity.

## STEPS

### CREATE AURORA

1. Inside **modules**  directory create **aurora** directory

2. Inside **aurora** directory create four files **main.tf** and **variables.tf** and **outputs.tf** and **sg.tf**

3. Define variables for the the cdn module in the **variables.tf** file

```terraform
variable "application" {
  description = "Application name"
}

variable "environment" {
  description = "Environment (e.g. `prod`, `dev`, `staging`)"
}

variable "backup_retention_period" {
  type    = number
  default = 7
}

variable "preferred_backup_window" {
  default = "02:00-05:00"
}

variable "preferred_maintenance_window" {
  default = "sun:01:00-sun:01:30"
}

variable "scaling_min_capacity" {
  type    = number
  default = 2
}

variable "scaling_max_capacity" {
  type    = number
  default = 4
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Whether to skip a final database snapshot"
}

variable "sg_id" {
  description = "SG ID to be assigned to a database cluster"
}

variable "db_subnet_ids" {
  type        = list(string)
  description = "List of VPC subnets ids for placing database cluster"
}

variable "vpc_id" {
  type =  string
  description = "VPC ID"
}
```

4. Define security groups for db, in the file **sg.tf** add 

```terraform
resource "aws_security_group" "db" {
  name   = "db-sg-${var.environment}-${var.application}"
  vpc_id = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 5432
    to_port         = 5432
    security_groups = [var.sg_id]
  }

  egress {
    protocol        = "tcp"
    from_port       = 5432
    to_port         = 5432
    security_groups = [var.sg_id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

5. In the **main.tf** file get all availability zones

```terraform
data "aws_availability_zones" "available" {
  all_availability_zones = true

  exclude_names = ["eu-west-1c"]
}
```

6. In the same file generate random users and passwords, for db and save it in ssm

```terraform
resource "random_string" "db_name" {
  special   = false
  number    = false
  length    = 20
  min_upper = 4
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/${var.environment}/${var.application}/aurora/db_name"
  type  = "String"
  value = random_string.db_name.result
}

resource "random_string" "db_master_user" {
  special   = false
  number    = false
  length    = 24
  min_upper = 4
}

resource "aws_ssm_parameter" "db_master_user" {
  name  = "/${var.environment}/${var.application}/aurora/db_master_user"
  type  = "String"
  value = random_string.db_master_user.result
}

resource "random_password" "db_master_password" {
  special     = false
  length      = 32
  min_numeric = 4
  min_upper   = 4
}

resource "aws_ssm_parameter" "db_master_password" {
  name  = "/${var.environment}/${var.application}/aurora/db_master_password"
  type  = "SecureString"
  value = random_password.db_master_password.result
}

resource "random_string" "final_snapshot_suffix" {
  special = false
  length  = 8
}
```

7. Create subnets group which points where to locate db

```terraform
resource "aws_db_subnet_group" "db" {
  subnet_ids = var.db_subnet_ids
}
```

8. Create rds cluster 

```terraform
resource "aws_rds_cluster" "db" {
  cluster_identifier           = "${var.environment}-${var.application}"
  engine_mode                  = "serverless"
  engine                       = "aurora-postgresql"
  engine_version               = "10.7"
  availability_zones           = data.aws_availability_zones.available.names
  database_name                = random_string.db_name.result
  master_username              = random_string.db_master_user.result
  master_password              = random_password.db_master_password.result
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window
  skip_final_snapshot          = var.skip_final_snapshot
  final_snapshot_identifier    = "${var.environment}-${var.application}-${random_string.final_snapshot_suffix.result}"
  storage_encrypted            = true
  vpc_security_group_ids       = [aws_security_group.db.id]
  db_subnet_group_name         = aws_db_subnet_group.db.name

  scaling_configuration {
    auto_pause               = false
    min_capacity             = var.scaling_min_capacity
    max_capacity             = var.scaling_max_capacity
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }

  lifecycle {
    ignore_changes  = [availability_zones, engine_version]
    prevent_destroy = true
  }
}
```

9. Add outputs to **outputs.tf** file 

```terraform
output "db_name_ssm_parameter_arn" {
  description = "DB name SSM parameter ARN"
  value       = aws_ssm_parameter.db_name.arn
}

output "db_user_ssm_parameter_arn" {
  description = "DB user SSM parameter ARN"
  value       = aws_ssm_parameter.db_master_user.arn
}

output "db_password_ssm_parameter_arn" {
  description = "DB password SSM parameter ARN"
  value       = aws_ssm_parameter.db_master_password.arn
}

output "db_host" {
  description = "DB host"
  value       = aws_rds_cluster.db.endpoint
}

output "db_cluster_identifier" {
  description = "DB host"
  value       = aws_rds_cluster.db.cluster_identifier
}

```

10. Go to **main.tf** file in **ssr** directory and create module **postgresql**

```terraform
module "postgresql" {
  source = "./modules/aurora"

  application          = var.application
  environment          = local.environment
  skip_final_snapshot  = true
  vpc_id               = module.vpc.vpc_id
  sg_id                = module.vpc.sg_id
  db_subnet_ids        = module.vpc.private_subnet_ids
}
```


11. Go to **ssr** directory and deploy the infrastructure

```terraforrm
terraform init
```

```terraforrm
terraform plan
```

```terraforrm
terraform apply
```

12. Go to AWS console and verify if aurora is created

13. Go to AWS SSM and verify password and username for DB
