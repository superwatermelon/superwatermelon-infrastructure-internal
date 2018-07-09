data "template_file" "unit" {
  template = "${file("${path.module}/templates/service.tpl")}"

  vars {
    volume = "${var.volume}"
  }
}

data "ignition_systemd_unit" "unit" {
    name = "${var.name}"
    enabled = "${var.enabled}"
    content = "${data.template_file.unit.rendered}"
}
