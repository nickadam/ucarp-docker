#!/bin/bash

ip addr delete ${2}/${CIDR} dev ${1}
