#!/home/abreha.b/bats-core/bin bats

# example test
# @test "addition using bc" {
#   result="$(echo 2+2 | bc)"
#   [ "$result" -eq 4 ]
# }

function setup {
	set -a; source $FLOW/functions.sh; set +a 
}

@test "renaming existing slurm output files" {
	touch $BATS_TMPDIR/00000000.o $BATS_TMPDIR/00000000.e
	run rename_slurm_outputs "00000000" "file_name"
	[ "$status" -eq 0 ]
	i=$(ls 00000000.* | wc -l)
    j=$(ls file_name.* | wc -l)	
    [ "$i" -eq 0 ]
    [ "$j" -eq 2 ]
}

@test "determining the lowest energy conformer" {
	run bash $FLOW/scripts/get_lowest_conf_sp-dft.sh $FLOW/test/templates/lowest-energy-confs/AAACLBGNAMDLRM-UHFFFAOYSA
	conf_name=$(basename $output)
	[ "$status" -eq 0 ]
	[ "$conf_name" = "AAACLBGNAMDLRM-UHFFFAOYSA-N_2" ]
}

