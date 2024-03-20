# Define provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.10.0.0/16"
  tags = {
    Name = "MyfirtsVPC"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "MyIGW"
  }
}

# Create a public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1b"
}

# Create a private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1c"
}

# Create a route table for the VPC
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "MyRoutTable"
  }
}

# Create a route for the public subnet
resource "aws_route" "public_subnet_route" {
  route_table_id         = aws_route_table.my_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

# Associate public subnet with a route table
resource "aws_route_table_association" "public_route_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

# Associate private subnet with a route table
resource "aws_route_table_association" "private_route_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

# Create a network ACL for the public subnet
resource "aws_network_acl" "public_acl" {
  vpc_id = aws_vpc.my_vpc.id

  # Ingress rules
  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "172.16.1.0/32"
    from_port  = 0
    to_port    = 65535
  }

  ingress {
    protocol   = "-1"
    rule_no    = 101
    action     = "allow"
    cidr_block = "172.16.1.1/32"
    from_port  = 0
    to_port    = 65535
  }

  ingress {
    protocol   = "-1"
    rule_no    = 102
    action     = "allow"
    cidr_block = "172.16.1.2/32"
    from_port  = 0
    to_port    = 65535
  }

  # Egress rule
  egress {
    protocol   = "-1"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  subnet_ids = [aws_subnet.public_subnet.id]
}
# Create a network ACL for the private subnet
resource "aws_network_acl" "private_acl" {
  vpc_id = aws_vpc.my_vpc.id

  # Ingress rules
  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.1.0/24"

  }

  # Egress rule
  egress {
    protocol   = "-1"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"

  }

  subnet_ids = [aws_subnet.private_subnet.id]
}

# Launch an EC2 instance in the public subnet
resource "aws_instance" "public_instance" {
  ami           = "ami-0742b4e673072066f"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  key_name      = "k8"
  tags = {
    Name = "pubec2"
  }
}

# Launch an EC2 instance in the private subnet
resource "aws_instance" "private_instance" {
  ami           = "ami-0742b4e673072066f"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet.id
  key_name      = "k8"
  tags = {
    Name = "prec2"
  }
}

