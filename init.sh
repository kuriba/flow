#!/bin/bash

# This script will modify the .bashrc file to add the $FLOW environment variable and 
# source functions necessary for the workflow. The location of the .bashrc file is 
# assumed to be ~/.bashrc; if this is not the case, specify the correct location below.

bashrc_source=~/.bashrc

# ensure .bashrc exists
if [ ! -f "$bashrc_source" ]; then
	echo "Error: .bashrc not found at $bashrc_source"
	exit 1
fi

utils_header='# VERDE Materials DB workflow utils'
# do not modify .bashrc if already modified
if [ $(grep -c "$utils_header" "$bashrc_source") -ge 1 ]; then
	echo "VERDE workflow already initialized."
	exit 0
fi

# modify .bashrc
FLOW=$(pwd)
echo -e "$utils_header\nexport FLOW=$FLOW\nset -a; source $FLOW/functions.sh; set +a\n" >> "$bashrc_source"
echo "Successfully initialized VERDE workflow variables."
