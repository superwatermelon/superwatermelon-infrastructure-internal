data "template_file" "unit" {
  template = "${file("${path.module}/templates/service.tpl")}"
}

data "ignition_systemd_unit" "unit" {
    name    = "${var.name}"
    content = "${data.template_file.unit.rendered}"
}
