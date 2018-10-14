#!/bin/bash

# script for automatically creating directory setup for database batch submissions
# takes N arguments which are the names of the batches with the following format: 
#
#							   title_M_C_YYYY-MM-DD
# 
# where M is the number of pdb files in the batch and C is the number of conformers

for batch_title in "$@"; do

	# don't make directory if already exists
	if [ -d "$batch_title" ]; then echo "error: directory named $batch_title already exists"; continue; fi
	mkdir $batch_title && cd $batch_title

	# setup directory structure
	mkdir unopt_pdbs pm7 rm1-d sp-dft sp-tddft s0_vac s0_solv s1_solv t1_solv cat-rad_solv cat-rad_vac all-logs mol-data flow-tools
	for d in pm7 rm1-d sp-dft sp-tddft; do mkdir $d/completed $d/failed; done
	for d in pm7 rm1-d s0_vac; do mkdir $d/opt_pdbs; done
	for d in s0_vac s0_solv s1_solv t1_solv cat-rad_solv cat-rad_vac; do mkdir $d/completed $d/failed_opt $d/failed_freq $d/resubmits $d/freq_calcs; done

	# setup config
	rsync -r --exclude=setup-flow.sh --exclude=functions.sh $FLOW/* flow-tools/.

	cd ..

done
