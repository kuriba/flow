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

allcheck=$(grep -ic 'geom=allcheck' $com_file)
termination=$(grep -c 'Normal termination' $log_file)
error_term=$(grep -c 'Error termination' $log_file)
route=$(grep '#' $com_file)

if [ $termination -eq 0 ] && [ $allcheck -eq 0 ] && [ $error_term -eq 0 ]; then
	# remove coordinates, set opt=restart, geom=allcheck, guess=read
    opt_keyword=$(awk '/opt/' RS=" " $com_file)     # get 'opt' keyword with options
	echo $opt_keyword
    options_exist=$(echo $opt_keyword | grep -c '=')    # check for options following 'opt' keyword
	restart_option_exists=$(echo $opt_keyword | grep -c 'restart')
    opt_options="${opt_keyword#*=}"               # get 'opt' options
    opt_options="${opt_options/\(/}"            # remove '(' from options
	opt_options="${opt_options/\)/}"            # remove ')' from options	
	
	# d
	if [ $restart_option_exists -eq 1 ]; then
		exit 0
	fi	

    if [ $options_exist -eq 1 ]; then
        restart_opt=$(echo "opt=($opt_options,restart)")
        sed -i "s/$opt_keyword/opt=($opt_options,restart)/" $com_file
    else
        restart_opt=$(echo "opt=restart")
        sed -i "s/$opt_keyword/$restart_opt/" $com_file
    fi
 
    # add geom=allcheck and guess=read to route
    sed -i '/#/s/$/ geom=allcheck guess=read/' $com_file
    # remove coordinates and charge/multiplicity
    sed -i '/[0-9] [0-9]/,$d' $com_file
 
	echo "successfully setup [$name] for opt restart"
fi
