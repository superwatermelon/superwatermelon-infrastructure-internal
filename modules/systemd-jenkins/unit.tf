data "template_file" "unit" {
  template = "${file("${path.module}/templates/service.tpl")}"
  vars {
    env_file       = "${var.env_file}"
    container_name = "${var.container_name}"
    docker_image   = "${var.docker_image}"
    mount_point    = "${var.mount_point}"
  }
}

data "ignition_systemd_unit" "unit" {
    name    = "${var.name}"
    content = "${data.template_file.unit.rendered}"
}
