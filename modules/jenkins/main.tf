terraform {
  required_version = ">= 0.9.0"
}

module "coreos" {
  source = "../coreos"
}

module "launch_agent_policy" {
  source         = "../pass-role-policy"
  name           = "${var.name}-launch-agent"
  source_role_id = "${aws_iam_role.role.id}"
  pass_role_arn  = "${var.jenkins_agent_role_arn}"
}
