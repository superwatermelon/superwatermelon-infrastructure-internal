variable "name" {
  description = "The name of the unit"
}

variable "enabled" {
  description = "Should the unit be enabled?"
  default     = false
}

variable "volume" {
  description = "The volume to partition and format"
}
