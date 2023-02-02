resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "devops-vpc"
    }
}

resource "aws_subnet" "main" {
    vpc_id = aws_vpc.main.id
    availability_zone = var.availability_zone_name
    cidr_block = "10.0.1.0/24"
    
    tags = {
        Name = "devops-subnet-1"
    }
    
    depends_on = [
        aws_vpc.main
    ]
}

resource "aws_route_table" "public-table" {
    vpc_id = aws_vpc.main.id
    
    tags = {
        Name = "devops-public-table"
    }

    depends_on = [
        aws_subnet.main
    ]
}

resource "aws_route" "default_route" {
    route_table_id = aws_route_table.public-table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id =  aws_internet_gateway.main.id
    
    depends_on = [
        aws_route_table.public-table
    ]
}

resource "aws_route_table_association" "a" {
    subnet_id      = aws_subnet.main.id
    route_table_id = aws_route_table.public-table.id
    
    depends_on = [
        aws_route.default_route
    ]
}

resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id
    
    tags = {
        Name = "devops-igw"
    }

    depends_on = [
        aws_route_table.public-table
    ]
}

resource "aws_security_group" "sg-public" {
    name        = "allow_ports"
    description = "Allow HTTP and SSH inbound traffic"
    vpc_id      = aws_vpc.main.id

    ingress {
        description      = "HTTP"
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    ingress {
        description      = "SSH"
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
    }

    tags = {
        Name = "allow_web"
    }

    depends_on = [
      aws_subnet.main
    ]
}

resource "aws_network_interface" "srv-nic" {
    subnet_id = aws_subnet.main.id
    private_ips = [var.private_ip]
    security_groups = [aws_security_group.sg-public.id]

    depends_on = [
        aws_security_group.sg-public
    ]
}

resource "aws_eip" "one" {
    vpc = true
    network_interface = aws_network_interface.srv-nic.id
    associate_with_private_ip = var.private_ip
    
    depends_on = [
        aws_internet_gateway.main,
        aws_network_interface.srv-nic
    ]
}

resource "aws_instance" "srv-1" {
    ami = var.ec2_ami
    instance_type = var.ec2_instance_type
    availability_zone = var.availability_zone_name
    key_name = var.ec2_key_name

    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.srv-nic.id
    }

    user_data = var.ec2_user_data
    
    tags = {
        Name = "web-srv"
    }
    
    depends_on = [
        aws_eip.one,
        aws_network_interface.srv-nic
    ]
}