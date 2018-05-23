variable "name" {
  description = "The name to give resources"
}

variable "availability_zone" {
  description = "The availability zone in which to place Jenkins"
}

variable "subnet_id" {
  description = "The subnet in which to place Jenkins"
}

variable "key_name" {
  description = "The name of the key pair to use"
}

variable "jenkins_agent_role_arn" {
  description = "The role of the Jenkins agent"
}

variable "vpc_security_group_ids" {
  description = "The security groups to give the Jenkins instance"
  default     = []
}

variable "instance_type" {
  description = "The AWS instance type to use for the instance"
  default     = "t2.micro"
}

variable "volume_size" {
  description = "The size of the volume in GB"
  default     = 10
}

variable "volume" {
  description = "The device name of the block storage volume"
  default     = "xvdf"
}

variable "environment" {
  description = "The environment settings for Jenkins"
  default     = ""
}

variable "format" {
  description = "Should the Jenkins volume be formatted?"
  default     = false
}
