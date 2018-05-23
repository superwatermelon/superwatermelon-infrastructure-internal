variable "jenkins_ssl_cert" {

}

resource "aws_lb" "jenkins" {
  name         = "jenkins"
  subnets      = ["${aws_subnet.subnet.*.id}"]
  idle_timeout = 60

  security_groups = [
    "${aws_security_group.jenkins_elb_sg.id}",
    "${aws_security_group.users_sg.id}"
  ]

  tags {
    Name = "jenkins"
  }
}

resource "aws_lb_listener" "jenkins" {
  load_balancer_arn = "${aws_lb.jenkins.arn}"
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = "${var.jenkins_ssl_cert}"

  default_action {
    target_group_arn = "${aws_lb_target_group.jenkins.arn}"
    type             = "forward"
  }
}

resource "aws_lb_target_group" "jenkins" {
  name     = "jenkins"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.vpc.id}"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    path                = "/login?from=%2F"
    interval            = 30
  }
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = "${aws_lb_target_group.jenkins.arn}"
  target_id        = "${module.jenkins.id}"
}
