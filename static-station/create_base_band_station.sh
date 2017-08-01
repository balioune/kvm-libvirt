#!/bin/bash

sudo mkdir /home/nfv
POOL=nfv
POOL_PATH=/home/nfv

##Create pool of volumes that will be allowated to KVM VNF
sudo virsh pool-define-as --name ${POOL} --type dir --target ${POOL_PATH}
sudo virsh pool-autostart ${POOL}
sudo virsh pool-build ${POOL}
sudo virsh pool-start ${POOL}

genisoimage -output confvnf1.iso -volid cidata -joliet -rock user-data meta-data
#change the meta-data file 
genisoimage -output confvnf2.iso -volid cidata -joliet -rock user-data meta-data
sudo cp confvnf1.iso confvnf1.iso $POOL_PATH
virsh pool-refresh $POOL

IMG_NAME=ubuntu-14.04-server-cloudimg-amd64-disk1.img
VROOTDISKSIZE=5
## VNF1 disk
virsh vol-clone --pool ${POOL} ${IMG_NAME} vnf1.img
virsh vol-resize --pool ${POOL} vnf1.img ${VROOTDISKSIZE}

## VNF3 disk
virsh vol-clone --pool ${POOL} ${IMG_NAME} vnf3.img
virsh vol-resize --pool ${POOL} vnf3.img ${VROOTDISKSIZE}


## Activate ip forward option in /proc/sys/net/ipv4/ip_forward in KVM VNF
sudo virt-install -r 512     \
  -n vnf1     \
  --vcpus=1    \
  --autostart  \
  --memballoon virtio    \
  --boot hd     \
  --disk vol=vm/vnf1.img,format=qcow2,bus=virtio  \
  --disk vol=vm/confvnf1.iso,bus=virtio



sudo virt-install -r 512     \
  -n vnf3     \
  --vcpus=1    \
  --autostart  \
  --memballoon virtio    \
  --network network=net2 --network network=net3 --network network=default\
  --boot hd     \
  --disk vol=vm/vnf3.img,format=qcow2,bus=virtio  \
  --disk vol=vm/confvnf3.iso,bus=virtio

## VNF2

sudo docker create -it --cap-add=NET_ADMIN --name=vnf2 --net=none xenial-ads
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
sudo ovs-vsctl add-port br-net1 veth20

sudo ip link set eth1-vnf2 netns $PID
sudo ovs-vsctl add-port br-net2 veth21

sudo ip link set eth2-vnf2 netns $PID
sudo brctl addif virbr0 veth22


## VNF4

sudo docker create -it --cap-add=NET_ADMIN --name=vnf4 --net=none xenial-ads
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
sudo ovs-vsctl add-port br-net3 veth40


sudo ip link set eth1-vnf4 netns $PID
sudo brctl addif virbr0 veth41

## Display VNFs
for i in `sudo virsh list`
  sudo virsh domiflist vnf1
  cat /dhcp file

echo "Displaying Virtual Network Functions ..."
for vnf_name in `sudo virsh list | awk '{print $2}'`  
do
  if [ $vnf_name != "Name" ]
  then
    echo "Printing MAC addresses of $vnf_name"
    mac_address=`sudo virsh domiflist $vnf_name | awk '{print $5}'` 
    for mac_address in `sudo virsh domiflist $vnf_name | awk '{print $5}'`
    do
      if [ $mac_address != "MAC" ]
      then
        echo " $mac_address"
        sudo cat /var/lib/misc/dnsmasq.leases |grep $mac_address
      fi
    done
  fi
done


## ADD route

## VNF1
sudo ip route add 192.168.0.0/16 via $IP_VNF2

## VNF2
sudo ip route add 192.168.3.0/24 via $IP_VNF3

## VNF3
sudo ip route add 192.168.1.0/24 via $IP_VNF2

## VNF4
sudo ip route add 192.168.0.0/16 via $IP_VNF3


