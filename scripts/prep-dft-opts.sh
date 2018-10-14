#!/bin/bash

# script for setting up DFT optimizations after completion of S0 DFT optimization in vacuo

# source config and function files
source-config

log_file=$1
inchi="${log_file/_S0_vac.pdb/}"

# setup S0 DFT optimization (in solvent)
bash $FLOW_TOOLS/scripts/make-com.sh -i=$log_file -r='#p M06/6-31+G(d,p) SCRF=(Solvent=Acetonitrile) opt' -t=$inchi\_S0_solv -l=$S0_SOLV

# setup S1 DFT optimization (in solvent)
bash $FLOW_TOOLS/scripts/make-com.sh -i=$log_file -r='#p M06/6-31+G(d,p) SCRF=(Solvent=Acetonitrile) opt td=root=1' -t=$inchi\_S1_solv -l=$S1_SOLV

# setup T1 DFT optimization (in solvent)
bash $FLOW_TOOLS/scripts/make-com.sh -i=$log_file -r='#p M06/6-31+G(d,p) SCRF=(Solvent=Acetonitrile) opt' -t=$inchi\_T1_solv -s=3 -l=$T1_SOLV

# setup cation radical DFT optimization (in solvent)
bash $FLOW_TOOLS/scripts/make-com.sh -i=$log_file -r='#p M06/6-31+G(d,p) SCRF=(Solvent=Acetonitrile) opt' -t=$inchi\_cat-rad_solv -c=1 -s=2 -l=$CAT_RAD_SOLV

# setup cation radical DFT optimization (in vacuo)
bash $FLOW_TOOLS/scripts/make-com.sh -i=$log_file -r='#p M06/6-31+G(d,p) opt' -t=$inchi\_cat-rad_vac -c=1 -s=2 -l=$CAT_RAD_VAC
