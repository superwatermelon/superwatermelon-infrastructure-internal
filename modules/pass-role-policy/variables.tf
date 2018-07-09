variable "name" {
  description = "The name of the policy"
}

variable "source_role_id" {
  description = "The role to which the policy will be attached"
}

variable "pass_role_arn" {
  description = "The role that will be passed to an instance by the above role"
}
