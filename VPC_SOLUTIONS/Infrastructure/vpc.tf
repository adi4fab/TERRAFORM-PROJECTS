## AWS provider block ##

provider "aws" {
  region = var.region
}




## Defining the backend. Takes value dynamically form the infra-prod.config file ##

terraform {
  backend "s3" {}
}



## Defining the VPC for production ##

resource "aws_vpc" "prod-vpc" {
  cidr_block = var.cidr
  enable_dns_hostnames = true  // this is for instance in public subnet to have hostnames.
                               // so that hostnames can be used without exposing IP address.
  tags = {
    Name = "production-vpc"
  }
}





## creating 3 public subnets ##

resource "aws_subnet" "public-subnet-1" {
  cidr_block = var.pub-sub-1-cidr
  vpc_id = aws_vpc.prod-vpc.id
  availability_zone = "eu-west-1a"

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public-subnet-2" {
  cidr_block = var.pub-sub-2-cidr
  vpc_id = aws_vpc.prod-vpc.id
  availability_zone = "eu-west-1b"

  tags = {
    Name = "public-subnet-2"
  }
}

resource "aws_subnet" "public-subnet-3" {
  cidr_block = var.pub-sub-3-cidr
  vpc_id = aws_vpc.prod-vpc.id
  availability_zone = "eu-west-1c"

  tags = {
    Name = "public-subnet-3"
  }
}




## creating 3 private subnets ##

resource "aws_subnet" "private-subnet-1" {
  cidr_block = var.pri-sub-1-cidr
  vpc_id = aws_vpc.prod-vpc.id
  availability_zone = "eu-west-1a"

  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private-subnet-2" {
  cidr_block = var.pri-sub-2-cidr
  vpc_id = aws_vpc.prod-vpc.id
  availability_zone = "eu-west-1b"

  tags = {
    Name = "private-subnet-2"
  }
}

resource "aws_subnet" "private-subnet-3" {
  cidr_block = var.pri-sub-3-cidr
  vpc_id = aws_vpc.prod-vpc.id
  availability_zone = "eu-west-1c"

  tags = {
    Name = "private-subnet-3"
  }
}




## creating public route table ##

resource "aws_route_table" "public-RT" {
  vpc_id = aws_vpc.prod-vpc.id

  tags = {
    Name = "public-RT"
  }
}




## Creating private route table ##

resource "aws_route_table" "private-RT" {
  vpc_id = aws_vpc.prod-vpc.id

  tags = {
    Name = "private-RT"
  }
}



## Public route table associate with public subnets ##

resource "aws_route_table_association" "public-subnet-1-associate" {
  subnet_id = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.public-RT.id
}

resource "aws_route_table_association" "public-subnet-2-associate" {
  subnet_id = aws_subnet.public-subnet-2.id
  route_table_id = aws_route_table.public-RT.id
}

resource "aws_route_table_association" "public-subnet-3-associate" {
  subnet_id = aws_subnet.public-subnet-3.id
  route_table_id = aws_route_table.public-RT.id
}



## Private route table associate with private subnet ##

resource "aws_route_table_association" "private-subnet-1-associate" {
  subnet_id = aws_subnet.private-subnet-1.id
  route_table_id = aws_route_table.private-RT.id
}

resource "aws_route_table_association" "private-subnet-2-associate" {
  subnet_id = aws_subnet.private-subnet-2.id
  route_table_id = aws_route_table.private-RT.id
}

resource "aws_route_table_association" "private-subnet-3-associate" {
  subnet_id = aws_subnet.private-subnet-3.id
  route_table_id = aws_route_table.private-RT.id
}





## creating an EIP for NAT gateway ##

resource "aws_eip" "EIP-NAT" {
  vpc = true
  associate_with_private_ip = "10.0.0.5" // private IP for EIP, taken form the given IP pool.

  tags = {
    Name = "production EIP"
  }
}





## creating a NAT gateway ##

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.EIP-NAT.id
  subnet_id     = aws_subnet.public-subnet-1.id //one subnet ID because the NAT gateway will be using a public subnet.
  depends_on = [aws_eip.EIP-NAT]
  tags = {
    Name = "NAT gateway"
  }
}


## creation of Routes for private subnets ##

resource "aws_route" "nat-gateway" {
  route_table_id = aws_route_table.private-RT.id
  nat_gateway_id = aws_nat_gateway.nat-gw.id
  destination_cidr_block = "0.0.0.0/0"    //Instances can access internet but outside world cannot access the resource
}                                         // egress rule






## creation of Routes for public subnets ##

resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.prod-vpc.id

  tags = {
    Name = "IGW"
  }
}


## creation of Routes for public subnets ##

resource "aws_route" "internet-gateway" {
  route_table_id = aws_route_table.public-RT.id
  gateway_id = aws_internet_gateway.internet-gateway.id
  destination_cidr_block = "0.0.0.0/0"
}

########### End of layer 1 - will be defining the values of variables in tf.vars file #####################
########### This state will be uploaded in backend and can be used in layer 2 infra   #######################









