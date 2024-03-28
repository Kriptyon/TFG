#!/bin/bash
nuevo_netplan=$(cat <<EOL
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0: # Interfaz pública
      dhcp4: true
    eth1: # Interfaz privada 1
      dhcp4: false
      addresses: [192.168.x.x/24]
    
EOL
)
echo "$nuevo_netplan" | sudo tee /etc/netplan/00-network-manager-all.yaml > /dev/null
sudo netplan apply
