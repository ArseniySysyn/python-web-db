variable "app_ecs_cluster_name" {
  default = "app"
}

variable "app_ecs_cluster_environment_name" {
  default = "dev"
}

variable "app_ecs_cluster_instance_type" {
  default = "t2.micro"
}

variable "container_image" {
  description = "The container image to use for the ECS task definition"
  type        = string
}