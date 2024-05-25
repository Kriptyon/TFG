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
        security_groups = [
            aws_security_group.Zabbix_SG.id
            aws_security_group.Web_SG.id
            ]
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

    user_data     = file("C:/Users/sebsg/Desktop/HealthCert/Scripts/scriptBH.sh")

    tags = {
        Name        = "Bastion Host"
        Departamento = "Seguridad"
    }
}

resource "aws_security_group" "Zabbix_SG" {
    name        = "zabbix-security-group"
    description = "Permite SSH desde el bastion host, tráfico HTTP/HTTPS y tráfico Zabbix"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["${aws_instance.bastion_host.public_ip}/32"]
    }

    ingress {
        from_port   = 10050
        to_port     = 10050
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 10051
        to_port     = 10051
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "zabbix_srv" {
    ami           = "ami-0607a9783dd204cae" // Ubuntu server 22.04
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.private_subnet.id
    key_name      = "Zabbix-srv"
    user_data     = file("C:/Users/sebsg/Desktop/HealthCert/Scripts/SCRIPT-ZABBIX.sh")
    private_ip    = "10.0.2.10"
    security_groups = [aws_security_group.Zabbix_SG.id]

    tags = {
        Name        = "Zabbix Server"
        Departamento = "Seguridad"
    }
}

resource "aws_security_group" "Web_SG" {
    name        = "web-security-group"
    description = "Permite SSH desde el Bastion Host, tráfico Zabbix Server y HTTP/HTTPS"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["${aws_instance.bastion_host.public_ip}/32"]
    }

    ingress {
        from_port   = 10050
        to_port     = 10050
        protocol    = "tcp"
        cidr_blocks = ["10.0.2.10/32"]  # Permitir tráfico Zabbix Server desde IP 10.0.2.10
    }

    ingress {
        from_port   = 10051
        to_port     = 10051
        protocol    = "tcp"
        cidr_blocks = ["10.0.2.10/32"]  # Permitir tráfico Zabbix Server desde IP 10.0.2.10
    }

    ingress {
        from_port   = 27017  # Puerto por defecto de DocumentDB
        to_port     = 27017
        protocol    = "tcp"
        security_groups = [aws_security_group.Zabbix_SG.id]  # Permitir acceso desde el grupo de seguridad de Zabbix
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]  # Permitir tráfico HTTP desde cualquier IP
    }

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]  # Permitir tráfico HTTPS desde cualquier IP
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"  # Permite todo el tráfico saliente
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "Web-SRV" {
    ami           = "ami-0607a9783dd204cae" // Ubuntu server 22.04
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.private_subnet.id
    key_name      = "Web-SRV"
    user_data     = file("C:/Users/sebsg/Desktop/HealthCert/Scripts/SCRIPT-WEB.sh")
    private_ip    = "10.0.2.20"
    security_groups = [aws_security_group.Web_SG.id]

    tags = {
        Name        = "Web"
        Departamento = "IT"
    }
}

resource "aws_docdb_cluster" "hcdb_cluster" {
  cluster_identifier        = "hcdb-cluster"
  instance_class            = "db.t3.micro"
  engine_version            = "4.0.0"
  master_username           = "HCDB_Admin"
  master_password           = "Contraseña123"
  preferred_backup_window   = "07:00-09:00"
  skip_final_snapshot       = true
  storage_encrypted         = true
  apply_immediately         = true

  vpc_security_group_ids    = [aws_security_group.Web_SG.id] 

  tags = {
    Name = "HCDB"
  }
}

resource "aws_cloudwatch_log_group" "logs_cw" {
  name              = "/var/log/health_cert"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_subscription_filter" "instance_logs_subscription" {
  name            = "instance_logs_subscription"
  log_group_name = aws_cloudwatch_log_group.logs_cw.name
  filter_pattern = ""

  destination_arn = aws_cloudwatch_log_group.logs_cw.arn
}
