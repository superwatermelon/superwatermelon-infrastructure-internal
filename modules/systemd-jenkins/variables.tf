variable "name" {
  description = "The name of the systemd unit"
}

variable "env_file" {
  description = "The path of the environment file"
}

variable "container_name" {
  description = "The name to give the container"
  default     = "jenkins"
}

variable "docker_image" {
  description = "The Docker image to use for Jenkins"
  default     = "superwatermelon/jenkins:v2.131.0"
}

variable "mount_point" {
  description = "The mount point for Jenkins home"
  default     = "/home/jenkins"
}
