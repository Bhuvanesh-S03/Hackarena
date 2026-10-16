variable "name" {}
variable "priority" {}
variable "host" {}
variable "image" {}
variable "region" {}
variable "cpu" {}
variable "memory" {}
variable "cluster_arn" {}
variable "vpc_id" {}
variable "subnets" { type = list(string) }
variable "task_sg_id" {}
variable "listener_arn" {}
variable "exec_role_arn" {}
