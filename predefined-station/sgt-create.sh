#!/bin/bash

POOL=nfv
POOL_PATH=/home/nfv

IMG_NAME=ubuntu-14.04-server-cloudimg-amd64-disk1.img
VROOTDISKSIZE=5

METADATA_VNF1="instance-id: iid-vnf1;
network-interfaces: |
  auto eth0
  iface eth0 inet dhcp
  auto eth1
  iface eth1 inet static
  address 192.168.1.10
  netmask 255.255.255.0

hostname: vnf1
local-hostname: vnf1"

USERDATA_VNF1="#cloud-config

password: password
chpasswd: { expire: False }
ssh_pwauth: True
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwnRe5EKCaecMsbHajWYcPpw/GaBQVEWdc7W/xzKq28MFoYDqFfLsZK0OS+fI3rWsYe91ewOcEe8LBzFkwsfyXpgJwhwVGshUl6b2OW97XrXXBWE52hJ20MJzCe7VgLLQBLdFQfumzMwcn71MYiJ1B5tsGJ2JBhd0bh3k6m6JiLpoHrTKI1yXGtwk+wIJyWTxGOMP0eQesf38YWGUvrfsEoa2US1pvjrHJEALWf8Svp6RryMA2mbyx9NoMqV883JN3TJuvDGOqnn3kodli6Ebah8vcqB/cw6v2gE8ZxQbOUsuykhqoHYoZ1OJ9SRdyG66778dCLxpauiUHAUAk0kjj alioune@foutatoro

