data "ignition_user" "jenkins" {
  name = "jenkins"
  uid  = "1000"
}

data "ignition_file" "environment" {
  filesystem = "root"
  path       = "/mnt/jenkins/environment"

  content {
    content = "${var.environment}"
  }
}

data "ignition_file" "jenkins_init_aws" {
  filesystem = "root"
  path       = "/mnt/jenkins/init.groovy.d/aws.groovy"

  content {
    content = "${file("${path.root}/jenkins/init.groovy.d/aws.groovy")}"
  }
}

data "ignition_file" "jenkins_init_git" {
  filesystem = "root"
  path       = "/mnt/jenkins/init.groovy.d/git.groovy"

  content {
    content = "${file("${path.root}/jenkins/init.groovy.d/git.groovy")}"
  }
}

data "ignition_file" "jenkins_init_master" {
  filesystem = "root"
  path       = "/mnt/jenkins/init.groovy.d/master.groovy"

  content {
    content = "${file("${path.root}/jenkins/init.groovy.d/master.groovy")}"
  }
}

data "ignition_file" "jenkins_init_security" {
  filesystem = "root"
  path       = "/mnt/jenkins/init.groovy.d/security.groovy"

  content {
    content = "${file("${path.root}/jenkins/init.groovy.d/security.groovy")}"
  }
}

module "jenkins_format_unit" {
  source  = "../systemd-format"
  name    = "jenkins-format.service"
  enabled = "${var.format}"
  volume  = "${var.volume}"
}

module "jenkins_mount_unit" {
  source      = "../systemd-mount"
  name        = "home-jenkins.mount"
  after       = "jenkins-format.service"
  volume      = "${var.volume}1"
  mount_point = "/home/jenkins"
}

module "jenkins_home_service_unit" {
  source      = "../systemd-jenkins-home"
  name        = "home-jenkins.service"
}

module "jenkins_service_unit" {
  source      = "../systemd-jenkins"
  name        = "jenkins.service"
  env_file    = "/mnt/jenkins/environment"
}

data "ignition_config" "ignition" {
  users = [
    "${data.ignition_user.jenkins.id}"
  ]
  files = [
    "${data.ignition_file.jenkins_init_aws.id}",
    "${data.ignition_file.jenkins_init_git.id}",
    "${data.ignition_file.jenkins_init_master.id}",
    "${data.ignition_file.jenkins_init_security.id}"
  ]
  systemd = [
    "${module.jenkins_format_unit.id}",
    "${module.jenkins_mount_unit.id}",
    "${module.jenkins_home_service_unit.id}",
    "${module.jenkins_service_unit.id}"
  ]
}
