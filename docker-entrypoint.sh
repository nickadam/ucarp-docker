#!/bin/bash

# check vars
if [ -z "$VIP" ] || [ -z "$HOST_IP" ]
then
  echo "Set VIP and HOST_IP environment vars"
  exit 1
fi

# get the interface name if not set
test ! -z "$DEV_NAME" || DEV_NAME=$(ip a \
  | grep -e "^[^ ]" -e inet\ "$(echo $HOST_IP | sed 's/\./\\./g')" \
  | egrep -B 1 "^ +inet" \
  | head -n 1 \
  | awk '{print $2}' \
  | awk -F @ '{print $1}' \
  | awk -F : '{print $1}')

if [ -z "$DEV_NAME" ]
then
  echo "Failed to find interface name for $HOST_IP"
  exit 1
fi

# get the CIDR number
test ! -z "$CIDR" || CIDR=$(ip a \
  | grep inet\ "$(echo $HOST_IP | sed 's/\./\\./g')" \
  | awk -F / '{print $2}' \
  | awk '{print $1}')

if [ -z "$CIDR" ]
then
  echo "Failed to CIDR for $HOST_IP"
  exit 1
fi

export CIDR

# set default VHID and PASSWORD if not set
test ! -z "$VHID" || VHID=10
test ! -z "$PASSWORD" || PASSWORD=ucarp

CONTAINER_NAME="ucarp-$(hostname)-$VHID"

# run ucarp container with NET_ADMIN
docker run --rm \
  --name $CONTAINER_NAME \
  --network=host \
  --cap-add=NET_ADMIN \
  --entrypoint tini \
  --env CIDR=${CIDR} \
  nickadam/ucarp-docker:v1.0.0 \
  -- ucarp --interface=${DEV_NAME} \
    --srcip=${HOST_IP} \
    --vhid=${VHID} \
    --pass=${PASSWORD} \
    --addr=${VIP} \
    --upscript=/vip-up.sh \
    --downscript=/vip-down.sh \
    --shutdown &

trap "docker stop $CONTAINER_NAME; exit" TERM

wait
