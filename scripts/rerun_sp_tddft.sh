# script for rerunning sp-tddft jobs with wB97XD functional

source_config
update_existing_flow
cd $SP_TDDFT
cp completed/*.com . 2>/dev/null
cp failed/*.com . 2>/dev/null

for f in *.com; do
	is_M06=$(grep 'M06/' $f | wc -l)
	log_file="${f/.com/.log}"
	if [[ $is_M06 -eq 1 ]]; then
		sed -i "s|M06/|wB97XD/|" $f
		rm completed/$log_file 2>/dev/null
		rm failed/$log_file 2>/dev/null
	fi
done
resubmit_array
