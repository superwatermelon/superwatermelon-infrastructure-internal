variable "docker_registry_volume_device" {
  description = "The device name of the Docker Registry volume"
  default     = "xvdf"
}

variable "docker_registry_format_data" {
  description = "Should the data for the Docker Registry be formatted"
  default     = false
}

variable "docker_registry_instance_type" {
  description = "The AWS instance type to use for the Docker Registry node"
  default     = "t2.nano"
}

variable "docker_registry_key_pair" {
  description = "The name of the key pair to use for the Docker Registry node"
}
