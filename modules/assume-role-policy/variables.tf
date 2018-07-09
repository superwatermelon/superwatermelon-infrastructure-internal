variable "name" {
  description = "The name of the policy"
}

variable "source_role_id" {
  description = "The role to which the policy will be applied"
}

variable "assume_role_arn" {
  description = "The role to assume"
}
