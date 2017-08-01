#!/bin/bash

sudo virsh destroy vnf1
sudo virsh undefine vnf1

sudo virsh destroy vnf3
sudo virsh undefine vnf3

sudo docker stop vnf2
sudo docker rm vnf2

sudo docker stop vnf4
sudo docker rm vnf4

~/openvim/network/net-del.sh net1
~/openvim/network/net-del.sh net2
~/openvim/network/net-del.sh net3
