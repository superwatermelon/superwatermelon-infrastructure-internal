terraform {
  required_version = ">= 0.9.0"
}

module "internal_deployment" {
  source          = "../assume-role-policy"
  name            = "${var.name}-internal-deployment"
  source_role_id  = "${aws_iam_role.role.id}"
  assume_role_arn = "${var.internal_deployment_role_arn}"
}

module "internal_ecr" {
  source          = "../assume-role-policy"
  name            = "${var.name}-internal-docker-registry"
  source_role_id  = "${aws_iam_role.role.id}"
  assume_role_arn = "${var.internal_ecr_role_arn}"
}

module "test_deployment" {
  source          = "../assume-role-policy"
  name            = "${var.name}-test-deployment"
  source_role_id  = "${aws_iam_role.role.id}"
  assume_role_arn = "${var.test_deployment_role_arn}"
}

module "test_ecr" {
  source          = "../assume-role-policy"
  name            = "${var.name}-test-docker-registry"
  source_role_id  = "${aws_iam_role.role.id}"
  assume_role_arn = "${var.test_ecr_role_arn}"
}

module "stage_deployment" {
  source          = "../assume-role-policy"
  name            = "${var.name}-stage-deployment"
  source_role_id  = "${aws_iam_role.role.id}"
  assume_role_arn = "${var.stage_deployment_role_arn}"
}

module "stage_ecr" {
  source          = "../assume-role-policy"
  name            = "${var.name}-stage-docker-registry"
  source_role_id  = "${aws_iam_role.role.id}"
  assume_role_arn = "${var.stage_ecr_role_arn}"
}

module "live_deployment" {
  source          = "../assume-role-policy"
  name            = "${var.name}-live-deployment"
  source_role_id  = "${aws_iam_role.role.id}"
  assume_role_arn = "${var.live_deployment_role_arn}"
}

module "live_ecr" {
  source          = "../assume-role-policy"
  name            = "${var.name}-live-docker-registry"
  source_role_id  = "${aws_iam_role.role.id}"
  assume_role_arn = "${var.live_ecr_role_arn}"
}
