resource "aws_vpc" "demo-vpc" {
  cidr_block = "10.0.0.0/21"

  tags = {
    Name = "demo-vpc"
  }
}

resource "aws_subnet" "demo-subnet1" {
  vpc_id                  = aws_vpc.demo-vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "ap-south-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "demo-subnet"
  }
}

resource "aws_subnet" "demo-subnet2" {
  vpc_id                  = aws_vpc.demo-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "demo-subnet"
  }
}

resource "aws_internet_gateway" "demo-igw" {
  vpc_id = aws_vpc.demo-vpc.id

  tags = {
    Name = "demo-igw"
  }
}

resource "aws_route_table" "demo-RT1" {
  vpc_id = aws_vpc.demo-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo-igw.id
  }
}

resource "aws_route_table" "demo-RT2" {
  vpc_id = aws_vpc.demo-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo-igw.id
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.demo-subnet1.id
  route_table_id = aws_route_table.demo-RT1.id
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.demo-subnet2.id
  route_table_id = aws_route_table.demo-RT2.id
}

resource "aws_security_group" "demo-SG" {
  name        = "demo-SG"
  description = "Allow HTTP AND HTTPS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.demo-vpc.id

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_http"
  }
}

resource "aws_instance" "demo-instance1" {
  ami               = "ami-0e7938ad51d883574"
  instance_type     = "t3.micro"
  availability_zone = "ap-south-2a"
  subnet_id         = aws_subnet.demo-subnet1.id
  security_groups   = [aws_security_group.demo-SG.id]
}

resource "aws_instance" "demo-instance2" {
  ami               = "ami-0e7938ad51d883574"
  instance_type     = "t3.micro"
  availability_zone = "ap-south-2b"
  subnet_id         = aws_subnet.demo-subnet2.id
  security_groups   = [aws_security_group.demo-SG.id]
}

#create alb
resource "aws_lb" "demo-alb" {
  name               = "demo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.demo-SG.id]
  subnets            = [aws_subnet.demo-subnet1.id, aws_subnet.demo-subnet2.id]
}

resource "aws_lb_target_group" "tg" {
  name     = "tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demo-vpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_target_group_attachment" "tga1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.demo-instance1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "tga2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.demo-instance2.id
  port             = 80
}

resource "aws_lb_listener" "alb-listener" {
  load_balancer_arn = aws_lb.demo-alb.arn
  port              = "80"
  protocol          = "HTTP"



  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_instance" "my-server"{

}

output "loadBalancerDNS" {
  value = aws_lb.demo-alb.dns_name
}

module "vpc-ex" {
    source = "./modules/vpc"
    
}

