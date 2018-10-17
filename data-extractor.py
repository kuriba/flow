import sys
import subprocess
import json
import os
import csv
import pandas as pd

# sript for extracting data

mols = []

for file in os.listdir("unopt_pdbs"):
    if file.endswith("_0.pdb"):
        mols.append(file[:-6])

os.chdir("all-logs")

# function which extracts coordinates from log file
def get_geom(log):
    mol_info = []
    collect_info = False
    try:
        with open(log, "r") as file:
            for line in file:
                line = line.strip()
                if "Dipole" in line:
                    collect_info = False
                elif line.startswith("1\\1\\"):
                    collect_info = True
                    mol_info.append(line)
                elif collect_info:
                    mol_info.append(line)
        mol_info = "".join(mol_info)
        mol_info = mol_info.split("Version", 1)[0]
        mol_info = mol_info.split("\\\\")
        geom = mol_info[3]
        geom = geom.split("\\")[1:]
        return geom
    except:
        return ""

# function which writes xyz files
# function which writes xyz files
def write_xyz(name, geom):
	if (len(geom) > 0):
		xyz_file = "../mol-data/" + name
		formatted_xyz = ""
		with open(xyz_file, "w") as file:
			file.write(str(len(geom)) + "\n\n")
		for atom in geom:
			formatted_atom = atom.replace(",","        ")
			formatted_xyz += formatted_atom + "\n"
		with open(xyz_file, "a") as file:
			file.write(formatted_xyz)	

