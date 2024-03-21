# Define provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "MyfirtsVPC"
  }
}

# Create IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "MyIGW"
  }
}
#Create Eip
resource "aws_eip" "nat_eip" {
    vpc = true
}

#Create NAT
resource "aws_nat_gateway" "nat_gateway" {

  depends_on = [aws_eip.nat_eip]
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.private_subnet.id
  tags = {
    "Name" = "Private NAT GW: For Private rt table "
  }
}
# Create Subnet Public
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "PublicSubnet"
  }
}
# Create subnet Prvt
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1c"
   tags = {
    Name = "PrvtSubnet"
  }
}

# Create Route Table Public 
resource "aws_route_table" "pubRtable" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "RT Public:subnet "
  }
}
# Create Route Table Prvt
resource "aws_route_table" "prvRtable" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name = "RT Private:subnet "
  }
}

# Assosiate Route Table Publicadd IGW to This 
resource "aws_route_table_association" "public_subnet_asso" {
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.pubRtable.id
}
# Associate Route table Prvt
resource "aws_route_table_association" "prvlic_subnet_asso" {
    subnet_id = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.prvRtable.id
}
# Create Security Group ForPublic ??

resource "aws_security_group" "sg_public" {
  egress = [
    {
      cidr_blocks      = [ "0.0.0.0/0", ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    }
  ]
  ingress                = [
    {
      cidr_blocks      = [ "0.0.0.0/0", ]
      description      = ""
      from_port        = 22
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 22
    }
  ]
  vpc_id = aws_vpc.my_vpc.id
  
  tags = {
    Name = "SG : Public ec2 "
  }
}
# Create Security Group For Prvt
resource "aws_security_group" "sg_prvt" {
  egress = [
    {
      cidr_blocks      = [ "0.0.0.0/0", ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    }
  ]
  ingress                = [
    {
      cidr_blocks      = [ "0.0.0.0/0", ]
      description      = ""
      from_port        = 22
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 22
    }
  ]
  vpc_id = aws_vpc.my_vpc.id
  
  tags = {
    Name = "SG : Private ec2 "
  }
}

#CreateEC2 in  Public
resource "aws_instance" "publicec2" {
  ami = "ami-0767046d1677be5a0"
  instance_type = "t2.micro"
  tags = {
    Name = "PublicEC2"
  }
  key_name= "k8"
  subnet_id = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.sg_public.id]
}

#Create EC2 In Private

resource "aws_instance" "prvtEC2" {
  ami = "ami-0767046d1677be5a0"
  instance_type = "t2.micro"
  tags = {
    Name = "PrivateEC2"
  }
  key_name= "k8"
  subnet_id = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.sg_prvt.id]
}