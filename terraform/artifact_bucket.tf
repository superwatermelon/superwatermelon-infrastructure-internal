variable "artifact_bucket" {
  description = "The name of the S3 bucket to host build artifacts"
}

resource "aws_s3_bucket" "artifacts" {
  bucket = "${var.artifact_bucket}"
  acl    = "private"
}
