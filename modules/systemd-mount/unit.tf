data "template_file" "unit" {
  template = "${file("${path.module}/templates/mount.tpl")}"

  vars {
    requires    = "${var.requires}"
    after       = "${var.after}"
    volume      = "${var.volume}"
    mount_point = "${var.mount_point}"
    type        = "${var.type}"
  }
}

data "ignition_systemd_unit" "unit" {
    name    = "${var.name}"
    content = "${data.template_file.unit.rendered}"
}
