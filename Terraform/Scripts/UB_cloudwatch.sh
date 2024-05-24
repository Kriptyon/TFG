#!/bin/bash

# Actualiza el sistema
sudo apt-get update

# Instala el agente de CloudWatch Logs
sudo apt-get install -y awslogs

# Configura el agente de CloudWatch Logs
sudo tee /etc/awslogs/awslogs.conf <<EOF
[general]
state_file = /var/lib/awslogs/agent-state

[/var/log/syslog]
log_group_name = /var/log/health_cert
log_stream_name = {instance_id}
file = /var/log/syslog
datetime_format = %b %d %H:%M:%S

[/var/log/cloud-init.log]
log_group_name = /var/log/health_cert
log_stream_name = {instance_id}-cloud-init
file = /var/log/cloud-init.log
datetime_format = %Y-%m-%dT%H:%M:%S.%f
EOF

# Configura la región de CloudWatch Logs
sudo tee /etc/awslogs/awscli.conf <<EOF
[plugins]
cwlogs = cwlogs
[default]
region = eu-west-1
EOF

# Reinicia el servicio de CloudWatch Logs para aplicar los cambios
sudo systemctl restart awslogs

# Habilita el servicio de CloudWatch Logs para que se inicie en el arranque
sudo systemctl enable awslogs
