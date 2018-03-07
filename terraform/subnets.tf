variable "subnet_cidr_range" {
  description = "The CIDR range for the subnet."
  default     = [
    "10.128.16.0/24",
    "10.128.17.0/24",
    "10.128.18.0/24"
  ]
}

variable "availability_zone" {
  description = "The availability zone into which to create the subnet."
  default     = [
    "eu-west-1a",
    "eu-west-1b",
    "eu-west-1c"
  ]
}

resource "aws_subnet" "subnet" {
  count                   = 3
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.subnet_cidr_range[count.index]}"
  availability_zone       = "${var.availability_zone[count.index]}"
  map_public_ip_on_launch = true

  tags {
    Name = "tools"
  }
}

resource "aws_route_table_association" "subnet_rtb" {
  count          = 3
  subnet_id      = "${element(aws_subnet.subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.public_rtb.id}"
}
