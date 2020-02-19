#!/bin/bash

# script for setting up DFT optimizations after completion of S0 DFT optimization in vacuo

# source config and function files
source_config

pdb_file=$1
inchi="${pdb_file/_S0_vac.pdb/}"
charge=$(get_charge $inchi)

# setup S0 DFT optimization (in solvent)
bash $FLOW/scripts/make-com.sh -i=$pdb_file -r='#p M06/6-31+G(d,p) SCRF=(Solvent=Acetonitrile) opt' -c=$charge -t=$inchi\_S0_solv -l=$S0_SOLV

# setup S1 DFT optimization (in solvent)
bash $FLOW/scripts/make-com.sh -i=$pdb_file -r="#p M06/6-31+G(d,p) SCRF=(Solvent=Acetonitrile) opt td=root=1" -c=$charge -t=$title\_S1_solv -l=$S1_SOLV

# setup T1 DFT optimization (in solvent)
bash $FLOW/scripts/make-com.sh -i=$pdb_file -r='#p M06/6-31+G(d,p) SCRF=(Solvent=Acetonitrile) opt' -t=$inchi\_T1_solv -c=$charge -s=3 -l=$T1_SOLV

# setup cation radical DFT optimization (in solvent)
bash $FLOW/scripts/make-com.sh -i=$pdb_file -r='#p M06/6-31+G(d,p) SCRF=(Solvent=Acetonitrile) opt' -t=$inchi\_cat-rad_solv -c=$(($charge + 1)) -s=2 -l=$CAT_RAD_SOLV

# setup cation radical DFT optimization (in vacuo)
bash $FLOW/scripts/make-com.sh -i=$pdb_file -r='#p M06/6-31+G(d,p) opt' -t=$inchi\_cat-rad_vac -c=$(($charge + 1)) -s=2 -l=$CAT_RAD_VAC
