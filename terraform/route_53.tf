resource "aws_route53_zone" "internal_dns" {
  name    = "${var.internal_hosted_zone}"
  comment = "Internal"
  vpc_id  = "${aws_vpc.vpc.id}"

  tags {
    Name = "internal"
  }
}

resource "aws_route53_record" "jenkins_internal_dns_record" {
  zone_id = "${aws_route53_zone.internal_dns.zone_id}"
  name    = "jenkins.${var.internal_hosted_zone}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.jenkins.private_ip}"]
}

resource "aws_route53_record" "git_internal_dns_record" {
  zone_id = "${aws_route53_zone.internal_dns.zone_id}"
  name    = "git.${var.internal_hosted_zone}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.git.private_ip}"]
}
