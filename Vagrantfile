# -*- mode: ruby -*-
# vim: set ft=ruby :
ENV["LC_ALL"] = "en_US.UTF-8"


MACHINES = {
  :systemd => {
        :box_name => "generic/centos8s",
        :box_version => "4.3.4",
        :ip_addr => '192.168.56.115',
    }
}


Vagrant.configure("2") do |config|


  MACHINES.each do |boxname, boxconfig|


      config.vm.define boxname do |box|


        box.vm.box = boxconfig[:box_name]
        box.vm.box_version = boxconfig[:box_version]
        box.vm.host_name = "systemd"
        box.vm.provider :virtualbox do |vb|
              vb.customize ["modifyvm", :id, "--memory", "1024"]
              needsController = false
        end

        box.vm.provision "shell", inline: <<-SHELL
              mkdir -p ~root/.ssh
              cp ~vagrant/.ssh/auth* ~root/.ssh
              sudo sed -i 's/\#PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
              systemctl restart sshd
        SHELL

     end
  end
end
