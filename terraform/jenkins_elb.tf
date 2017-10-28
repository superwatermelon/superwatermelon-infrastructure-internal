variable "jenkins_ssl_cert" {

}

resource "aws_elb" "jenkins" {
  name               = "jenkins"
  subnets            = ["${aws_subnet.subnet.id}"]
  security_groups    = [
    "${aws_security_group.jenkins_elb_sg.id}",
    "${aws_security_group.users_sg.id}"
  ]

  listener {
    instance_port      = 8080
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${var.jenkins_ssl_cert}"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8080/login?from=%2F"
    interval            = 30
  }

  instances                   = ["${aws_instance.jenkins.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 60
  connection_draining         = true
  connection_draining_timeout = 60

  tags {
    Name = "jenkins"
  }
}
