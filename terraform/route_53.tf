variable "public_hosted_zone" {

}

resource "aws_route53_zone" "private_dns" {
  name    = "${var.internal_hosted_zone}"
  comment = "Internal private"
  vpc_id  = "${aws_vpc.vpc.id}"

  tags {
    Name = "internal-private"
  }
}

resource "aws_route53_record" "jenkins_private_dns_record" {
  zone_id = "${aws_route53_zone.private_dns.zone_id}"
  name    = "jenkins.${var.internal_hosted_zone}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.jenkins.private_ip}"]
}

resource "aws_route53_record" "git_private_dns_record" {
  zone_id = "${aws_route53_zone.private_dns.zone_id}"
  name    = "git.${var.internal_hosted_zone}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.git.private_ip}"]
}

resource "aws_route53_zone" "public_dns" {
  name    = "${var.public_hosted_zone}"
  comment = "Internal public"

  tags {
    Name = "internal-public"
  }
}

resource "aws_route53_record" "jenkins_public_dns_record" {
  zone_id = "${aws_route53_zone.public_dns.zone_id}"
  name    = "jenkins.${var.public_hosted_zone}"
  type    = "A"

  alias {
    name                   = "${aws_lb.jenkins.dns_name}"
    zone_id                = "${aws_lb.jenkins.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "git_public_dns_cname_record" {
  zone_id = "${aws_route53_zone.public_dns.zone_id}"
  name    = "git.${var.public_hosted_zone}"
  type    = "CNAME"
  ttl     = "300"
  records = ["git.${var.internal_hosted_zone}"]
}

resource "aws_route53_record" "git_public_dns_record" {
  zone_id = "${aws_route53_zone.public_dns.zone_id}"
  name    = "git.${var.internal_hosted_zone}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_eip.git_eip.public_ip}"]
}
