provider "aws" {
    region = "us-east-1"
}


terraform {
  backend "s3" {
    bucket         = "pythonwebapptfstate"
    key            = "myapp/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "my-lock-table"
  }
}

resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "az1" {
  availability_zone = "us-east-1a"
}

resource "random_password" "mysql_password" {
  length  = 16
  special = false
}

resource "random_string" "mysql_username" {
  length = 8
  special = false
}


locals {
  db_username = "a${random_string.mysql_username.result}"
}


resource "aws_ssm_parameter" "mysql_username" {
  name  = "/myapp/db/username"
  type  = "SecureString"
  value = "${local.db_username}"
}

resource "aws_ssm_parameter" "mysql_password" {
  name  = "/myapp/db/password"
  type  = "SecureString"
  value = random_password.mysql_password.result
}

resource "aws_ssm_parameter" "mysql_endpoint" {
  name  = "/myapp/db/endpoint"
  type  = "SecureString"
  value = aws_db_instance.mysql.endpoint
}


resource "aws_security_group" "app" {
  name_prefix = "app-"
  ingress {
    from_port = 5000  
    to_port = 5000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "mysql" {
  name_prefix = "mysql-"
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    #security_groups = [aws_security_group.app.id]
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "mysql" {
  identifier = "my-mysql-db"
  name = "mydb"
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t2.micro"
  allocated_storage = 10
  storage_type = "gp2"
  username = aws_ssm_parameter.mysql_username.value
  password = aws_ssm_parameter.mysql_password.value
  vpc_security_group_ids = [aws_security_group.mysql.id]
  skip_final_snapshot       = true
}

module "app_ecs_cluster" {
  source = "trussworks/ecs-cluster/aws"

  name        = var.app_ecs_cluster_name
  environment = var.app_ecs_cluster_environment_name

  image_id      = data.aws_ami.ecs_ami.image_id
  instance_type = var.app_ecs_cluster_instance_type

  vpc_id           = aws_default_vpc.default.id
  subnet_ids       = [aws_default_subnet.az1.id]
  desired_capacity = 1
  max_size         = 1
  min_size         = 1
  security_group_ids = [aws_security_group.app.id]
}

resource "aws_ecs_task_definition" "task" {
  family                   = "myapp"
  container_definitions    = <<DEFINITION
  [
    {
      "name": "example-container",
      "image": "${var.container_image}",
      "memory": 512,
      "cpu": 256,
      "portMappings": [
        {
          "containerPort": 5000,
          "hostPort": 80,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "DB_USERNAME",
          "value": "${aws_ssm_parameter.mysql_username.value}"
        },
        {
          "name": "DB_PASSWoRD",
          "value": "${aws_ssm_parameter.mysql_password.value}"
        },
        {
          "name": "DB_ENDPOINT",
          "value": "${aws_db_instance.mysql.endpoint}"
        }
      ]
    }
  ]
  DEFINITION
}

module "ecs-service" {
  source  = "mergermarket/load-balanced-ecs-service-no-target-group/acuris"
  version = "2.2.4"
  
  name = "pythonapp"
  task_definition = aws_ecs_task_definition.task.arn
  cluster = module.app_ecs_cluster.ecs_cluster_name
  container_name = "pythonapp"
  container_port = 5000
  desired_count = "1"
}
