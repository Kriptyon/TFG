#APKs CLINICAS
  config.vm.define "SRV-APKS-CLINICAS" do |app_server|
    app_server.vm.box = "gusztavvargadr/ubuntu-server"
# Interfaces
    app_server.vm.network "private_network", type: "dhcp", virtualbox__intnet: "red1", auto_config: false

#Instalaciones
    app_server.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get install -y openjdk-11-jdk
    # OSCare
    sudo apt-get install -y tomcat9
    sudo systemctl start tomcat9
    sudo systemctl enable tomcat9
    # OpenMRS
    sudo wget https://downloads.openmrs.org/releases/OpenMRS_Platform_2.4.0/openmrs.war -O /var/lib/tomcat9/webapps/openmrs.war
    sudo systemctl restart tomcat9
    # HAPI FHIR
    sudo wget https://github.com/hapifhir/hapi-fhir-jpaserver-starter/releases/download/5.4.0/hapi-fhir-jpaserver-starter-5.4.0.jar -O /opt/hapi-fhir-jpaserver-starter.jar
    sudo systemctl restart tomcat9
SHELL
end
# Correo y Comunicaciones
config.vm.define "SRV-CORREO-COM" do |mail_server|
  mail_server.vm.box = "gusztavvargadr/ubuntu-server"
  
  #Interfaces
  mail_server.vm.network "private_network", type: "dhcp", virtualbox__intnet: "red1", auto_config: false


  #Postfix
  mail_server.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update
    sudo apt-get install -y postfix mailutils
  SHELL

  # ejabberd
  mail_server.vm.provision "shell", inline: <<-SHELL
    sudo apt-get install -y ejabberd
    sudo systemctl start ejabberd
    sudo systemctl enable ejabberd
    sudo sed -i 's/hosts: \[.*\]/hosts: \["localhost"\]/' /etc/ejabberd/ejabberd.yml
    sudo systemctl restart ejabberd
  SHELL
end


end
