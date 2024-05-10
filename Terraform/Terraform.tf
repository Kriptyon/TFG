provider "aws" {
    region = "eu-west-1"
}

resource "aws_vpc" "health-cert-network" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "HealthCertNetwork"
    }
}

resource "aws_subnet" "public_subnet" {
    vpc_id            = aws_vpc.health-cert-network.id
    cidr_block        = "10.0.1.0/24"
    availability_zone = "eu-west-1"

    tags = {
        Name = "Red_Publica"
    }
}

resource "aws_subnet" "private_subnet" {
    vpc_id            = aws_vpc.health-cert-network.id
    cidr_block        = "10.0.2.0/24"
    availability_zone = "eu-west-1"

    tags = {
        Name = "Red_Privada"
    }
}

resource "aws_internet_gateway" "my_igw" {
    vpc_id = aws_vpc.health-cert-network.id

    tags = {
        Name = "Gateway"
    }
}

resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.health-cert-network.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my_igw.id
    }
}

resource "aws_route_table_association" "public_route_association" {
    subnet_id      = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_route_table.id
}

resource "aws_eip" "nat_eip" {
    vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
    allocation_id = aws_eip.nat_eip.id
    subnet_id     = aws_subnet.public_subnet.id
}

resource "aws_route_table" "private_route_table" {
    vpc_id = aws_vpc.health-cert-network.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_gateway.id
    }
}

resource "aws_route_table_association" "private_route_association" {
    subnet_id      = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.private_route_table.id
}

resource "aws_security_group" "bastion_ssh" {
    name        = "ssh-bastion-host-sg"
    description = "Permite SSH desde Bastion Host"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "bastion_host" {
    ami                    = "ami-094025d68c6601508" // Amazon Linux 2023
    instance_type          = "t2.micro"
    key_name               = "Bastion_Host.pem"
    associate_public_ip_address = true

    network_interface {
        subnet_id         = aws_subnet.public_subnet.id
        security_groups   = [aws_security_group.bastion_ssh.id]
        device_index      = 0
    }

    network_interface {
        subnet_id         = aws_subnet.private_subnet.id
        device_index      = 1
    }

    tags = {
        Name        = "Bastion Host"
        Departamento = "Seguridad"
    }

    provisioner "file" {
        source      = "Scripts/scriptBH.sh"
        destination = "/tmp/scriptBH.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "chmod +x /tmp/scriptBH.sh",
            "/tmp/scriptBH.sh"
        ]
    }  
}

resource "aws_security_group" "zabbix_sg" {
    name        = "zabbix-security-group"
    description = "Permite SSH desde el bastion host y tráfico HTTP y Zabbix Agent desde Odoo"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [aws_instance.bastion_host.id]
    }

    ingress {
        from_port   = 10050
        to_port     = 10050
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "zabbix_srv" {
    ami           = "ami-094025d68c6601508" // Amazon Linux 2023
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.private_subnet.id
    key_name      = "Zabbix-srv.pem"
    security_groups = [aws_security_group.zabbix_sg.id]

    tags = {
        Name        = "Zabbix Server"
        Departamento = "Seguridad"
    }

    provisioner "file" {
        source      = "Scripts/SCRIPT-ZABBIX.sh"
        destination = "/tmp/SCRIPT-ZABBIX.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "chmod +x /tmp/SCRIPT-ZABBIX.sh",
            "/tmp/SCRIPT-ZABBIX.sh"
        ]
    }  
}

resource "aws_security_group" "odoo_sg" {
    name        = "odoo-security-group"
    description = "Permite SSH desde el bastion host y tráfico HTTP y Zabbix Agent desde Zabbix"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [aws_instance.bastion_host.id]
    }

    ingress {
        from_port   = 10050
        to_port     = 10050
        protocol    = "tcp"
        security_groups = [aws_security_group.zabbix_sg.id]
    }
}

resource "aws_instance" "odoo" {
    ami           = "ami-0776c814353b4814d" // Ubuntu server 24.04
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.private_subnet.id
    key_name      = "Odoo-SRV.pem"
    security_groups = [aws_security_group.odoo_sg.id]

    tags = {
        Name        = "Odoo"
        Departamento = "IT"
    }

    provisioner "file" {
        source      = "Scripts/SCRIPT-ODOO17.sh"
        destination = "/tmp/SCRIPT-ODOO17.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "chmod +x /tmp/SCRIPT-ODOO17.sh",
            "/tmp/SCRIPT-ODOO17.sh"
        ]
    }  
}
