# -*- mode: ruby -*-
# vi: set ft=ruby :

nodes = {
  'controller' => [1, 100],
  'devstack' => [1, 101],
}

$commonscript = <<COMMONSCRIPT
#### Prep Environment
sudo adduser --disabled-password --gecos "" stack
echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
git clone -b stable/icehouse https://github.com/openstack-dev/devstack.git /home/stack/devstack/

COMMONSCRIPT

$masterscript = <<MASTERSCRIPT
MY_IP=$(ifconfig eth1 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')

git clone https://github.com/openstack/heat-templates.git /home/stack/heat-templates/
git clone https://github.com/stackforge/rally /home/stack/rally
cp /home/stack/rally/contrib/devstack/lib/rally /home/stack/devstack/lib/
cp /home/stack/rally/contrib/devstack/extras.d/70-rally.sh /home/stack/devstack/extras.d/

echo "
{
    "type": "ExistingCloud",
    "endpoint": {
        "auth_url": "http://${MY_IP}:5000/v2.0",
        "username": "admin",
        "password": "secrete",
        "tenant_name": "admin"
    }
}" | tee -a /home/stack/rally/existingcloud.json

ADMIN_PASSWORD="secrete"

echo "
[[local|localrc]]
ADMIN_PASSWORD=$ADMIN_PASSWORD
DATABASE_PASSWORD=$ADMIN_PASSWORD
RABBIT_PASSWORD=$ADMIN_PASSWORD
SERVICE_PASSWORD=$ADMIN_PASSWORD
SERVICE_TOKEN=a682f596-76f3-11e3-b3b2-e716f9080d50

# Change the scheduler to something multi-node
SCHEDULER=nova.scheduler.simple.SimpleScheduler

GIT_BASE=${GIT_BASE:-https://git.openstack.org}

# Neutron - Networking Service
# If Neutron is not declared the old good nova-network will be used
disable_service n-net
ENABLED_SERVICES+=,q-svc,q-agt,q-dhcp,q-l3,q-meta,neutron

## Neutron - Load Balancing
ENABLED_SERVICES+=,q-lbaas

## Neutron - VPN as a Service
ENABLED_SERVICES+=,q-vpn

## Neutron - Firewall as a Service
ENABLED_SERVICES+=,q-fwaas

# Neutron Stuff
OVS_VLAN_RANGES=RegionOne:1:4000
OVS_ENABLE_TUNNELING=False

# Heat - Orchestration Service
ENABLED_SERVICES+=,heat,h-api,h-api-cfn,h-api-cw,h-eng

# Ceilometer - Metering Service (metering + alarming)
ENABLED_SERVICES+=,ceilometer-acompute,ceilometer-acentral,ceilometer-collector,ceilometer-api
ENABLED_SERVICES+=,ceilometer-alarm-notify,ceilometer-alarm-eval

# Rally
ENABLED_SERVICES+=.rally

## It would also be useful to automatically download and register VM images that Heat can launch.
# 32bit image (~660MB)
IMAGE_URLS+=",http://fedorapeople.org/groups/heat/prebuilt-jeos-images/F19-i386-cfntools.qcow2"
# 64bit image (~640MB)
IMAGE_URLS+=",http://fedorapeople.org/groups/heat/prebuilt-jeos-images/F19-x86_64-cfntools.qcow2"
IMAGE_URLS+=",http://mirror.chpc.utah.edu/pub/fedora/linux/releases/20/Images/x86_64/Fedora-x86_64-20-20131211.1-sda.qcow2"
IMAGE_URLS+=",http://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-uec.tar.gz"

# Output
LOGFILE=/opt/stack/logs/stack.sh.log
VERBOSE=True
LOG_COLOR=False
SCREEN_LOGDIR=/opt/stack/logs
" | tee -a /home/stack/devstack/local.conf

chown -vR stack:stack /home/stack

sudo su - stack /home/stack/devstack/stack.sh
MASTERSCRIPT

$computenode = <<COMPUTENODE
MY_IP=$(ifconfig eth1 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')

echo "
[[local|localrc]]
ADMIN_PASSWORD=$ADMIN_PASSWORD
DATABASE_PASSWORD=$ADMIN_PASSWORD
RABBIT_PASSWORD=$ADMIN_PASSWORD
SERVICE_PASSWORD=$ADMIN_PASSWORD
SERVICE_TOKEN=a682f596-76f3-11e3-b3b2-e716f9080d50

ENABLED_SERVICES=n-cpu,rabbit,neutron,q-agt

HOST_IP=${MY_IP}
SERVICE_HOST=172.16.0.100
MYSQL_HOST=$SERVICE_HOST
RABBIT_HOST=$SERVICE_HOST
Q_HOST=$SERVICE_HOST
GLANCE_HOSTPORT=$SERVICE_HOST:9292

# Output
LOGFILE=/opt/stack/logs/stack.sh.log
VERBOSE=True
LOG_COLOR=False
SCREEN_LOGDIR=/opt/stack/logs

" | tee -a /home/stack/devstack/local.conf

chown -vR stack:stack /home/stack

sudo su - stack /home/stack/devstack/stack.sh
COMPUTENODE

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  hostname = "devstack"
  
  # Virtual Box
  config.vm.box = "trusty64"
  config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"

  # Rackspace Cloud
  config.vm.provider "rackspace" do |rs, override|
      override.vm.box = "dummy"
      override.vm.box_url = "https://github.com/mitchellh/vagrant-rackspace/raw/master/dummy.box"
      override.ssh.private_key_path = "~/.ssh/id_rsa"
      rs.username        = "e-vad"
      rs.api_key         = "990a15b3bfa545e193574d243710abf0"
      rs.flavor          = /8GB/              # I've fonud this works better with LOTS of ram, like the 30gb instances, but ymmv
      rs.image           = /Ubuntu 14.04/i    # Change as needed
      rs.public_key_path = "~/.ssh/id_rsa.pub"  # Path to your public key, can be omitted if using the generic vagrant ones (don't do that)
      rs.rackspace_region = :dfw # things like :dfw and :ord
  end


  # VMware Fusion
  config.vm.provider "vmware_fusion" do |vmware, override|
    override.vm.box = "trusty64_fusion"
    override.vm.box_url = "https://oss-binaries.phusionpassenger.com/vagrant/boxes/latest/ubuntu-14.04-amd64-vmwarefusion.box"  
#    override.vm.synced_folder ".", "/vagrant", type: "nfs"

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
          box.vm.provision :shell, :inline => "sudo apt-get update && sudo apt-get install -y vim wget git curl screen kvm libvirt-bin virtinst"
          box.vm.provision :shell, :inline => "sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\" dist-upgrade"
          if prefix == "controller"
            box.vm.provision :shell, path: "./cell-00.sh"
          elsif prefix == "devstack"
            box.vm.provision :shell, path: "./child.sh"
          end
        end
      end
    end
end
