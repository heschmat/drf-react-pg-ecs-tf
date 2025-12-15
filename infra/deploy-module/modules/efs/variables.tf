variable "prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ecs_task_sg_id" {
  type = string
}

variable "private_subnet_ids" {
  type = map(string)
}
