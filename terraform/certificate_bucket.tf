variable "certificate_bucket" {
  description = "The name of the S3 bucket to host certificates"
}

resource "aws_s3_bucket" "certificates" {
  bucket = "${var.certificate_bucket}"
  acl    = "private"
}
