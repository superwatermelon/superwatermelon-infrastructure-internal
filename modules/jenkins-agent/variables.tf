variable "name" {
  description = "The name to give the Jenkins agent resources"
}

variable "internal_deployment_role_arn" {
  description = "The role to use for internal deployment"
}

variable "internal_ecr_role_arn" {
  description = "The role to use to push internal Docker images"
}

variable "test_deployment_role_arn" {
  description = "The role to use for test deployment"
}

variable "test_ecr_role_arn" {
  description = "The role to use to push test Docker images"
}

variable "stage_deployment_role_arn" {
  description = "The role to use for stage deployment"
}

variable "stage_ecr_role_arn" {
  description = "The role to use to push stage Docker images"
}

variable "live_deployment_role_arn" {
  description = "The role to use for live deployment"
}

variable "live_ecr_role_arn" {
  description = "The role to use to push live Docker images"
}
