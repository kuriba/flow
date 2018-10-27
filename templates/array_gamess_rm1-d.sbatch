#!/bin/bash
#SBATCH -J JOBNAME
#SBATCH -o %A_%a.o
#SBATCH -e %A_%a.e
#SBATCH -N 1
#SBATCH -n 16
#SBATCH --array=1-TOTAL%50
#SBATCH --parsable

# source config and function files
source_config

gen_slurm_report

#input file to be processed
input_file=$(fetch_input $SLURM_ARRAY_TASK_ID "gamess_inp.txt")

#name of molecule and out/err files
title="${input_file/.inp/}"
out=$title.o

# remove existing scratch files
rm $scratch/gamess_scratch/$title*
rm $scratch/gamess_scratch/scr/$title*

# execute job
time $FLOW/utils/rungms $input_file

# rename .o and .e files
rename_slurm_outputs $SLURM_ARRAY_TASK_ID $title

# termination status (successful if termination=1)
termination=$(grep 'TERMINATED NORMALLY' $out | wc -l)

# end of job preparation for next submissions
if [ $termination -eq 1 ]; then		# if the run terminated successfully

	# move files to completed directory and discard scratch files
	mv $title* $RM1_D/completed/
	rm $scratch/gamess_scratch/scr/$title*
	
	# make pdb file of RM1-D optimized structure
	cd $RM1_D/completed/
	obabel -igam $title.o -opdb -O $title.pdb &>/dev/null
	mv $title.pdb ../opt_pdbs

	# make SP-DFT .com input file
	cd $RM1_D/opt_pdbs/
	bash $FLOW_TOOLS/scripts/make-com.sh -i=$title.pdb -r='#p M06/6-31+G(d,p)' -t=$title\_sp -l=$SP_DFT
	exit 0	
else
	# move files to failed directory
	mv $title* $RM1_D/failed/
	rm $scratch/gamess_scratch/$title*
	rm $scratch/gamess_scratch/scr/$title*
	exit 1
fi
