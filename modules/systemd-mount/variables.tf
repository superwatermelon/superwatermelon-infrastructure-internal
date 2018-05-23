variable "name" {
  description = "The name of the unit"
}

variable "requires" {
  description = "The units that this service requires"
  default     = ""
}

variable "after" {
  description = "The units that this service should be run after"
  default     = ""
}

variable "volume" {
  description = "The volume to mount"
}

variable "mount_point" {
  description = "The logical location to mount the volume"
}

variable "type" {
  description = "The type of filesystem to mount"
  default     = "ext4"
}
