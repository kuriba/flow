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
ls "$log_file" &>/dev/null
if ! [ $? -eq 0 ] ; then
	echo "error: $log_file not found in current directory"
	exit 1
fi

allcheck=$(grep -ic 'geom=allcheck' "$com_file")
termination=$(grep -c 'Normal termination' "$log_file")
error_term=$(grep -c 'Error termination' "$log_file")
convergence_fail=$(grep -c 'Convergence failure -- run terminated.' "$log_file")
route=$(grep '#' "$com_file")

if [[ "$error_term" -eq 1 ]] && [[ "$convergence_fail" -eq 0 ]]; then
	exit 1
fi

function restart_convergence_fail {
	local com_file=$1
	local opt_keyword=$(get_opt_keyword "$com_file")
	local opt_options=$(get_opt_options "$com_file")
	local has_calcfc=$(echo $opt_options | grep -c "calcfc")
	local has_restart=$(echo $opt_options | grep -c "restart")

	if [[ "$has_calcfc" -eq 1 ]] && [[ "$has_restart" -eq 1 ]]; then
		echo "[$name] already setup for convergence failure restart"
		exit 0
	elif [[ "$has_restart" -eq 1 ]]; then
		restart_opt="opt=($opt_options,calcfc)"
	else
		restart_opt="opt=($opt_options,restart,calcfc)"
		remove_coord_charge_mult $com_file
	fi
	
	sed -i "s|$opt_keyword|$restart_opt|" "$com_file"
	exit 0

	echo "successfully setup [$name] for convergence failure restart"
}

function remove_coord_charge_mult {
	local com_file=$1
	sed -i '/[0-9] [0-9]/,$d' "$com_file"	
}

function get_opt_options {
	local com_file=$1
	local opt_keyword=$(get_opt_keyword $com_file)     # get 'opt' keyword with options
    local opt_options="${opt_keyword#*=}"               # get 'opt' options
    local opt_options="${opt_options/\(/}"            # remove '(' from options
    local opt_options="${opt_options/\)/}"            # remove ')' from options
	echo $opt_options
}

function get_opt_keyword {
	local com_file=$1
	local route=$(grep '#' "$com_file")
	local opt_keyword=$(echo "$route" | awk '/opt/' RS=" ")
	echo $opt_keyword
}

if [[ "$convergence_fail" -eq 1 ]]; then
	restart_convergence_fail $com_file
	exit 0
fi	

if [[ "$termination" -eq 0 ]]; then
	if [[ "$allcheck" -eq 0 ]]; then
		# remove coordinates, set opt=restart, geom=allcheck, guess=read
		opt_keyword=$(echo "$route" | awk '/opt/' RS=" ")     # get 'opt' keyword with options
		has_options=$(echo "$opt_keyword" | grep -c '=')    # check for options following 'opt' keyword
		has_restart_option=$(echo "$opt_keyword" | grep -c 'restart')
		opt_options="${opt_keyword#*=}"               # get 'opt' options
		opt_options="${opt_options/\(/}"            # remove '(' from options
		opt_options="${opt_options/\)/}"            # remove ')' from options	

		if [[ "$has_restart_option" -eq 1 ]] && [[ "$convergence_fail" -eq 0 ]]; then
			echo "[$name] already setup for restart"
			exit 0
		fi
		
		# add geom=allcheck and guess=read
		if [[ "$all_check" -eq 0 ]] && [[ "$has_restart_option" -eq 0 ]] ; then
			if [[ "$has_options" -eq 1 ]]; then
				restart_opt="opt=($opt_options,restart) geom=allcheck guess=read"
			else
				restart_opt="opt=restart geom=allcheck guess=read"
			fi
		fi

		sed -i "s|$opt_keyword|$restart_opt|" "$com_file"

		# remove coordinates and charge/multiplicity
		sed -i '/[0-9] [0-9]/,$d' "$com_file"

		echo "successfully setup [$name] for opt restart"
	fi
fi

