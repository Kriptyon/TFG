# Enrutador
config.vm.define "SRV-ENRUTADOR" do |router|
    router.vm.box = "gusztavvargadr/ubuntu-server"
    # Interfaces de red
    router.vm.network "public_network", type: "dhcp", name: "enp0s3", bridge: "Intel(R) Wi-Fi 6 AX201 160MHz"
    router.vm.network "private_network", type: "static", ip: "192.168.1.1", name: "enp0s8"
    router.vm.network "private_network", type: "static", ip: "192.168.100.1", name: "enp0s9"
    # DHCP y Bind9
    router.vm.provision "shell", inline: <<-SHELL
      sudo apt-get update
      sudo apt-get upgrade -y
      sudo apt-get install -y isc-dhcp-server
      sudo apt-get install -y bind9
  
      # Configuración del servidor DHCP
      sudo tee /etc/dhcp/dhcpd.conf > /dev/null <<~EOL
      subnet 192.168.1.0 netmask 255.255.255.0 {
        range 192.168.1.50 192.168.1.100;
        option routers 192.168.1.1;
        option domain-name-servers 8.8.8.8, 8.8.4.4;
      }
  
      subnet 192.168.100.0 netmask 255.255.255.252 {
<<<<<<< HEAD
        range 192.168.100.2 192.168.100.2;
=======
        range 192.168.100.50 192.168.100.100;
>>>>>>> 6fa9240409f0c6b377e1a5f76c617bdf111adf92
        option routers 192.168.100.1;
        option domain-name-servers 8.8.8.8, 8.8.4.4;
      }
      EOL
  
      # Configura las interfaces para DHCP
      sudo tee /etc/default/isc-dhcp-server > /dev/null <<~EOL
      INTERFACESv4="enp0s8 enp0s9"
      EOL
  
      # Reinicia el servicio DHCP
      sudo service isc-dhcp-server restart
    SHELL
  
    router.vm.provision "file", source: "vagrant/named.conf.options", destination: "/etc/bind/named.conf.options"
    router.vm.provision "file", source: "vagrant/db.local", destination: "/etc/bind/db.local"

    #REINICIAMOS BIND9
    router.vm.provision "shell", inline: <<-SHELL
      sudo systemctl restart bind9
    SHELL
<<<<<<< HEAD
  end
=======
  end

  config.vm.define "SRV-Odoo" do |odoo|
  config.vm.box = "gusztavvargadr/ubuntu-server"

  config.vm.network "private_network", type: "static", ip: "192.168.1.2"

    config.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update
    sudo apt upgrade
    sudo apt install postgresql -y
    sudo systemctl status postgresql
    sudo su postgres
    psql postgres postgres
    postgres=# \l+
    q
    \q
    exit
    sudo apt install python3-pip xfonts-75dpi xfonts-base libxrender1 libjpeg-turbo8 fontconfig -y
    sudo echo "deb http://security.ubuntu.com/ubuntu focal-security main" | sudo tee /etc/apt/sources.list.d/focal-security.list
    sudo apt update
    sudo apt install libssl1.1
    cd /opt
    sudo wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.bionic_amd64.deb
    sudo dpkg -i wkhtmltox_0.12.6-1.bionic_amd64.deb
    sudo cp /usr/local/bin/wkhtmltoimage  /usr/bin/wkhtmltoimage
    sudo cp /usr/local/bin/wkhtmltopdf  /usr/bin/wkhtmltopdf
    sudo wget -q -O - https://nightly.odoo.com/odoo.key | sudo gpg --dearmor -o /usr/share/keyrings/odoo-archive-keyring.gpg
    sudo echo 'deb [signed-by=/usr/share/keyrings/odoo-archive-keyring.gpg] https://nightly.odoo.com/16.0/nightly/deb/ ./' | sudo tee /etc/apt/sources.list.d/odoo.list
    sudo apt install odoo -y
    sudo systemctl restart odoo
    sudo systemctl status odoo
    


  SHELL
end
>>>>>>> 6fa9240409f0c6b377e1a5f76c617bdf111adf92
