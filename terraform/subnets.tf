variable "subnet_cidr_range" {
  description = "The CIDR range for the subnet."
  default     = "10.128.16.0/24"
}

variable "availability_zone" {
  description = "The availability zone into which to create the subnet."
  default     = "eu-west-1a"
}

resource "aws_subnet" "subnet" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.subnet_cidr_range}"
  availability_zone       = "${var.availability_zone}"
  map_public_ip_on_launch = true

  tags {
    Name = "tools"
  }
}

resource "aws_route_table_association" "subnet_rtb" {
  subnet_id      = "${aws_subnet.subnet.id}"
  route_table_id = "${aws_route_table.public_rtb.id}"
}
