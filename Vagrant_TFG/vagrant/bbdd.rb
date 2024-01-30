# Base de Datos
config.vm.define "SRV-DDBB" do |db_server|
    db_server.vm.box = "gusztavvargadr/ubuntu-server"
  #Interfaz
    db_server.vm.network "private_network", type: "dhcp", virtualbox__intnet: "red1", auto_config: false

#Configuración BBDD
    db_server.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get install -y mysql-server
    sudo service mysql restart
    sudo mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'sebas';
    FLUSH PRIVILEGES;"
    sudo service mysql restart
    sudo mysql -u root -p < /vagrant/database.sql
  SHELL
end