#!/bin/bash
#SBATCH -J DFT-VEE_submitter
#SBATCH -o DFT-VEE_submitter.o
#SBATCH -e DFT-VEE_submitter.e
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --parsable
#SBATCH --dependency=afterany:T1_DFT_OPT_SOLV_ID

# source config and function files
source_config

gen_slurm_report

pwd
# handles submission of:
# 	T1 single-point TD-DFT (for vertical excitation energy)

# submit S0 DFT optimization array (in vacuo)
cd $T1_SP_TDDFT
pwd
T1_SP_TDDFT_ID=$(submit_array "$TITLE\_T1-SP-TDDFT" "g16_inp.txt" "com" $FLOW_TOOLS/templates/array_g16_t1_sp_td-dft.sbatch $DFT_TIME)
wait

