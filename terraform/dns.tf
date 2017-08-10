data "aws_route53_zone" "chefdemo" {
  name = "chefdemo.net."
}

resource "aws_route53_record" "automate" {
  zone_id = "${data.aws_route53_zone.chefdemo.zone_id}"
  name    = "${var.workshop_prefix}-workshop.${data.aws_route53_zone.chefdemo.name}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.automate.public_ip}"]
}
