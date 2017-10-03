resource "aws_iam_role_policy" "jenkins_launch_agent_policy" {
  name   = "jenkins-launch-agent"
  role   = "${aws_iam_role.jenkins_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "${aws_iam_role.jenkins_agent_role.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "jenkins_agent_profile" {
  name  = "jenkins-agent"
  role  = "${aws_iam_role.jenkins_agent_role.name}"
}

resource "aws_iam_role" "jenkins_agent_role" {
  name               = "jenkins-agent"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "JenkinsAgentAssumeRole",
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

resource "aws_iam_role_policy" "jenkins_agent_test_deployment_policy" {
  name   = "jenkins-agent-test-deployment"
  role   = "${aws_iam_role.jenkins_agent_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "${var.test_iam_role}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "jenkins_agent_stage_deployment_policy" {
  name   = "jenkins-agent-stage-deployment"
  role   = "${aws_iam_role.jenkins_agent_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "${var.stage_iam_role}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "jenkins_agent_live_deployment_policy" {
  name   = "jenkins-agent-live-deployment"
  role   = "${aws_iam_role.jenkins_agent_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "${var.live_iam_role}"
    }
  ]
}
EOF
}
