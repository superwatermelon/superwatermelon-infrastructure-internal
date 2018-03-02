data "template_file" "docker_registry_service" {
  template = "${file("${path.module}/templates/docker_registry.service.tpl")}"
}

data "template_file" "var_lib_registry_mount" {
  template = "${file("${path.module}/templates/var_lib_registry.mount.tpl")}"
  vars {
    volume = "${var.docker_registry_volume_device}"
  }
}

data "template_file" "docker_registry_format_volume_service" {
  template = "${file("${path.module}/templates/format_volume.service.tpl")}"
  vars {
    volume = "${var.docker_registry_volume_device}"
  }
}
