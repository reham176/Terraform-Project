provider "aws" {
}
variable "subnet_cidr_block"  {}
variable "avil_zone" {} #bas keda whigib el value bta3ha mn env.var eli ana m3rfaha fil terminal
variable "vpc_cidr_block"  {}
variable "env" {} #ha5li el user y2oli wich env ha deploy fiha
variable "my_ip" {}
variable "instance_type" {}
variable "public_key_location" {}

resource "aws_vpc" "my-vpc"{  #dah name 5as bel terraform 3alashan 2ader 23mlo referecing wana b3mel subnets
    #cidr_block = var.cidr_blocks[0].cidr_block han5li el modo3 2shel
    cidr_block = var.vpc_cidr_block
    tags = { #dah el name eli hayzhar fel vpc 
        Name = "${var.env}-vpc"
    }
}
resource "aws_subnet" "my-app-subnet"{
    vpc_id = aws_vpc.my-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avil_zone
    tags = {
        Name = "${var.env}-subnet"
    }
}

resource "aws_internet_gateway" "my-app-igw" {
    vpc_id = aws_vpc.my-vpc.id
    tags ={
        Name = "${var.env}-igw"
    }
}



resource "aws_default_route_table" "main_rtb"{
   default_route_table_id = aws_vpc.my-vpc.default_route_table_id
   route {
        cidr_block="0.0.0.0/0"
        gateway_id=aws_internet_gateway.my-app-igw.id
     }
   tags= {
        Name = "${var.env}-main-rtb"
    }

}
#security group
resource "aws_security_group" "myapp-sg"{
    name ="my-app-sg"
    vpc_id=aws_vpc.my-vpc.id
    ingress {
        from_port = 22
        to_port = 22
        protocol="tcp"
        cidr_blocks=[var.my_ip] #keda el ip bta3i bas eli y2dr ywsl llport 22 ana bas eli 2dr 23ml ssh 3ala el server
    }
    ingress {
        from_port = 8080
        to_port = 8080
        protocol="tcp"
        cidr_blocks=["0.0.0.0/0"] #laken hena 2i 7ad fel donia y2dr ywsl to server 3ala elport 8080
    }
    egress {
        from_port=0
        to_port=0
        protocol="-1"
        cidr_blocks=["0.0.0.0/0"]
        prefix_list_ids=[]
    }
   tags= {
        Name = "${var.env}-my-app-sg"
    } 
}

#fetch the ami
data "aws_ami" "amazon-linux-image"{
    most_recent= true    #btgeb 25er 7aga 20 25er version
    owners= ["amazon"]
    filter {
        name= "name"   #key hndor bel name el ami name
        values =["amzn2-ami-*x86_64-gp2"]  #2i 7aga mn kmtha tdlna 3aliha w 7na 25trna to filter by name * ya3ni 2i 7aga fel nos

    }
    filter {
        name= "virtualization-type"
        values =["hvm"]

    }
}
output "ami_id" {
    value = data.aws_ami.amazon-linux-image.id
}

#creating ec2
resource "aws_instance" "myapp-server"{
    ami=data.aws_ami.amazon-linux-image.id #hatgeb value of ami mn el data keda el ec2 bta3i hytcreate fi 2i region y2dr ywsl lami bdon mshakel
    instance_type= var.instance_type #ec2 btkon sizes b5tar binhom el free t2.micro han3mlo var 3alashan lo 7ad 3ayz y2om ec2 bsize tani
    subnet_id= aws_subnet.my-app-subnet.id #ha2om el ec2 fi 2nhi subnet
    vpc_security_group_ids= [aws_security_group.myapp-sg.id] #sg eli 3ala ec2 ha3mlha 3ala shakl list l2nha aktr mn id l2n momken akt mn sg
    availability_zone= var.avil_zone
    associate_public_ip_address= true #3lashan at2ked 2n el e2 hya5od public ip 2ol may2om k2ni 3mlto enable 3alashan el nas t2dr access 3alih
    key_name =aws_key_pair.ssh-key.key_name
    user_data = <<EOF
                  #!/bin/bash
                  sudo yum update -y 
                  sudo yum install docker -y
                  sudo systemctl start docker
                  sudo systemctl enable docker
                  sudo chmod 666 /var/run/docker.sock
                  sudo chown $USER /var/run/docker.sock
                  sudo usermod -aG docker ec2-user
                  docker run -d -p 8080:80 nginx
                  sleep 30
                EOF
    tags= {
        Name = "${var.env}-server"
    } 
}
 resource "aws_key_pair" "ssh-key"{
    key_name= "myapp-key"
    public_key =file(var.public_key_location) 
    
 }

 output "my-server-ip"{
    value = aws_instance.myapp-server.public_ip
 }

















