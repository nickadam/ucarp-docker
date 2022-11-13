#!/bin/bash

ip addr add ${2}/${CIDR} dev ${1}
