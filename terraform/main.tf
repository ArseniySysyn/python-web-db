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

resource "random_password" "mysql_password" {
  length  = 16
  special = true
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
  value = random_string.mysql_username.result
}

resource "aws_ssm_parameter" "mysql_password" {
  name  = "/myapp/db/password"
  type  = "SecureString"
  value = "${local.db_username}"
}

resource "aws_ssm_parameter" "mysql_endpoint" {
  name  = "/myapp/db/endpoint"
  type  = "SecureString"
  value = aws_db_instance.mysql.endpoint
}

resource "aws_security_group" "mysql" {
  name_prefix = "mysql-"
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = ["sg-07996073df3da55a7"]
  }
}

resource "aws_db_instance" "mysql" {
  identifier = "my-mysql-db"
  db_name = "mydb"
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

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "myapp-cluster"
}

resource "aws_ecs_task_definition" "task" {
  family                   = "myapp"
  container_definitions    = <<DEFINITION
  [
    {
      "name": "example-container",
      "image": "<YOUR-CONTAINER-IMAGE>",
      "memory": 512,
      "cpu": 256,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "ENV_VAR_1",
          "value": "VALUE_1"
        },
        {
          "name": "ENV_VAR_2",
          "value": "VALUE_2"
        }
      ],
      "secrets": [
        {
          "name": "DB_PASSWORD",
          "valueFrom": "<SECRET-ARN>"
        }
      ]
    }
  ]
  DEFINITION
}

resource "aws_ecs_service" "example_service" {
  name            = "example-service"
  cluster         = aws_ecs_cluster.example_cluster.id
  task_definition = aws_ecs_task_definition.example_task.arn
}