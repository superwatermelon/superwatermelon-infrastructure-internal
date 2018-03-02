data "template_file" "docker_registry_ignition" {
  template = "${file("${path.module}/templates/docker_registry_ignition.tpl")}"
  vars {
    docker_registry_service = "${jsonencode(data.template_file.docker_registry_service.rendered)}"
    var_lib_registry_mount  = "${jsonencode(data.template_file.var_lib_registry_mount.rendered)}"
    format_volume_service   = "${jsonencode(data.template_file.docker_registry_format_volume_service.rendered)}"
    format_volume_enabled   = "${var.docker_registry_format_data == true}"
  }
}
