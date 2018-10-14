#!/bin/bash
#SBATCH -J JOBNAME	
#SBATCH -o %A_%a.o				
#SBATCH -e %A_%a.e				
#SBATCH -N 1			
#SBATCH -n 16               			
#SBATCH --array=1-TOTAL%30 			
#SBATCH --parsable

# source config and function files
source-config

gen-slurm-report

#input file to be processed
input_file=$(fetch-input $SLURM_ARRAY_TASK_ID g16_inp.txt)

#name of molecule and out/err files
title="${input_file/.com/}"
log=$title.log

# execute job
timeout TIME time g16 $input_file
timeout_status=$?

# rename .o and .e files
rename-slurm-outputs $SLURM_ARRAY_TASK_ID $title

# termination status (opt successful if termination=1, opt & freq successful if termination=2)
termination=$(grep 'Normal termination' $log | wc -l)

# end of job preparation for next submissions
if [ $timeout_status -eq 124 ]; then		# if the run times out

	# move files to timeouts directory 
	mv $title* resubmits/
	cd resubmits/
	
	# submit restart calc
	bash $FLOW_TOOLS/scripts/restart-opt.sh $input_file
	setup-sbatch $input_file $FLOW_TOOLS/templates/dft-opt_g16_sbatch_re.txt
	sbatch $title.sbatch
		
elif [ $termination -eq 1 ]; then		# if the run terminated successfully

	# move files to completed directory
	mv $title* completed/
	cd completed/
	to-all-logs $log
	setup-freq $log
	exit 0

else
	# move files to failed directory
	mv $title* failed_opt/
	exit 1
fi
