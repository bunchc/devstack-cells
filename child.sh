## Cell-0
#### Prep Environment
sudo adduser --disabled-password --gecos "" stack
echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
git clone -b stable/icehouse https://github.com/openstack-dev/devstack.git /home/stack/devstack/

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

GIT_BASE=${GIT_BASE:-https://git.openstack.org}

# Cells!
ENABLED_SERVICES+=,n-cell
DISABLED_SERVICE+=,n-api,key,g-api

# Neutron - Networking Service
# If Neutron is not declared the old good nova-network will be used
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

echo "
[cells]
enable=True
name=cell1
cell_type=compute
" | sudo tee -a /etc/nova/nova.conf