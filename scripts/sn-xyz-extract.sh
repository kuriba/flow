#!/bin/bash
# Test script to extract geometries from failed Sn calcs or completed ground state calcs

source_config
mv sn_solv s1_solv 2>/dev/null
update_flow
update_existing_flow
get_charge_info
cd $MAIN_DIR

log_files=$(ls s1_solv/failed_opt/*.log s1_solv/completed/*.log 2>/dev/null)
num_log_files=$(ls s1_solv/failed_opt/*.log s1_solv/completed/*.log 2>/dev/null| wc -l)

if [[ $num_log_files > 0  ]]; then
	cd s1_solv
	for log_path in $log_files; do 
		log_file_name=$(basename $log_path)
		inchi_key=${log_file_name:0:27}
		title=$(echo "$inchi_key""_S1_solv")
		bash $FLOW/scripts/make-com.sh -i=$log_path -r="#p M06/6-31+G(d,p) opt td=(root=1) SCRF=(Solvent=Acetonitrile)" -c=$(get_charge $inchi_key) -t=$title -f
	done
	submit_array "$TITLE\_S1_SOLV" "g16_inp.txt" "com" "$FLOW_TOOLS/templates/array_g16_dft-opt.sbatch" "$DFT_TIME"
fi
