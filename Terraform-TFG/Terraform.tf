provider "aws" {
    region = "eu-west-1"
}

resource "aws_route53_zone" "dominio_healthcert" {
  name = "healthcert.com" 
}

resource "aws_route53_record" "registro" {
  zone_id = aws_route53_zone.dominio_healthcert.zone_id
  name    = "www.healthcert.com"
  type    = "A"
  ttl     = "300"
  records = ["1.2.3.4"]  # Enter the IP address associated with this record
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

resource "aws_route_table" "tabla_route" {
    vpc_id = aws_vpc.health-cert-network.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my_igw.id
    }
}

resource "aws_route_table_association" "public_route_association" {
    subnet_id      = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.tabla_route.id
}

resource "aws_internet_gateway" "my_igw" {
    vpc_id = aws_vpc.health-cert-network.id

    tags = {
        Name = "Gateway"
    }
}

# BASTION HOST

resource "aws_security_group" "ssh_bh" {
    name        = "ssh-bastion-host-sg"
    description = "Permite SSH desde Bastion Host"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        security_groups = [aws_security_group.ssh_pn.id]
    }
}

resource "aws_instance" "bastion_host" {
    ami           = "ami-094025d68c6601508" // Amazon Linux 2023
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.public_subnet.id
    key_name      = "Bastion_Host.pem"
    security_groups = [aws_security_group.ssh_bh.name]

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

# Zabbix

resource "aws_security_group" "ssh_pn" {
    name        = "zabbix-security-group"
    description = "Permite SSH desde el bastion host y tráfico HTTP"

    # Regla que permite SSH desde el bastion host
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [aws_instance.bastion_host.public_ip]
    }
    ingress {
        from_port   = 10050
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "zabbix-srv" {
    ami           = "ami-094025d68c6601508" // Amazon Linux 2023
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.private_subnet.id
    key_name      = "Zabbix-srv.pem"
    security_groups = [aws_security_group.ssh_pn.name]

    tags = {
        Name        = "Bastion Host"
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


# ODOO

resource "aws_instance" "Odoo" {
    ami           = "ami-0776c814353b4814d" // Ubuntu server 24.04
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.private_subnet.id
    key_name      = "Odoo-SRV.pem"
    security_groups = [aws_security_group.ssh_pn.name]

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