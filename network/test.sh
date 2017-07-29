#!/bin/bash

#echo "dhcp-server-$1"
if [ $# -ne 1 ]
then
    echo "no parameter is given"
    #exit 0
fi

function validate_ip
{
  
  if [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "success"
    CN1=`echo $1 | cut -d . -f 1`
    CN2=`echo $1 | cut -d . -f 2`
    CN3=`echo $1 | cut -d . -f 3`
    CN4=`echo $1 | cut -d . -f 4`
    echo "CN1: $CN1" $'\n\n\n'
  else
    echo "fail"
  fi
}

#validate_ip $1

cat > network.xml <<EOF

 " remove "

EOF
