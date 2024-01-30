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
        range 192.168.100.2 192.168.100.2;
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
  end