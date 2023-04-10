provider "aws" {
    region = "us-east-1"
    access_key = "AKIA3EZ5M2KHCVKGZDNM"
    secret_key = "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"
}

resource "aws_vpc" "first-vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "Production"
    }
}

// Internet Gateway //
resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.first-vpc.id

}



// Create a Route Table  //

resource "aws_route_table" "main-route-table" {
  vpc_id = aws_vpc.first-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "example"
  }
}

// Create a Subnet //

resource "aws_subnet" "subnet-1" {
    vpc_id = aws_vpc.first-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"

    tags = {
        Name = "main-subnet"
    }
}
// Associate subnet with Route Table
  resource "aws_route_table_association" "a" {
    subnet_id = aws_subnet.subnet-1.id 
    route_table_id = aws_route_table.main-route-table.id
  }
// Create a Security Group //

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.first-vpc.id 

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
    from_port        = 2
    to_port          = 2
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

// Create a network interface with an ip in the subnet that was created in the previous step
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

// Assign an elastic IP to the network interface created in a previous step
 resource "aws_eip" "one" {
    vpc = true
    network_interface = aws_network_interface.web-server-nic.id
    associate_with_private_ip = "10.0.1.50"
    depends_on = [aws_internet_gateway.gw]
 }

 // Create an Ubuntu server and install
  resource "aws_instance" "web-server-instance" {
  ami  = "ami-007855ac798b5175e"
  instance_type  = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "terraform1"
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-nic.id
   }
   user_data =  <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo my web server has been created > /var/www/html/index.html'
                EOF
        tags = {
            Name = "web server"
        }

}

/* resource "aws_instance" "terraform1" {
    ami  = "ami-007855ac798b5175e"
    instance_type  = "t2.micro"
    tags = {
        Name = "My Terraform WB"
    }
} */

/* resource "<provider>_<resource_type>" "name" {
    config options.....
    key = "value"
    key2 = "another value"
} */