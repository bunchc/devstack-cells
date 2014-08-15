## Cell-0
#### Prep Environment
sudo adduser --disabled-password --gecos "" stack
echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
git clone -b stable/icehouse https://github.com/openstack-dev/devstack.git /home/stack/devstack/

MY_IP=$(ifconfig eth1 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
CONTROLLER_IP=$1

echo "
[[local|localrc]]
ADMIN_PASSWORD=$ADMIN_PASSWORD
DATABASE_PASSWORD=$ADMIN_PASSWORD
RABBIT_PASSWORD=$ADMIN_PASSWORD
SERVICE_PASSWORD=$ADMIN_PASSWORD
SERVICE_TOKEN=a682f596-76f3-11e3-b3b2-e716f9080d50

HOST_IP=${MY_IP}
SERVICE_HOST=${CONTROLLER_IP}
MYSQL_HOST=$SERVICE_HOST
RABBIT_HOST=$SERVICE_HOST
Q_HOST=$SERVICE_HOST
GLANCE_HOSTPORT=$SERVICE_HOST:9292

GIT_BASE=${GIT_BASE:-https://git.openstack.org}

# Cells!
ENABLED_SERVICES+=,n-cell
DISABLED_SERVICE+=,n-api,key,g-api

# Neutron - Networking Service
# If Neutron is not declared the old good nova-network will be used
ENABLED_SERVICES+=,q-svc,q-agt,q-dhcp,q-l3,q-meta,neutron,q-lbaas,q-vpn,q-fwaas

# Neutron Stuff
OVS_VLAN_RANGES=RegionOne:1:4000
OVS_ENABLE_TUNNELING=False

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