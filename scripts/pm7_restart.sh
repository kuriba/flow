#!/bin/bash

# .com file to restart
file=$1

route=$(grep '#' $file)
sed -i '/[0-9] [0-9]/,$d' $file
sed -i "s/$route/#p pm7 opt=calcfc geom=allcheck/" $file