# run commands
runcmd:

  - [ sh, -c, \"apt-get install update\" ]
  - [ sh, -c, \"ip route add 192.168.0.0/16 via 192.168.1.20\" ]
"

METADATA_VNF3="instance-id: iid-vnf3;
network-interfaces: |
  auto eth0
  iface eth0 inet dhcp
  auto eth1
  iface eth1 inet static
  address 192.168.2.30
  netmask 255.255.255.0
  auto eth2
  iface eth2 inet static
  address 192.168.3.30
  netmask 255.255.255.0

hostname: vnf3
local-hostname: vnf3"

USERDATA_VNF3="#cloud-config

password: password
chpasswd: { expire: False }
ssh_pwauth: True
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwnRe5EKCaecMsbHajWYcPpw/GaBQVEWdc7W/xzKq28MFoYDqFfLsZK0OS+fI3rWsYe91ewOcEe8LBzFkwsfyXpgJwhwVGshUl6b2OW97XrXXBWE52hJ20MJzCe7VgLLQBLdFQfumzMwcn71MYiJ1B5tsGJ2JBhd0bh3k6m6JiLpoHrTKI1yXGtwk+wIJyWTxGOMP0eQesf38YWGUvrfsEoa2US1pvjrHJEALWf8Svp6RryMA2mbyx9NoMqV883JN3TJuvDGOqnn3kodli6Ebah8vcqB/cw6v2gE8ZxQbOUsuykhqoHYoZ1OJ9SRdyG66778dCLxpauiUHAUAk0kjj alioune@foutatoro

# run commands
runcmd:

  - [ sh, -c, \"apt-get install update\" ]
  - [ sh, -c, \"ip route add 192.168.1.0/24 via 192.168.2.20\" ]
  - [ sh, -c, \"echo 1 >> /proc/sys/net/ipv4/ip_forward \" ]
"


## Check if the pool directory exists
if [ ! -e ${POOL_PATH} ]; then
  sudo mkdir /home/nfv
  sudo virsh pool-define-as --name ${POOL} --type dir --target ${POOL_PATH}
  sudo virsh pool-autostart ${POOL}
  sudo virsh pool-build ${POOL}
  sudo virsh pool-start ${POOL}
fi

function create_metadata_vnf1()
{
  cat > meta-data <<EOF
$METADATA_VNF1
EOF
}


function create_userdata_vnf1()
{
  cat > user-data <<EOF
$USERDATA_VNF1
EOF

}

function create_metadata_vnf3()
{
  cat > meta-data <<EOF
$METADATA_VNF3
EOF
}


function create_userdata_vnf3()
{
  cat > user-data <<EOF
$USERDATA_VNF3
EOF

}

## Create networks
sh create-networks.sh

## VNF1 configuration
create_metadata_vnf1
create_userdata_vnf1
sudo genisoimage -output confvnf1.iso -volid cidata -joliet -rock user-data meta-data
sudo mv confvnf1.iso $POOL_PATH
sudo virsh vol-clone --pool ${POOL} ${IMG_NAME} vnf1.img


## VNF3 configuration
create_metadata_vnf3
create_userdata_vnf3
sudo genisoimage -output confvnf3.iso -volid cidata -joliet -rock user-data meta-data
sudo mv confvnf3.iso $POOL_PATH
sudo virsh vol-clone --pool ${POOL} ${IMG_NAME} vnf3.img

sudo virsh pool-refresh $POOL

true &> /dev/null | sudo virt-install -r 512     \
  -n vnf1     \
  --vcpus=1    \
  --autostart  \
  --memballoon virtio    \
  --boot hd     \
  --graphics none \
  --network network=default \
  --network network=net1 \
  --disk vol=$POOL/vnf1.img,format=qcow2,bus=virtio  \
  --disk vol=$POOL/confvnf1.iso,bus=virtio


true &> /dev/null | sudo virt-install -r 512     \
  -n vnf3     \
  --vcpus=1    \
  --autostart  \
  --memballoon virtio    \
  --boot hd     \
  --graphics none \
  --network network=default \
  --network network=net2 \
  --network network=net3 \
  --disk vol=$POOL/vnf3.img,format=qcow2,bus=virtio  \
  --disk vol=$POOL/confvnf3.iso,bus=virtio

## Configure VNF2

sudo docker create -it --cap-add=NET_ADMIN --name=vnf2 --net=none ubuntu-ads
sudo docker start vnf2

sudo ip link add veth20 type veth peer name eth0-vnf2
sudo ip link add veth21 type veth peer name eth1-vnf2
sudo ip link add veth22 type veth peer name eth2-vnf2
sudo ip link set veth20 up
sudo ip link set veth21 up
sudo ip link set veth22 up
sudo ip link set eth0-vnf2 up
sudo ip link set eth1-vnf2 up
sudo ip link set eth2-vnf2 up

PID=`sudo docker inspect -f '{{.State.Pid}}' vnf2`
sudo ln -s /proc/$PID/ns/net /var/run/netns/$PID

sudo ip link set eth0-vnf2 netns $PID
sudo brctl addif virbr0 veth20
sudo ip netns exec $PID ifconfig eth0-vnf2 up


sudo ip link set eth1-vnf2 netns $PID
sudo ip netns exec $PID ifconfig eth1-vnf2 192.168.1.20/24 up
sudo ovs-vsctl add-port br-net1 veth21

sudo ip link set eth2-vnf2 netns $PID
sudo ip netns exec $PID ifconfig eth2-vnf2 192.168.2.20/24 up
sudo ovs-vsctl add-port br-net2 veth22

## Add routes for VNF2
sudo ip netns exec $PID ip route add 192.168.3.0/24 via 192.168.2.30


## Configure VNF4

sudo docker create -it --cap-add=NET_ADMIN --name=vnf4 --net=none ubuntu-ads
sudo docker start vnf4

sudo ip link add veth40 type veth peer name eth0-vnf4
sudo ip link add veth41 type veth peer name eth1-vnf4
sudo ip link set veth40 up
sudo ip link set veth41 up
sudo ip link set eth0-vnf4 up
sudo ip link set eth1-vnf4 up

PID=`sudo docker inspect -f '{{.State.Pid}}' vnf4`
sudo ln -s /proc/$PID/ns/net /var/run/netns/$PID

sudo ip link set eth0-vnf4 netns $PID
sudo ip netns exec $PID ifconfig eth0-vnf4 up
sudo brctl addif virbr0 veth40

sudo ip link set eth1-vnf4 netns $PID
sudo ovs-vsctl add-port br-net3 veth41
sudo ip netns exec $PID ifconfig eth1-vnf4 192.168.3.40/24 up


## Add routes for VNF4
sudo ip netns exec $PID ip route add 192.168.0.0/16 via 192.168.3.30

sudo rm meta-data
sudo rm user-data
echo "Printing VNFs ...."
sudo virsh list
sudo docker ps

