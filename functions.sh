#!/bin/bash

function upsearch {
    local cur_dir=$PWD
    test / == "$PWD" && return || test -e "$1" && echo "$PWD" && return || cd .. && upsearch "$1"
    cd $cur_dir
}

function source-config {
    local cur_dir=$PWD
    local main_dir=$(upsearch flow-tools)
    cd $main_dir
	. "flow-tools/config.sh"
    wait
    cd $cur_dir
}

function gen-slurm-report {
	printf "%-20s %-15s\n" "CLUSTER" "$SLURM_CLUSTER_NAME"
	printf "%-20s %-15s\n" "SLURM_JOB_ID" "$SLURM_JOB_ID"
	printf "%-20s %-15s\n" "SLURM_ARRAY_JOB_ID" "$SLURM_ARRAY_JOB_ID"
	printf "%-20s %-15s\n" "SLURM_ARRAY_TASK_ID" "$SLURM_ARRAY_TASK_ID"
	printf "%-20s %-15s\n" "PARTITION" "$SLURM_JOB_PARTITION"
	printf "%-20s %-15s\n" "JOBNAME" "$SLURM_JOB_NAME"
	printf "%-20s %-15s\n" "SLURM_JOB_NODELIST" "$SLURM_JOB_NODELIST"
	printf "%-20s %-15s\n" "Groups" "$(groups)"
	printf "%-20s %-15s\n" "Submission time" "$(date +"%H:%M:%S | %b %d %y")"
}

# function which sets up an sbatch email for the given job id
# use: email-sbatch <title> <jobid>
# effect: submits a job which waits until the job with the given id completes, then sends an email
function email-sbatch {
	local title=$1 # title of the job
	local jobid=$2 # job-id which you would like to be notified about
	sed "s/JOBID/$jobid/g" $FLOW_TOOLS/templates/email.sbatch | sed "s/EMAIL/$DEFAULT_EMAIL/g" | sed "s/JOBNAME/$title/g" | sed "s/PARTITION/$DEFAULT_PARTITION/g" | sbatch 1>/dev/null
}

# function which submits an array of input files
# use: submit-array <array_title> <inp_file_list> <inp_file_type> <partition> <sbatch_file>
# effect: submits an array of jobs
function submit-array {
	local array_title=$1
	local inp_file_list=$2
	local inp_file_type=$3
	local sbatch_file=$4
	local calc_time=$5

	# remove existing list of input files
	rm "$inp_file_list" 2>/dev/null

	# create list of input files
	ls *."$inp_file_type" >> "$inp_file_list"

	# number of files in the array
	local numfiles=$(wc -l <$inp_file_list)

	# substitute ARRAY_TITLE with name of super-directory and TOTAL with the number of files
	# in the array then submit sbatch
	local jobid=$(sed "s/JOBNAME/$array_title/g" $sbatch_file | sed "s/TOTAL/$numfiles/g" | sed "s/TIME/$calc_time/" | sbatch)
	wait

	# submit separate sbatch for array email
	email-sbatch $array_title $jobid
	wait

	echo $jobid
}

# function which renames slurm array output files
# use: rename-slurm-outputs <id> <title>
# effect: renames output and error files
function rename-slurm-outputs {
	local id=$1
	local title=$2
	mv *"_$id.o" $title.o
	mv *"_$id.e" $title.e
}

# function which fetches the line number from the given file matching the given slurm array task id
# use: fetch-input <id> <file>
# effect: echoes the name of the input file
function fetch-input {
	local id=$1
	local file=$2
	local input_file=$(sed -n "$id"p $file | cut -f 1 -d '.')
	echo $input_file
}

# job completion handlers

# basic job handler (only checks for completed or failed and moves files accordingly)
# use: basic-job-handler <title> <termination>
# effect moves all files beginning with the given title into the completed or failed directory
function basic-job-handler {
	local title=$1
	local termination=$2
	if [ $termination -ge 1 ]; then # if the run terminated successfully
		mv $title* completed/
		exit 0
	else # if the run fails
		mv $title* failed/
		exit 1
	fi
}

