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
    availability_zone = "eu-west-1a"

    tags = {
        Name = "Red_Publica"
    }
}

resource "aws_subnet" "private_subnet" {
    vpc_id            = aws_vpc.health-cert-network.id
    cidr_block        = "10.0.2.0/24"
    availability_zone = "eu-west-1a"

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

    tags = {
        Name = "PublicRouteTable"
    }
}

resource "aws_route_table_association" "public_route_association" {
    subnet_id      = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_route_table.id
}

resource "aws_eip" "nat_eip" {
    domain = "vpc"
}

resource "aws_nat_gateway" "nat_gateway" {
    allocation_id = aws_eip.nat_eip.id
    subnet_id     = aws_subnet.public_subnet.id

    tags = {
        Name = "NATGateway"
    }
}

resource "aws_route_table" "private_route_table" {
    vpc_id = aws_vpc.health-cert-network.id

    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_gateway.id
    }

    tags = {
        Name = "PrivateRouteTable"
    }
}

resource "aws_route_table_association" "private_route_association" {
    subnet_id      = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.private_route_table.id
}

resource "aws_security_group" "bastion_ssh" {
    name        = "ssh-bastion-host-sg"
    description = "Permite SSH desde Bastion Host en la subred privada"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        security_groups = [aws_security_group.private_subnet.id]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_network_interface" "public" {
    subnet_id       = aws_subnet.public_subnet.id
}

resource "aws_network_interface" "private" {
    subnet_id       = aws_subnet.private_subnet.id
    security_groups = [aws_security_group.bastion_ssh.id]
}

resource "aws_instance" "bastion_host" {
    ami           = "ami-0dfdc165e7af15242" // Amazon Linux 2023
    instance_type = "t2.micro"
    key_name      = "Bastion_Host"

    network_interface {
        network_interface_id = aws_network_interface.public.id
        device_index         = 0
    }

    network_interface {
        network_interface_id = aws_network_interface.private.id
        device_index         = 1
    }

    user_data     = file("/home/kpt/TFG/Terraform-TFG/Scripts/scriptBH.sh")

    tags = {
        Name        = "Bastion Host"
        Departamento = "Seguridad"
    }
}

resource "aws_security_group" "Zabbix_SG" {
    name        = "zabbix-security-group"
    description = "Permite SSH desde el bastion host y tráfico HTTP"

    # Regla que permite SSH desde el bastion host
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [aws_instance.bastion_host.public_ip]
    }

    # Regla que permite tráfico Zabbix Server a Agentes
    ingress {
        from_port   = 10050
        to_port     = 10050
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Regla que permite tráfico Agentes a Zabbix Server
    ingress {
        from_port   = 10051
        to_port     = 10051
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Regla de egress que permite todo el tráfico saliente
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1" # Permite todo el tráfico
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "zabbix_srv" {
    ami           = "ami-0dfdc165e7af15242" // Amazon Linux 2023
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.private_subnet.id
    key_name      = "Zabbix-srv"
    user_data     = file("/home/kpt/TFG/Terraform-TFG/Scripts/SCRIPT-ZABBIX.sh")
    private_ip = "10.0.2.10"

    tags = {
        Name        = "Zabbix Server"
        Departamento = "Seguridad"
    }
}

resource "aws_security_group" "Odoo_SG" {
    name        = "Odoo-security-group"
    description = "Permite SSH desde el Bastion Host y tráfico Zabbix Server"

    ingress {
        from_port   = 22  # Puerto SSH
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [aws_instance.bastion_host.public_ip]  # Permitir SSH del Bastion Host
    }

    ingress {
        from_port   = 10050  # Puerto Zabbix Server
        to_port     = 10051
        protocol    = "tcp"
        cidr_blocks = ["10.0.2.10/32"]  # Permitir tráfico Zabbix Server (IP 10.0.2.10)
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1" # Permite todo el tráfico saliente
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "odoo" {
    ami           = "ami-0776c814353b4814d" // Ubuntu server 24.04
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.private_subnet.id
    key_name      = "Odoo-SRV"
    user_data     = file("/home/kpt/TFG/Terraform-TFG/Scripts/SCRIPT-ODOO17.sh")
    private_ip = "10.0.2.20"

    tags = {
        Name        = "Odoo"
        Departamento = "IT"
    }
}