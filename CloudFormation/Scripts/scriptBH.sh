#!/bin/bash

sudo yum update
sudo yum upgrade -y

amazon-linux-extras install -y epel

sudo yum install ssh
sudo systemctl enable ssh
sudo systemctl start ssh
sudo systemctl restart ssh

# Actualiza el sistema
sudo yum update -y

# Instala el agente de CloudWatch Logs
sudo yum install -y awslogs

# Configura el agente de CloudWatch Logs
sudo tee /etc/awslogs/awslogs.conf <<EOF
[general]
state_file = /var/lib/awslogs/agent-state

[/var/log/messages]
log_group_name = /var/log/health_cert
log_stream_name = {instance_id}
file = /var/log/messages
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
sudo service awslogs restart

# Habilita el servicio de CloudWatch Logs para que se inicie en el arranque
sudo chkconfig awslogs on
# Hostname deseado
DESIRED_HOSTNAME="SRV-ENR"

# Función para verificar si una contraseña cumple con los requisitos
check_password() {
    password=$1

    # Comprobar si la contraseña tiene la cantidad de caracteres necesarios
    if [ ${#password} -lt 8 ]; then
        echo "CONTRASEÑA MALA: La contraseña contiene menos de 8 caracteres"
        return 1
    fi

    # Comprobar si contiene al menos 1 mayúscula
    if ! [[ $password =~ [[:upper:]] ]]; then
        echo "MALA CONTRASEÑA: Contiene menos de 1 letra mayúscula"
        return 1
    fi

    # Comprobar si la contraseña se encuentra en el diccionario
    if grep -q "^$password$" /usr/share/dict/words; then
        echo "DEBUG: Contraseña encontrada en el diccionario: $password"
        echo "MALA CONTRASEÑA: La contraseña es demasiado fácil o fácilmente adivinable"
        return 1
    else
        echo "DEBUG: Contraseña no encontrada en el diccionario: $password"
    fi

    # Si todas las comprobaciones pasan, devuelve éxito
    return 0
}

echo "@@@@@@ $DESIRED_HOSTNAME @@@@@@"
yum update -y

# Evita la aparición del servicio udisks2 y reinicia automáticamente
sudo NEEDRESTART_MODE=a yum dist-upgrade --assumeyes

# Configura el nombre de host de la instancia
if [ -n "$DESIRED_HOSTNAME" ]; then
    echo "$DESIRED_HOSTNAME" > /etc/hostname
    hostnamectl set-hostname "$DESIRED_HOSTNAME"
    sed -i "s/127.0.0.1 localhost/127.0.0.1 localhost $DESIRED_HOSTNAME/g" /etc/hosts
fi

# PAM
# Complejidad de la contraseña (usando módulos PAM)
# Instala los paquetes necesarios
yum install -y libpwquality

# Configura PAM
sed -i '/pam_pwquality.so/d' /etc/pam.d/common-password
echo "password requisite pam_pwquality.so retry=3 minlen=8 maxrepeat=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1 difok=3 gecoscheck=1 reject_username enforce_for_root" >> /etc/pam.d/common-password

# Añade un diccionario personalizado para los ajustes de contraseña
custom_dict="/usr/share/dict/custom-dict"
cat << EOF >> "$custom_dict"
HealthCert
Healthcert
HEALTHCERT
hEALTHCERT
HealthCert1
HealthCert2
HealthCert3
HealthCert4
HealthCert5
HealthCert6
HealthCert7
HealthCert8
HealthCert9
HealthCert0
HealthCert123
HealthCert1234
HealthCert12345
HealthCert123456
HealthCert2018
HealthCert2019
HealthCert2020
HealthCert2021
HealthCert2022
HealthCert2023
HealthCert2024
HealthCert01
HealthCert02
HealthCert03
HealthCert04
HealthCert05
HealthCert06
HealthCert07
HealthCert08
HealthCert09
HealthCert10
HealthCert11
HealthCert12
HealthCert13
HealthCert14
HealthCert15
HealthCert16
HealthCert17
HealthCert18
HealthCert19
HealthCert20
HealthCert21
HealthCert22
HealthCert23
HealthCert24
HealthCert25
HealthCert26
HealthCert27
HealthCert28
HealthCert29
HealthCert30
HealthCert31
HealthCert!
HealthCert@
HealthCert#
HealthCert$
HealthCert!@
HealthCert!@#
HealthCert!@#$
HealthCert123!
HealthCert!123
HealthCert1@
HealthCert2018!
HealthCert2019!
HealthCert2020!
HealthCert2021!
HealthCert2022!
HealthCert!2018
HealthCert!2019
HealthCert!2020
HealthCert!2021
HealthCert!2022
HealthCert!2023
HealthCert!2024
HealthCert2018!@#
HealthCert2019!@#
HealthCert2020!@#
HealthCert2021!@#
HealthCert2022!@#
HealthCert2023!@#
HealthCert2024!@#
HealthCert01!
HealthCert02!
HealthCert03!
HealthCert04!
HealthCert05!
HealthCert06!
HealthCert07!
HealthCert08!
HealthCert09!
HealthCert10!
HealthCert11!
HealthCert12!
HealthCert13!
HealthCert14!
HealthCert15!
HealthCert16!
HealthCert17!
HealthCert18!
HealthCert19!
HealthCert20!
HealthCert21!
HealthCert22!
HealthCert23!
HealthCert24!
HealthCert25!
HealthCert26!
HealthCert27!
HealthCert28!
HealthCert29!
HealthCert30!
HealthCert31!
Healthcert1
Healthcert2
Healthcert3
Healthcert4
Healthcert5
Healthcert6
Healthcert7
Healthcert8
Healthcert9
Healthcert0
Healthcert123
Healthcert1234
Healthcert12345
Healthcert123456
Healthcert2018
Healthcert2019
Healthcert2020
Healthcert2021
Healthcert2022
Healthcert2023
Healthcert2024
Healthcert!
Healthcert@
Healthcert#
Healthcert$
Healthcert!@
Healthcert!@#
Healthcert!@#$
Healthcert123!
Healthcert!123
Healthcert1@
Healthcert2018!
Healthcert2019!
Healthcert2020!
Healthcert2021!
Healthcert2022!
Healthcert!2018
Healthcert!2019
Healthcert!2020
Healthcert!2021
Healthcert!2022
Healthcert!2023
Healthcert!2024
Healthcert2018!@#
Healthcert2019!@#
Healthcert2020!@#
Healthcert2021!@#
Healthcert2022!@#
Healthcert2023!@#
Healthcert2024!@#
Healthcert01!
Healthcert02!
Healthcert03!
Healthcert04!
Healthcert05!
Healthcert06!
Healthcert07!
Healthcert08!
Healthcert09!
Healthcert10!
Healthcert11!
Healthcert12!
Healthcert13!
Healthcert14!
Healthcert15!
Healthcert16!
Healthcert17!
Healthcert18!
Healthcert19!
Healthcert20!
Healthcert21!
Healthcert22!
Healthcert23!
Healthcert24!
Healthcert25!
Healthcert26!
Healthcert27!
Healthcert28!
Healthcert29!
Healthcert30!
Healthcert31!
Healthcert01
Healthcert02
Healthcert03
Healthcert04
Healthcert05
Healthcert06
Healthcert07
Healthcert08
Healthcert09
Healthcert10
Healthcert11
Healthcert12
Healthcert13
Healthcert14
Healthcert15
Healthcert16
Healthcert17
Healthcert18
Healthcert19
Healthcert20
Healthcert21
Healthcert22
Healthcert23
Healthcert24
Healthcert25
Healthcert26
Healthcert27
Healthcert28
Healthcert29
Healthcert30
Healthcert31
EOF

sort -u -o "$custom_dict" "$custom_dict"
create-cracklib-dict /usr/share/dict/custom-dict /usr/share/dict/cracklib-small

#Zabbix

# Variables
ZABBIX_VERSION="6.0"  # Specify the Zabbix version you want to install
ZABBIX_SERVER_IP="10.0.1.10"  # Replace with the IP address of your Zabbix server

# Update the system
sudo yum update -y

# Install prerequisites
sudo yum install -y wget

# Download the Zabbix repository package
wget https://repo.zabbix.com/zabbix/$ZABBIX_VERSION/rhel/9/x86_64/zabbix-release-$ZABBIX_VERSION-1.el9.noarch.rpm

# Install the Zabbix repository
sudo rpm -Uvh zabbix-release-$ZABBIX_VERSION-1.el9.noarch.rpm

# Clean the repository cache
sudo yum clean all

# Install the Zabbix agent
sudo yum install -y zabbix-agent

# Configure the Zabbix agent
sudo sed -i "s/^Server=.*/Server=$ZABBIX_SERVER_IP/" /etc/zabbix/zabbix_agentd.conf
sudo sed -i "s/^ServerActive=.*/ServerActive=$ZABBIX_SERVER_IP/" /etc/zabbix/zabbix_agentd.conf
sudo sed -i "s/^Hostname=.*/Hostname=$(hostname)/" /etc/zabbix/zabbix_agentd.conf

# Enable and start the Zabbix agent service
sudo systemctl enable zabbix-agent
sudo systemctl start zabbix-agent

# Verify the Zabbix agent is running
sudo systemctl status zabbix-agent
# Telegram

# Token y chat_id de Telegram
TELEGRAM_BOT_TOKEN="6835637516:AAFCs4xax9K37Xq3p2Sgkqt_8gVjAhYhB7A"
TELEGRAM_CHAT_ID="5089735569"

# Mensaje a enviar
MESSAGE="El script de configuración se ha ejecutado con éxito en $DESIRED_HOSTNAME."

# Envía el mensaje utilizando la API de Telegram
curl -s -X POST https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage -d chat_id=$TELEGRAM_CHAT_ID -d text="$MESSAGE"

# Actualización de PAM
sudo pam-auth-update --force --package pwquality

echo "Script ejecutado con éxito."