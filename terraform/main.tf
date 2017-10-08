variable "seed_tfstate_bucket" {
  description = "The seed tfstate S3 bucket"
  type        = "string"
}

terraform {
  backend "s3" {
    key = "terraform.tfstate"
  }
}

data "terraform_remote_state" "seed" {
  backend = "s3"

  config {
    bucket = "${var.seed_tfstate_bucket}"
    key    = "terraform.tfstate"
  }
}
