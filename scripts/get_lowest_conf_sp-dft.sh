#!/bin/bash

# This script extracts the lowest energy conformer for conformers obtained from G16 optimization.
# Conformers are expected to have the name "MOLECULE_N.log" where N is the conformer number. The proper input
# for this script is "MOLECULE".


# molecule of interest
mol=$1

confs=()
energies=()

# gather energies of all conformers of the input molecule
for conf in $mol*.log; do
	confs+=($conf)
	energy=$(grep 'SCF Done' $conf | tail -1 | awk '{print $5}')
	energies+=($energy)
done

# initialize minimum energy to the first value in the array
min=${energies[0]}

# loop over the energies in the array, comparing each to the current minimum and replacing if a lower energy is found
min_index=0
curr_index=-1
for energy in "${energies[@]}"; do
	((curr_index+=1))
	comparison=$(echo $min'>'$energy | bc -l) # 1 if true, 0 if false
	if (($comparison == 1)); then
		min=$energy
		min_index=$curr_index
	fi
done

min_conf=${confs[$min_index]}

echo "${min_conf/_sp.log/}"
