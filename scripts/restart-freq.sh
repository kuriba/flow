#!/bin/bash

# script for automatically setting up G16 opt input file for resubmission based on job progress

# make sure input file is provided
if [[ $# -eq 0 ]]; then
    echo 'error: no input file provided'
    exit 1
fi

com_file=$1
name="${com_file/.com/}"
log_file=$name.log

# make sure log file is in the same directory
ls $log_file &>/dev/null
if ! [ $? -eq 0 ] ; then
	echo "error: $log_file not found in current directory"
	exit 1
fi

termination=$(grep -c 'Normal termination' $log_file)
error_term=$(grep -c 'Error termination' $log_file)
route=$(grep '#' $com_file)
freq_restart=$(echo $route | grep -ic '# restart')

if [ $error_term -eq 0 ] && [ $freq_restart -eq 0 ] && [ $termination -eq 0 ]; then
	# replace route with '# Restart'	
	sed -i "s|$route|# Restart|" $com_file	

	# remove coordinates and charge/multiplicity
	sed -i '/[0-9] [0-9]/,$d' $com_file
fi
