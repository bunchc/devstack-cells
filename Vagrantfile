# -*- mode: ruby -*-
# vi: set ft=ruby :

nodes = {
  'parent' => [1, 100],
  'cell' => [1, 101],
}

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Virtual Box
  config.vm.box = "trusty64"
  config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"

  # VMware Fusion
  config.vm.provider "vmware_fusion" do |vmware, override|
    override.vm.box = "trusty64_fusion"
    override.vm.box_url = "https://oss-binaries.phusionpassenger.com/vagrant/boxes/latest/ubuntu-14.04-amd64-vmwarefusion.box"  

    # Fusion Performance Hacks
    vmware.vmx["logging"] = "FALSE"
    vmware.vmx["MemTrimRate"] = "0"
    vmware.vmx["MemAllowAutoScaleDown"] = "FALSE"
    vmware.vmx["mainMem.backing"] = "swap"
    vmware.vmx["sched.mem.pshare.enable"] = "FALSE"
    vmware.vmx["snapshot.disabled"] = "TRUE"
    vmware.vmx["isolation.tools.unity.disable"] = "TRUE"
    vmware.vmx["unity.allowCompostingInGuest"] = "FALSE"
    vmware.vmx["unity.enableLaunchMenu"] = "FALSE"
    vmware.vmx["unity.showBadges"] = "FALSE"
    vmware.vmx["unity.showBorders"] = "FALSE"
    vmware.vmx["unity.wasCapable"] = "FALSE"
    vmware.vmx["memsize"] = "2048"
    vmware.vmx["numvcpus"] = "1"
    vmware.vmx["vhv.enable"] = "TRUE"
  end

  nodes.each do |prefix, (count, ip_start)|
    count.times do |i|

        hostname = "%s-%02d" % [prefix, (i+1)]
        config.vm.define hostname do |box|
          box.vm.hostname = "#{hostname}"
          box.vm.network :private_network, ip: "172.16.0.#{ip_start+i}", :netmask => "255.255.0.0"
          box.vm.network :private_network, ip: "10.10.0.#{ip_start+i}", :netmask => "255.255.0.0"
          box.vm.provision :shell, :inline => "sudo apt-get update && sudo apt-get install -y vim wget git curl screen kvm libvirt-bin virtinst"
          box.vm.provision :shell, :inline => "sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\" dist-upgrade"
          if prefix == "parent"
            box.vm.provision :shell, path: "./parent.sh"
          elsif prefix == "cell"
            box.vm.provision :shell, path: "./cell.sh", :args => "172.16.0.100"
          end
        end
      end
    end
end
