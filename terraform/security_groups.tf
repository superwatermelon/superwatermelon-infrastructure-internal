resource "aws_security_group" "users_sg" {
  name        = "tools-users"
  description = "User access to tools"
  vpc_id      = "${aws_vpc.vpc.id}"

  tags {
    Name = "tools-users"
  }
}

resource "aws_security_group_rule" "git_from_jenkins" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.git_sg.id}"
  source_security_group_id = "${aws_security_group.jenkins_sg.id}"
}

resource "aws_security_group_rule" "git_from_jenkins_agent" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.git_sg.id}"
  source_security_group_id = "${aws_security_group.jenkins_agent_sg.id}"
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins"
  description = "Jenkins"
  vpc_id      = "${aws_vpc.vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "jenkins"
  }
}

resource "aws_security_group" "jenkins_agent_sg" {
  name        = "jenkins-agent"
  description = "Jenkins agent"
  vpc_id      = "${aws_vpc.vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "jenkins-agent"
  }
}

resource "aws_security_group" "git_sg" {
  name        = "git"
  description = "Git"
  vpc_id      = "${aws_vpc.vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "git"
  }
}
