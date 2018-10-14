#!/bin/bash

# script which adds properties to input sdf file

sdf_file=$1
property=$2
value=$3

obabel -i sdf $sdf_file -o sdf -O $sdf_file --property $property $value 2>/dev/null