# creates an xyz file by extracting coordinates from the given log file
# use: pull-xyz-geom <log>
# effect: creates an xyz file with the same name as the log file
function pull-xyz-geom {
	local log=$1
	local title="${log/.log/}"
	local xyz=$title.xyz
	local charge=$(grep 'Charge =' $log | awk '{print $3}')
	local mult=$(grep 'Charge =' $log | awk '{print $6}')
	local geom=$(grep -ozP '(?s)\\\\'"$charge"",""$mult"'\\\K.*?(?=\\\\Version)' $log |
		sed 's/ //g' | tr -d '\n')
	local IFS='\' read -r -a coords <<<"$geom"
	echo ${#coords[@]} >$xyz
	echo $title >>$xyz
	printf '%s\n' "${coords[@]}" | sed 's/,/\t\t/g' >>$xyz
}

# draws a progress bar for a for loops given the barsize and length of the loop
# use: progress-bar <barsize> <base> <current> <total>
# effect: prints a progress bar as the for loop runs
function progress-bar {
	local barsize=$1
	local base=$2
	local current=$3
	local total=$4
	local j=0
	local progress=$((($barsize * ($current - $base)) / ($total - $base)))
	echo -n "["
	for ((j = 0; j < $progress; j++)); do echo -n '='; done
	echo -n '=>'
	for ((j = $progress; j < $barsize; j++)); do echo -n ' '; done
	echo -n "] $(($current)) / $total " $'\r'
}

# finds the given directory by inverse recursion
# use: upsearch <file or directory name>
# effect: echoes the directory of the found file
function upsearch {
	local cur_dir=$PWD
	test / == "$PWD" && return || test -e "$1" && echo "$PWD" && return || cd .. && upsearch "$1"
	cd $cur_dir
}

# sets up the given $file for restart, intended for PM7 optimization
# use: pm7-restart <com file>
# effect: modifies the input file by changing the route and deleting the coordinates
function pm7-restart {
	local file=$1
	local route=$(grep '#' $file)
	sed -i '/[0-9] [0-9]/,$d' $file
	sed -i "s/$route/#p pm7 opt=calcfc geom=allcheck/" $file
}

# sets up sbatch script for given .com file and sbatch template
# use: setup-sbatch <com file> <sbatch template>
# effect: copies a new sbatch file to the current directory and substitutes the placeholders
function setup-sbatch {
	local input=$1
	local sbatch_template=$2

	local batch_file="${input/.com/.sbatch}"
	local title="${input/.com/}"

	cp $sbatch_template $batch_file
	sed -i "s/JOBNAME/$title/g" $batch_file
	sed -i "s/PARTITION/$DEFAULT_PARTITION/g" $batch_file
	sed -i "s/EMAIL/$DEFAULT_EMAIL/g" $batch_file
}

# sets up frequency calculation from geometry from given log file
# use: setup-freq <log file>
# effect: creates an input and sbatch file for a frequency job and submits it
function setup-freq {
	local log_file=$1
	local route=$(grep "#" $log_file | head -1)
	local opt_keyword=$(echo $route | awk '/opt/' RS=" ")
	local charge=$(grep 'Charge =' $log_file | awk '{print $3}')
    local mult=$(grep 'Charge =' $log_file | awk '{print $6}')
	local freq="${log_file/.log/_freq}"
	local new_route=$(echo $route | sed "s|$opt_keyword|freq=noraman|")

	# set up freq job
	bash $FLOW_TOOLS/scripts/make-com.sh -f -i=$log_file -r="$new_route" -c=$charge -s=$mult -t=$freq -l="../freq_calcs/"
	cd "../freq_calcs/"

	# set up sbatch
	cp $FLOW_TOOLS/templates/freq_sbatch.txt $freq.sbatch
	sed -i "s/JOBNAME/$freq/g" $freq.sbatch
	sed -i "s/DEFAULT_EMAIL/$DEFAULT_EMAIL/" $freq.sbatch
	sed -i "s/TIME/$DFT_TIME/" $freq.sbatch
	sbatch $freq.sbatch

	cd "../completed/"
}

function to-all-logs {
	local log_file=$1
	cp $log_file $ALL_LOGS
}

function submit-all-dft-opts {
	local inchi_key=$1
	for d in $S0_SOLV $S1_SOLV $T1_SOLV $CAT_RAD_VAC $CAT_RAD_SOLV; do
		cd $d && sbatch $inchi_key*sbatch;
	done
}
