variable "jenkins_format_volume" {
  description = "Should the Jenkins volume be formatted (use for first launch)"
  default     = false
}

data "template_file" "jenkins_ignition" {
  template = <<EOF
{
  "ignition":{"version":"2.0.0"},
  "passwd":{
    "users":[
      {"name":"jenkins","create":{"uid":1000}}
    ]
  },
  "storage":{
    "files":[
      {"filesystem":"root","path":"/mnt/jenkins/init.groovy.d/aws.groovy","contents":{"source":$${init_aws_groovy}},"mode":420,"user":{"id":1000},"group":{"id":1000}},
      {"filesystem":"root","path":"/mnt/jenkins/init.groovy.d/git.groovy","contents":{"source":$${init_git_groovy}},"mode":420,"user":{"id":1000},"group":{"id":1000}},
      {"filesystem":"root","path":"/mnt/jenkins/init.groovy.d/master.groovy","contents":{"source":$${init_master_groovy}},"mode":420,"user":{"id":1000},"group":{"id":1000}},
      {"filesystem":"root","path":"/mnt/jenkins/init.groovy.d/security.groovy","contents":{"source":$${init_security_groovy}},"mode":420,"user":{"id":1000},"group":{"id":1000}}
    ]
  },
  "systemd":{
    "units":[
      {"name":"docker.socket","enabled":true},
      {"name":"containerd.service","enabled":true},
      {"name":"docker.service","enabled":true},
      {"name":"jenkins.service","enabled":true,"contents":$${jenkins_service_unit}},
      {"name":"home-jenkins.service","enabled":true,"contents":$${jenkins_home_service_unit}},
      {"name":"home-jenkins.mount","enabled":true,"contents":$${jenkins_home_mount_unit}},
      {"name":"jenkins-format.service","enabled":$${jenkins_format_service_enabled},"contents":$${jenkins_format_service}}
    ]
  }
}
EOF
  vars = {
    jenkins_service_unit           = "${jsonencode(data.template_file.jenkins_service_unit.rendered)}"
    jenkins_home_service_unit      = "${jsonencode(data.template_file.jenkins_home_service_unit.rendered)}"
    jenkins_home_mount_unit        = "${jsonencode(data.template_file.jenkins_home_mount_unit.rendered)}"
    jenkins_format_service         = "${jsonencode(data.template_file.jenkins_format_service.rendered)}"
    jenkins_format_service_enabled = "${var.jenkins_format_volume == true}"

    # Jenkins init scripts
    init_aws_groovy                = "${jsonencode("data:text/plain;base64,${base64encode(file("${path.root}/jenkins/init.groovy.d/aws.groovy"))}")}"
    init_git_groovy                = "${jsonencode("data:text/plain;base64,${base64encode(file("${path.root}/jenkins/init.groovy.d/git.groovy"))}")}"
    init_master_groovy             = "${jsonencode("data:text/plain;base64,${base64encode(file("${path.root}/jenkins/init.groovy.d/master.groovy"))}")}"
    init_security_groovy           = "${jsonencode("data:text/plain;base64,${base64encode(file("${path.root}/jenkins/init.groovy.d/security.groovy"))}")}"
  }
}
