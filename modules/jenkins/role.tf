resource "aws_iam_role" "role" {
  name               = "${var.name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "JenkinsAssumeRole",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "policy" {
  role       = "${aws_iam_role.role.id}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}
