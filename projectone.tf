

#Providing with the provider

provider "aws" {
  region     = "us-east-1"
  access_key = "AKIAXJMYKKOJNCKYCU52"
  secret_key = "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"
}

#creating a VPC

resource "aws_vpc" "deepanshu_vpc" {
  cidr_block = "10.0.0.0/16"
   tags = {
    Name = "production"
   }
 }


#create a internet gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.deepanshu_vpc.id
}

#create a custom route table

resource "aws_route_table" "prod_route_table" {
  vpc_id = aws_vpc.deepanshu_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Prod" 
  }
}


#Creating the subnet

resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.deepanshu_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "prod-subnet"
  }
}

#assosiating the subnet with the route table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod_route_table.id

}

#creating the security group

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow WEB traffic"
  vpc_id      = aws_vpc.deepanshu_vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_WEB"
  }
}

#creating network interface(this assign private IP)

resource "aws_network_interface" "web_server_nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}


#providing elastic IP(Public ip to be accesed by public)

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web_server_nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}

#creating the ubuntu server install apache

resource "aws_instance" "web-server-instance" {
	
	ami = "0747bdcabd34c712"
	instance_type = "t2.micro"
	availability_zone = "us-east-1a"
	key_name = "terraform-key"

	network_interface {
		device_index = 0
		network_interface_id = aws_network_interface.web_server_nic.id

	}
	user_data = <<-EOF
		#!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo your very first web server >  /var/www/html/index.html'
              EOF

 tags = {
    "Name" = "Web Server"
  }
}