# function which extracts basic molecular data
def basic_info(mol):
	cmd = "obprop " + mol + " 2>/dev/null" + " | awk \'{if ($1==\"formula\" || $1==\"mol_weight\" || $1==\"exact_mass\" || $1==\"canonical_SMILES\" || $1==\"InChI\" || $1==\"logP\") print $2 }\'"
	ps = subprocess.Popen(cmd,shell=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
	output = str(ps.communicate()[0], "utf-8")
	if "Open Babel Warning" in output:
		output = [""] * 10	
	else:
		output = output.strip().split("\n")	
	# [formula, mol_weight, exact_mass, SMILES, InChI, logP]	
	return(output)

# function which extracts energies from given log file
def get_energies(mol):
	try:
		virt_orbs = []
		with open(mol, "r") as file:
			for line in file:
				line = line.strip()
				# free energy
				if line.startswith("Sum of electronic and thermal Free Energies="):
					free_energy = line.split("Energies=")[1].strip()
				# enthalpy
				if line.startswith("Sum of electronic and thermal Enthalpies="):
					enthalpy = line.split("Enthalpies=")[1].strip()
				# entropy
				if line.startswith("KCal/Mol"):
					entropy = next(file).strip().split(" ")[-1]
				# zpve
				if line.startswith("Sum of electronic and zero-point Energies="):
					zpve = line.split("Energies=")[1].strip()
				# homo
				if line.startswith("Alpha  occ. eigenvalues"):
					homo = line.split(" ")[-1]
				# lumo
				if line.startswith("Alpha virt. eigenvalues"):
					virt_orbs.append(line)
		lumo = virt_orbs[0].split("--",1)[1].strip().split(" ", 1)[0]
		
		return free_energy, enthalpy, entropy, zpve, homo, lumo
	except:
		return "", "", "", "", "", ""

def get_scf_energy(mol):
    try:
        scf_energy = ""
        with open(mol, "r") as file:
            for line in file:
                line = line.strip()
                if line.startswith("SCF Done:"):
                    scf_energy = line.split(" ")[6]
        return scf_energy
    except:
        return ""

def push_data(state, solv, geom, energies, json_obj, total_electronic_energy):
    json_obj[state][solv]["geom"] = geom
    json_obj[state][solv]["energies"]["G"] = energies[0]
    json_obj[state][solv]["energies"]["H"] = energies[1]
    json_obj[state][solv]["energies"]["S"] = energies[2]
    json_obj[state][solv]["energies"]["zpve"] = energies[3]
    json_obj[state][solv]["energies"]["homo"] = energies[4]
    json_obj[state][solv]["energies"]["lumo"] = energies[5]
    json_obj[state][solv]["energies"]["total_electronic_energy"] = total_electronic_energy

# extract data for each molecule
for mol in mols:
	# filenmes
	s1_solv_opt = mol + "_S1_solv.log"
	s1_solv_freq = mol + "_S1_solv_freq.log"
	s1_solv_xyz = mol + "_S1_solv.xyz"
	s0_vac_opt = mol + "_S0_vac.log"
	s0_vac_freq = mol + "_S0_vac_freq.log"
	s0_vac_xyz = mol + "_S0_vac.xyz"
	s0_solv_opt = mol + "_S0_solv.log"
	s0_solv_freq = mol + "_S0_solv_freq.log"
	s0_solv_xyz = mol + "_S0_solv.xyz"
	cat_rad_vac_opt = mol + "_cat-rad_vac.log"
	cat_rad_vac_freq = mol + "_cat-rad_vac_freq.log"
	cat_rad_vac_xyz = mol + "_cat-rad_vac.xyz"
	cat_rad_solv_opt = mol + "_cat-rad_solv.log"
	cat_rad_solv_freq = mol + "_cat-rad_solv_freq.log"
	cat_rad_solv_xyz = mol + "_cat-rad_solv.xyz"
	t1_solv_opt = mol + "_T1_solv.log"
	t1_solv_freq = mol + "_T1_solv_freq.log"
	t1_solv_xyz = mol + "_T1_solv.xyz"
	sp_tddft = mol + "_sp-tddft.log"	

	# get basic mol info
	mol_data = basic_info("../unopt_pdbs/" + mol + "_0.pdb")
	
	# vertical excitation energy
	try:
		with open(s1_solv_opt, "r") as file:
			for line in file:
				line = line.strip()
				if line.startswith("Excited State   1:"):
					vertical_excitation_energy = line.split("eV",1)[1].split("nm",1)[0].strip()
					break
	except:
		try:
			with open(sp_tddft, "r") as file:
				for line in file:
					line = line.strip()
					if line.startswith("Excited State   1:"):
						vertical_excitation_energy = line.split("eV",1)[1].split("nm",1)[0].strip()
						break
		except:
			vertical_excitation_energy = ''

	# extract energies
	s1_solv_energies = get_energies(s1_solv_freq)
	s0_vac_energies = get_energies(s0_vac_freq)
	s0_solv_energies = get_energies(s0_solv_freq)
	cat_rad_vac_energies = get_energies(cat_rad_vac_freq)
	cat_rad_solv_energies = get_energies(cat_rad_solv_freq)
	t1_solv_energies = get_energies(t1_solv_freq)
	
	# electronic energies
	s0_vac_elec_energy = get_scf_energy(s0_vac_opt)
	s0_solv_elec_energy = get_scf_energy(s0_solv_opt)
	s1_solv_elec_energy = get_scf_energy(s1_solv_opt)
	cat_rad_vac_elec_energy = get_scf_energy(cat_rad_vac_opt)
	cat_rad_solv_elec_energy = get_scf_energy(cat_rad_solv_opt)
	t1_solv_elec_energy = get_scf_energy(t1_solv_opt)

	# extract geometries
	s0_vac_geom = get_geom(s0_vac_opt)
	s0_solv_geom = get_geom(s0_solv_opt)
	s1_solv_geom = get_geom(s1_solv_opt)
	t1_solv_geom = get_geom(t1_solv_opt)
	cat_rad_vac_geom = get_geom(cat_rad_vac_opt)
	cat_rad_solv_geom = get_geom(cat_rad_solv_opt)

	# write xyz files
	write_xyz(s0_vac_xyz, s0_vac_geom)
	write_xyz(s0_solv_xyz, s0_solv_geom)
	write_xyz(s1_solv_xyz, s1_solv_geom)
	write_xyz(t1_solv_xyz, t1_solv_geom)
	write_xyz(cat_rad_vac_xyz, cat_rad_vac_geom)
	write_xyz(cat_rad_solv_xyz, cat_rad_solv_geom)

	# compute properties
	# 0-0 transition energy
	if (s1_solv_energies[3] != "") and (s0_solv_energies[3] != ""):
		E00 = round(27.211 * (float(s1_solv_energies[3]) - float(s0_solv_energies[3])), 2)
	else:
		E00 = ""

	# ionization potential
	if (s0_vac_energies[1] != "") and (cat_rad_vac_energies[1] != ""):
		ip = round(27.211 * (float(cat_rad_vac_energies[1]) - float(s0_vac_energies[1])), 2)
	else:
		ip = ""

	# redox potential
	if "" not in (ip, s0_vac_energies[2], cat_rad_vac_energies[2], s0_solv_energies[0], s0_vac_energies[0], cat_rad_solv_energies[0], cat_rad_vac_energies[0]):
		# ∆S
		s0_S = float(s0_vac_energies[2]) / 1000
		cat_rad_S = float(cat_rad_vac_energies[2]) / 1000
		delS = float(cat_rad_S) - float(s0_S)
		TdelS = -298.15 * delS
		# ox solvation energy
		s0_solvation_energy = 627.509 * (float(s0_solv_energies[0]) - float(s0_vac_energies[0]))
		# red solvation energy
		cat_rad_solvation_energy = 627.509 * (float(cat_rad_solv_energies[0]) - float(cat_rad_vac_energies[0]))
		
		redox_pot = round(ip + (1/23.06) * (TdelS + cat_rad_solvation_energy - s0_solvation_energy) - 4.44, 2)
	else:
		redox_pot = ""

	# write data
	with open("/home/abreha.b/flow/templates/mol-template.json", "r+") as file:
		data = json.load(file)
		
		# basic details
		data["formula"] = mol_data[0]
		data["smiles"] = mol_data[3]
		data["inchi"] = mol_data[4]
		data["inchi-key"] = mol

		# properties
		data["properties"]["mw"] = mol_data[1]
		data["properties"]["ip"] = str(ip)
		data["properties"]["rp"] = str(redox_pot)
		data["properties"]["0-0"] = str(E00)
		data["properties"]["ve"] = vertical_excitation_energy
	
		# S0 solv
		push_data("s0", "solv", s0_solv_geom, s0_solv_energies, data, s0_solv_elec_energy)
		# S0 vac
		push_data("s0", "vac", s0_vac_geom, s0_vac_energies, data, s0_vac_elec_energy)
		# S1 solv
		push_data("s1", "solv", s1_solv_geom, s1_solv_energies, data, s1_solv_elec_energy)
		# cation radical solv
		push_data("cat-rad", "solv", cat_rad_solv_geom, cat_rad_solv_energies, data, cat_rad_solv_elec_energy)
		# cation radical vac
		push_data("cat-rad", "vac", cat_rad_vac_geom, cat_rad_vac_energies, data, cat_rad_vac_elec_energy)
		# T1 solv
		push_data("t1", "solv", t1_solv_geom, t1_solv_energies, data, t1_solv_elec_energy)

	json_name = mol + ".json"
	
	with open("../mol-data/" + json_name, "w") as data_file:
		data_file.write(json.dumps(data))	
	