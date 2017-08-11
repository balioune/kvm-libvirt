#!/bin/bash

POOL=nfv
POOL_PATH=/home/nfv

echo "Deleting VNF1 and VNF3"
sudo virsh destroy vnf1
sudo virsh undefine vnf1

sudo virsh destroy vnf3
sudo virsh undefine vnf3

echo "Deleting KVM disks "
sudo rm /home/nfv/confvnf1.iso
sudo rm /home/nfv/vnf1.img

sudo rm /home/nfv/confvnf3.iso
sudo rm /home/nfv/vnf3.img

sudo virsh pool-refresh $POOL

sudo virsh vol-list --pool $POOL

## Delete networks
sh delete-networks.sh

echo "Deleting VNF2 and VNF4"

PID=`sudo docker inspect -f '{{.State.Pid}}' vnf2`
sudo docker stop vnf2
sudo docker rm vnf2
sudo ip netns del $PID

PID=`sudo docker inspect -f '{{.State.Pid}}' vnf4`
sudo docker stop vnf4
sudo docker rm vnf4
sudo ip netns del $PID


echo "Printing VNFs ...."
sudo virsh list --all
sudo docker ps -a
