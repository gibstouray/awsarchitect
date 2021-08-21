resource "aws_vpc" "softcom-vpc"{
    cidr_block                          = var.vpcidr
    instance_tenancy                    = "default"
    enable_dns_hostnames                = true
    enable_dns_support                  = true
    # main_route_table_id               =
    # aws_main_route_table_association  =
    # default_route_table_id            =
    # default_security_group_id         =

    tags = {
      Name  = "softcom-vpc"
    }

}

resource "aws_subnet" "public_sub"{
    vpc_id          = aws_vpc.softcom-vpc.id
    cidr_block      =  var.public_subnet
    map_public_ip_on_launch = true
    availability_zone = element(var.azs,0)

    tags = {
      Name = "public_1"
    }
}

resource "aws_subnet" "private_sub"{
    vpc_id          = aws_vpc.softcom-vpc.id
    cidr_block      =  var.private_subnet
    availability_zone = element(var.azs,1)
   
    

    tags = {
      Name = "private_1"
    }
}

#create an instance, an ubuntu instance
resource "aws_instance" "webserver" {
  # us-west-2
  ami           = "ami-00f22f6155d6d92c5"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.allow_ssh.id]

  #private_ip = "10.0.1.0/24"
  subnet_id  = aws_subnet.private_sub.id
  key_name =  "my_keys"

  tags = {
    Name = "SoftComWebserver"
  }
}

# create another instance that we will put in the public subnet
# Note that this instance is not shown in the diagram of our infrastructure
# This instance will be our bastion host. Thats why i name it such way
# we will then ssh into this instance and get into the instance in the private subnet
#create an instance, an ubuntu instance
resource "aws_instance" "bastionhost" {
  # us-west-2
  ami           = "ami-00f22f6155d6d92c5"
  instance_type = "t2.micro"

  #private_ip = "10.0.1.0/24"
  subnet_id  = aws_subnet.public_sub.id
  security_groups = [aws_security_group.allow_ssh.id]
  key_name =  "my_keys"

  tags = {
    Name = "SoftComBastionHost"
  }
}

# create an Internet gateway

resource "aws_internet_gateway" "softcom_igw"{
    vpc_id = aws_vpc.softcom-vpc.id

    tags = {
      Name  = "softcom_igw"
    }
}

#route table for public subnet
resource "aws_route_table" "prod-public-rtable" {
  vpc_id = aws_vpc.softcom-vpc.id
  
  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.softcom_igw.id
  }

  tags = {
    Name = "public-rtable"
  }
}

# create a route table for the private subnet
#route table for public subnet
resource "aws_route_table" "prod-priv-rtable" {
  vpc_id = aws_vpc.softcom-vpc.id
  
  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.softcom_natgw.id
  }

  tags = {
    Name = "private-rtable"
  }
}

# associate the public subnet with our routing table

resource "aws_route_table_association" "publicsubnetassoc"{
  subnet_id = aws_subnet.public_sub.id
  route_table_id =  aws_route_table.prod-public-rtable.id

}

# Associate the private subnet with our routing private route table

resource "aws_route_table_association" "privatesubassoc"{
  subnet_id = aws_subnet.private_sub.id
  route_table_id =  aws_route_table.prod-priv-rtable.id
}

# create elastic ip which is used by the nat gateway
resource "aws_eip" "softcom_eip" {
  vpc      = true
  #instance = aws_instance.webserver.id
  #associate_with_private_ip = aws_instance.webserver.private_ip
  depends_on = [aws_internet_gateway.softcom_igw]
}


resource "aws_nat_gateway" "softcom_natgw"{
    allocation_id = aws_eip.softcom_eip.id
    subnet_id = aws_subnet.public_sub.id
    #Note that the value assighed to depends_on is a literal not in quotes
    # This is possible but it will be deprecated in later versions of Terraform 
    depends_on = [aws_internet_gateway.softcom_igw]

    tags = {
      Name = "softcom_natgw"
    }
}

# ceate a security group to allow ssh traffic in and out

resource "aws_security_group" "allow_ssh"{
  name        = "allow_ssh"
  description = "allow ssh inbound traffic"
  vpc_id = aws_vpc.softcom-vpc.id

  ingress {
      description      = "ssh from VPC"
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
      
    }

  tags = {
    Name = "allow_ssh"
  }
}
