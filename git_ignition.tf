variable "git_format_volume" {
  description = "Should the Git volume be formatted (use for first launch)"
  default     = false
}

#
# Addition of users is mainly due to security paranoia, to
# prevent accidentally opening a vulnerability due to some
# misconfiguration.
#
# https://docs.docker.com/engine/security/security/#other-kernel-security-features
# > Docker containers are, by default, quite secure; especially
# > if you take care of running your processes inside the
# > containers as non-privileged users (i.e., non-root).
#
# The users on the host shadow the users in the containers
# to prevent accidental overlap of uids between the host
# and container which could expose accidental vulnerabilities.
#

data "template_file" "git_ignition" {
  template = <<EOF
{
  "ignition":{"version":"2.1.0"},
  "passwd":{
    "users":[
      {"name":"git","create":{"uid":1001}}
    ]
  },
  "systemd":{
    "units":[
      {"name":"docker.socket","enabled":true},
      {"name":"containerd.service","enabled":true},
      {"name":"docker.service","enabled":true},
      {"name":"git.service","enabled":true,"contents":$${git_service_unit}},
      {"name":"gitlist-nginx.service","enabled":true,"contents":$${gitlist_nginx_service_unit}},
      {"name":"gitlist-php-fpm.service","enabled":true,"contents":$${gitlist_php_fpm_service_unit}},
      {"name":"sshd.socket","enabled":true,"contents":$${git_sshd_socket_unit}},
      {"name":"home-git.service","enabled":true,"contents":$${git_home_service_unit}},
      {"name":"home-git.mount","enabled":true,"contents":$${git_home_mount_unit}},
      {"name":"git-format.service","enabled":$${git_format_service_enabled},"contents":$${git_format_service}}
    ]
  }
}
EOF
  vars = {
    git_service_unit             = "${jsonencode(data.template_file.git_service_unit.rendered)}"
    gitlist_nginx_service_unit   = "${jsonencode(data.template_file.gitlist_nginx_service_unit.rendered)}"
    gitlist_php_fpm_service_unit = "${jsonencode(data.template_file.gitlist_php_fpm_service_unit.rendered)}"
    git_sshd_socket_unit         = "${jsonencode(data.template_file.git_sshd_socket_unit.rendered)}"
    git_home_service_unit        = "${jsonencode(data.template_file.git_home_service_unit.rendered)}"
    git_home_mount_unit          = "${jsonencode(data.template_file.git_home_mount_unit.rendered)}"
    git_format_service           = "${jsonencode(data.template_file.git_format_service.rendered)}"
    git_format_service_enabled   = "${var.git_format_volume == true}"
  }
}
