#!/bin/bash

# script for checking progress of workflow batch
# run in workflow directory to get progress report

source_config
cd $MAIN_DIR

total_unique=$(for file in $UNOPT_PDBS/*.pdb; do echo $file | sed 's|_[0-9].pdb||'; done | uniq | wc -l)
total_pdbs=$(ls -f unopt_pdbs/*.pdb | wc -l)
directory_name=$(basename `pwd`)

# print header
bold=$(tput bold); normal=$(tput sgr0); now=$(date)
echo -e "\n\t\t$now"
echo -e "\t\tReport for ${bold}$directory_name${normal}\n\t\tNum. Molecules: $total_unique\n\t\tTotal Structures: $total_pdbs\n"
 
# table title
echo -e "\t\t\t\t\t\t  ${bold}Pre-DFT Optimization${normal}"

# print header
header_dimension='%20s %14s %14s %14s %14s %14s %14s\n'
printf "$header_dimension" '' "completed" "incomplete" "running" "resubmissions" "failed_opt" "failed_freq"

function percentage {
	NUMER=$1; DENOM=$2
	if [[ "$DENOM" -ne 0 ]]; then
		result=$(echo "$NUMER $DENOM" | awk '{printf "%0.1f\n", 100 * ($1 / $2)}')
		echo $result
	else
		echo "0.0"
	fi
}

function get_prog {
	DIR=$1; TOTAL=$2; OUT_TYPE=$3; NAME=$4
	num_running=$(ls -f $DIR/*.OUT_TYPE 2>/dev/null | wc -l)
	num_completed=$(ls -f $DIR/completed/*.$OUT_TYPE 2>/dev/null | wc -l)
	num_failed=$(ls -f $DIR/failed/*.$OUT_TYPE 2>/dev/null | wc -l)
	num_incomplete=$(echo $(($TOTAL - $num_completed)))
	percent_running=$(percentage $num_running $TOTAL)
	percent_completed=$(percentage $num_completed $TOTAL)
	percent_failed=$(percentage $num_failed $TOTAL)
	percent_incomplete=$(percentage $num_incomplete $TOTAL)
	printf "%20s %5s %8s %5s %8s %5s %8s %13s %5s %8s %13s\n" "$NAME" "$num_completed" "($percent_completed%)" "$num_incomplete" "($percent_incomplete%)" \
				"$num_running" "($percent_running%)" "    –––––––   " "$num_failed" "($percent_failed%)" "     –––––––   "
}

get_prog pm7 $total_pdbs log 'PM7 opt'
get_prog rm1-d $total_pdbs o 'RM1-D opt'
get_prog sp-dft $total_pdbs log 'SP-DFT'
get_prog sp-tddft $total_unique log 'SP-TD-DFT'

# table title
echo -e "\n\t\t\t\t\t\t  ${bold}DFT Optimization${normal}"
# header
printf "$header_dimension" '' "completed" "incomplete" "running" "resubmissions" "failed_opt" "failed_freq"

function get_prog {
	DIR=$1; TOTAL=$2; OUT_TYPE=$3; NAME=$4
	num_completed=$(ls -f $DIR/completed/*_freq.$OUT_TYPE 2>/dev/null | wc -l)
	num_failed_opts=$(ls -f $DIR/failed_opt/*.$OUT_TYPE 2>/dev/null | wc -l)
	num_failed_freqs=$(ls -f $DIR/failed_freq/*.$OUT_TYPE 2>/dev/null | wc -l)
	num_resubs=$(ls -f $DIR/resubmits/*.$OUT_TYPE 2>/dev/null | wc -l)
	num_running=$(ls -f $DIR/*.$OUT_TYPE 2>/dev/null | wc -l)
	num_incomplete=$(echo $(($TOTAL - $num_completed)))
	percent_completed=$(percentage $num_completed $TOTAL)
	percent_failed_opt=$(percentage $num_failed_opts $TOTAL)
	percent_failed_freq=$(percentage $num_failed_freqs $TOTAL)
	percent_resub=$(percentage $num_resubs $TOTAL)
	percent_running=$(percentage $num_running $TOTAL)
	percent_incomplete=$(percentage $num_incomplete $TOTAL)
	printf "%20s %5s %8s %5s %8s %5s %8s %5s %8s %5s %8s %5s %8s\n" "$NAME" "$num_completed" "($percent_completed%)" "$num_incomplete" "($percent_incomplete%)" \
		 "$num_running" "($percent_running%)" "$num_resubs" "($percent_resub%)" "$num_failed_opts" "($percent_failed_opt%)" "$num_failed_freqs" "($percent_failed_freq%)"
}

get_prog s0_vac $total_unique log 'S0 (in vacuo)'
get_prog s0_solv $total_unique log 'S0 (in MeCN)'
get_prog s1_solv $total_unique log 'S1 (in MeCN)'
get_prog t1_solv $total_unique log 'T1 (in MeCN)'
get_prog cat-rad_vac $total_unique log 'cat-rad (in vacuo)'
get_prog cat-rad_solv $total_unique log 'cat-rad (in MeCN)'

echo ""

