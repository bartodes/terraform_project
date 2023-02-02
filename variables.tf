variable "ec2_instance_type" {
    type = string
    default = "t2.micro"
}

variable "ec2_ami" {
    type = string
    default = "ami-00874d747dde814fa"
}

variable "ec2_user_data" {
  type = string
  default = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install apache2 -y
    sudo ufw disable
    sudo service start apache2 && sudo systemctl enable apache2
    echo "Hello World!" > /var/www/html/index.html 
    EOF
}

variable "ec2_key_name" {
    type = string
    default = "tf-devops"
    # key_name --> Replace this value with the name of your key pair or remove the line, if you dont want to set any.
}

variable "availability_zone_name" {
    type = string
    default = "us-east-1a"
}

variable "private_ip" {
    type = string
    default = "10.0.1.50"
}