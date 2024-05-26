#!/bin/bash
# Hostnme deseado
DESIRED_HOSTNAME="ZABBIX-SRV"

# Función para checkear si una contraseña pasa los requerimientos
check_password() {
    password=$1

    # Comprueba si la contraseña tiene la cantidad de caracteres necesarios
    if [ ${#password} -lt 8 ]; then
        echo "CONTRASEÑA MALA: La contraseña contiene menos de 8 caracteres"
        return 1
    fi

    # Comprueba si contiene al menos 1 mayúscula
    if ! [[ $password =~ [[:upper:]] ]]; then
        echo "MALA CONTRASEÑA: Contiene menos de 1 letra mayúscula"
        return 1
    fi

    # Comprueba si la contraseña se encuentra en el diccionario
    if grep -q "^$password$" /usr/share/dict/words; then
        echo "DEBUG: Contraseña encontrada en el diccionario: $password"
        echo "MALA CONTRASEÑA: La contraseña es muy fácil o fácilmente adivinable"
        return 1
    else
        echo "DEBUG: Contraseña no encontrada en el diccionario: $password"
    fi

    # Si todas las comprobaciones pasan, retorna éxito
    return 0
}

echo "@@@@@@ $DESIRED_HOSTNAME @@@@@@"
apt update -y

# Prevents the popup of udisks2.service and automates the restart of it
sudo NEEDRESTART_MODE=a apt dist-upgrade --assumeyes


# Configure the hostname of the instance
if [ -n "$DESIRED_HOSTNAME" ]; then
    echo "$DESIRED_HOSTNAME" > /etc/hostname
    hostnamectl set-hostname "$DESIRED_HOSTNAME"
    sed -i "s/127.0.0.1 localhost/127.0.0.1 localhost $DESIRED_HOSTNAME/g" /etc/hosts
fi


#PAM
# Password Complexity (Using PAM modules)
# Install necessary packages
apt install libpam-pwquality -y

# Configure PAM
sed -i '/pam_pwquality.so/d' /etc/pam.d/common-password
echo "password requisite pam_pwquality.so retry=3 minlen=8 maxrepeat=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1 difok=3 gecoscheck=1 reject_username enforce_for_root" >> /etc/pam.d/common-password

#Añadimos un diccionario Personalizado para los ajustes de Contraseña.

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

# Actualización de PAM
sudo pam-auth-update --force --package pwquality

#SSH
sudo apt install -y ssh
sudo systemctl enable ssh
sudo systemctl start ssh
sudo systemctl restart ssh
#INSTALAR ZABBIX SERVER
# Variables
DB_NAME="zabbix_HC"
DB_USER="s.garcia_HC"
DB_PASS="43]iO_eGya(rP,U"
ZBX_SERVER_IP="127.0.0.1"
TIMEZONE="Europe/Madrid"
sudo apt update
sudo apt -y upgrade
sudo apt -y install wget gnupg2
wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4+ubuntu22.04_all.deb
sudo dpkg -i zabbix-release_6.0-4+ubuntu22.04_all.deb
sudo apt update
sudo apt -y install zabbix-server-pgsql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent postgresql
sudo -i -u postgres psql -c "CREATE DATABASE ${DB_NAME};"
sudo -i -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';"
sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};"
zcat /usr/share/doc/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u postgres psql ${DB_NAME}
sudo sed -i "s/# DBPassword=/DBPassword=${DB_PASS}/" /etc/zabbix/zabbix_server.conf
sudo systemctl restart zabbix-server zabbix-agent
sudo systemctl enable zabbix-server zabbix-agent
sudo sed -i "s/^;date.timezone =$/date.timezone = ${TIMEZONE}/" /etc/php/*/apache2/php.ini
sudo systemctl restart apache2
sudo tee /etc/zabbix/web/zabbix.conf.php <<EOL
<?php
// Zabbix GUI configuration file.
\$DB['TYPE'] = 'POSTGRESQL';
\$DB['SERVER'] = 'localhost';
\$DB['PORT'] = '5432';
\$DB['DATABASE'] = '${DB_NAME}';
\$DB['USER'] = '${DB_USER}';
\$DB['PASSWORD'] = '${DB_PASS}';
\$DB['SCHEMA'] = '';
\$ZBX_SERVER = '${ZBX_SERVER_IP}';
\$ZBX_SERVER_PORT = '10051';
\$ZBX_SERVER_NAME = 'Zabbix Server';
\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
?>
EOL

# Telegram

# Token y chat_id de Telegram
TELEGRAM_BOT_TOKEN="6835637516:AAFCs4xax9K37Xq3p2Sgkqt_8gVjAhYhB7A"
TELEGRAM_CHAT_ID="5089735569"

# Mensaje a enviar
MESSAGE="El script de configuración ha sido ejecutado con éxito en  $DESIRED_HOSTNAME."

# Envía el mensaje utilizando la API de Telegram
curl -s -X POST https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage -d chat_id=$TELEGRAM_CHAT_ID -d text="$MESSAGE"


echo "Script executed successfully."
