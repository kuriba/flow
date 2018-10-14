#!/bin/bash

# cat-rad_dft-opt_solv  pm7_opt    s0_dft-opt_solv  s1_dft-opt_solv  sp_td-dft        unopt_pdbs
# cat-rad_dft-opt_vac   rm1-d_opt  s0_dft-opt_vac   sp_dft           t1_dft-opt_solv

SCALE=2

for file in unopt_pdbs/*_0.pdb; do
	file=$(basename $file)
	inchi_key="${file/_0.pdb/}"
	
	# S0 geometry
	obabel -i log s0_dft-opt_vac/completed/$inchi_key\_S0_vac.log -o sdf -O $inchi_key.sdf --add cansmi 1>/dev/null

	# VEE extraction
	vee=$(grep 'Excited State   1' sp_td-dft/completed/$inchi_key\_sp-tddft.log | awk '{print $7}')	
	bash $utils/add-sdf-prop.sh $inchi_key.sdf VEE $vee
	# IP extraction
	red_elect_enthalpy=$(grep 'Sum of electronic and thermal Enthalpies' s0_dft-opt_vac/completed/$inchi_key\_S0_vac_freq.log | awk '{print $7}')
	ox_elect_enthalpy=$(grep 'Sum of electronic and thermal Enthalpies' cat-rad_dft-opt_vac/completed/$inchi_key\_cat-rad_vac_freq.log | awk '{print $7}')

	bash $utils/add-sdf-prop.sh $inchi_key.sdf ground-state_TE-H_Ha "<+>$red_elect_enthalpy"
	bash $utils/add-sdf-prop.sh $inchi_key.sdf cation-radical_TE-H_Ha "<+>$ox_elect_enthalpy"
	
	# entropy
	s0_vac_entropy=$(grep -A 2 'E (Thermal)' s0_dft-opt_vac/completed/$inchi_key\_S0_vac_freq.log | awk '{print $4}' | tail -1)
	cat_rad_vac_entropy=$(grep -A 2 'E (Thermal)' cat-rad_dft-opt_vac/completed/$inchi_key\_cat-rad_vac_freq.log | awk '{print $4}' | tail -1)
	bash $utils/add-sdf-prop.sh $inchi_key.sdf ground-state_vac_entropy_cal_mol-K $s0_vac_entropy
	bash $utils/add-sdf-prop.sh $inchi_key.sdf cation-radical_vac_entropy_cal_mol-K $cat_rad_vac_entropy
	
	# free energy
	s0_vac_free_energy=$(grep 'Sum of electronic and thermal Free Energies' s0_dft-opt_vac/completed/$inchi_key\_S0_vac_freq.log | awk '{print $8}')
	s0_solv_free_energy=$(grep 'Sum of electronic and thermal Free Energies' s0_dft-opt_solv/completed/$inchi_key\_S0_solv_freq.log | awk '{print $8}')
	cat_rad_vac_free_energy=$(grep 'Sum of electronic and thermal Free Energies' cat-rad_dft-opt_vac/completed/$inchi_key\_cat-rad_vac_freq.log | awk '{print $8}')
	cat_rad_solv_free_energy=$(grep 'Sum of electronic and thermal Free Energies' cat-rad_dft-opt_solv/completed/$inchi_key\_cat-rad_solv_freq.log | awk '{print $8}')
	bash $utils/add-sdf-prop.sh $inchi_key.sdf ground-state_vac_free-energy_Ha "<+>$s0_vac_free_energy"
	bash $utils/add-sdf-prop.sh $inchi_key.sdf ground-state_solv_free-energy_Ha "<+>$s0_solv_free_energy"
	bash $utils/add-sdf-prop.sh $inchi_key.sdf cat-rad_vac_free-energy_Ha "<+>$cat_rad_vac_free_energy"
	bash $utils/add-sdf-prop.sh $inchi_key.sdf cat-rad_solv_free-energy_Ha "<+>$cat_rad_solv_free_energy"

	#FMOs
	HOMO_energy=$(grep 'Alpha  occ. eigenvalues' s0_dft-opt_vac/completed/$inchi_key\_S0_vac_freq.log | tail -1 | awk '{print $NF}')
	LUMO_energy=$(grep 'Alpha virt. eigenvalues' s0_dft-opt_vac/completed/$inchi_key\_S0_vac_freq.log | head -1 | awk '{print $5}')
	bash $utils/add-sdf-prop.sh $inchi_key.sdf HOMO_energy "<+>$HOMO_energy"
	bash $utils/add-sdf-prop.sh $inchi_key.sdf LUMO_energy "<+>$LUMO_energy"

	gr_elect_zpve=$(grep 'Sum of electronic and zero-point Energies=' s0_dft-opt_solv/completed/$inchi_key\_S0_solv_freq.log | awk '{print $7}')
	ex_elect_zpve=$(grep 'Sum of electronic and zero-point Energies=' s1_dft-opt_solv/completed/$inchi_key\_S1_solv_freq.log | awk '{print $7}')
	bash $utils/add-sdf-prop.sh $inchi_key.sdf ground_electronic-zpve_Ha "<+>$gr_elect_zpve"
	bash $utils/add-sdf-prop.sh $inchi_key.sdf excited_electronic-zpve_Ha "<+>$ex_elect_zpve"

done

sed -i "s/<+>-/-/g" *.sdf
sed -i "s/<+>//g" *.sdf

all_mols=$(ls *.sdf)

obabel $all_mols all_mols.sdf -O all_mols.sdf 2>/dev/null
