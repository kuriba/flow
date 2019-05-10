#!/bin/bash

# script for setting up DFT optimizations after completion of S0 DFT optimization in vacuo

# source config and function files
source_config

pdb_file=$1
inchi="${pdb_file/_S0_vac.pdb/}"

# setup S0 DFT optimization (in solvent)
bash $FLOW_TOOLS/scripts/make-com.sh -i=$pdb_file -r='#p M06/6-31+G(d,p) SCRF=(Solvent=Acetonitrile) opt' -t=$inchi\_S0_solv -l="$S0_SOLV/resubmits"
cd "$S0_SOLV/resubmits" && setup_sbatch "$inchi\_S0_solv.com" "$FLOW_TOOLS/templates/single_g16_dft-opt.sbatch"

# setup S1 DFT optimization (in solvent)
bash $FLOW_TOOLS/scripts/make-com.sh -i=$pdb_file -r='#p M06/6-31+G(d,p) SCRF=(Solvent=Acetonitrile) opt td=root=1' -t=$inchi\_S1_solv -l="$S1_SOLV/resubmits"
cd "$S1_SOLV/resubmits" && setup_sbatch "$inchi\_S1_solv.com" "$FLOW_TOOLS/templates/single_g16_dft-opt.sbatch"

# setup T1 DFT optimization (in solvent)
bash $FLOW_TOOLS/scripts/make-com.sh -i=$pdb_file -r='#p M06/6-31+G(d,p) SCRF=(Solvent=Acetonitrile) opt td=(triplets, root=1)' -t=$inchi\_T1_solv -s=3 -l="$T1_SOLV/resubmits"
cd "$T1_SOLV/resubmits" && setup_sbatch "$inchi\_T1_solv.com" "$FLOW_TOOLS/templates/single_g16_dft-opt.sbatch"

# setup cation radical DFT optimization (in solvent)
bash $FLOW_TOOLS/scripts/make-com.sh -i=$pdb_file -r='#p M06/6-31+G(d,p) SCRF=(Solvent=Acetonitrile) opt' -t=$inchi\_cat-rad_solv -c=1 -s=2 -l="$CAT_RAD_SOLV/resubmits"
cd "$CAT_RAD_SOLV/resubmits" && setup_sbatch "$inchi\_cat-rad_solv.com" "$FLOW_TOOLS/templates/single_g16_dft-opt.sbatch"

# setup cation radical DFT optimization (in vacuo)
bash $FLOW_TOOLS/scripts/make-com.sh -i=$pdb_file -r='#p M06/6-31+G(d,p) opt' -t=$inchi\_cat-rad_vac -c=1 -s=2 -l="$CAT_RAD_VAC/resubmits"
cd "$CAT_RAD_VAC/resubmits" && setup_sbatch "$inchi\_cat-rad_vac.com" "$FLOW_TOOLS/templates/single_g16_dft-opt.sbatch"
