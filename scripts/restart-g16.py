import os
import sys
import glob
import re

cwd = os.getcwd()
files = [file for file in sys.argv[1:] if file.endswith(".com")]
com_files = []

# only keep input files which also have log files in the same directory
for file in files:
    if os.path.exists(file.replace(".com", ".log")):
        com_files.append(file)

# returns the route of the given Gaussian input file
def get_route(com_file):
    route = None
    with open(com_file, "r") as file:
        for line in file:
            line = line.strip()
            if line.startswith("#"):
                route = line
                break
    return route

# returns the options of the opt keyword
def get_opt_options(route):
    opt_keyword = [i for i in route.split(" ") if i.startswith("opt")][0]
    try:
        opt_options = opt_keyword.split("=")[1].replace(")", "").replace("(", "").split(",")
        return opt_options
    except:
        return []

def get_opt_keyword(route):
    opt_keyword = [i for i in route.split(" ") if i.startswith("opt")][0]
    return opt_keyword

# returns the number of occurences of the given search string in the given file
def get_count(file, search_string):
    text = open(file, "r").read()
    count = text.count(search_string)
    return count

# determines if the given job needs to be restarted
def needs_restart(com_file, log_file):
    route = get_route(com_file)
    normal_t_count = get_count(log_file, "Normal termination")
    if "opt" in route and "freq" in route:
        if normal_t_count == 2:
            return False
    elif "opt" in route or "freq" in route or "# Restart" in route:
        if normal_t_count == 1:
            return False
    return True

# determines if the given job encountered an error fail
def error_fail(log_file):
    return get_count(log_file, "Error termination") > 0

# determines if the given job failed due to a convergence failure
def convergence_fail(log_file):
    text = open(log_file, "r").read()
    count = text.count("Convergence failure -- run terminated.")
    if count > 0:
        return True
    else:
        return False

# removes the coordinates, charge, and multiplicity from the given Gaussian input file
def remove_coord_charge_mult(com_file):
    file_text = open(com_file, "r").readlines()
    with open(com_file, "w") as file:
        for line in file_text:
            search = re.match(r'-?\d \d', line)
            if search:
                break
            else:
                file.write(line)

# sets up an optimization to be restarted
def restart_opt(com_file, additional_opt_options=[]):
    route = get_route(com_file)
    opt_keyword = get_opt_keyword(route)
    opt_options = get_opt_options(route)
    opt_options.append("restart")
    for option in additional_opt_options:
        if option not in opt_options:
            opt_options.append(option)
    if "opt=" in route and "geom=allcheck" in route and "guess=read" in route:
        return
    else:
        remove_coord_charge_mult(com_file)
        file_text = open(com_file, "r").readlines()
        with open(com_file, "w") as file:
            for line in file_text:
                if line.startswith("#"):
                    line = line.strip()
                    new_opt_keyword = "opt=(" + ",".join(opt_options) + ")"
                    new_line = line.replace(opt_keyword, new_opt_keyword)
                    new_line += " geom=allcheck guess=read\n"
                    file.write(new_line)
                else:
                    file.write(line)

# sets up a frequency calculation to be restarted
def restart_freq(com_file):
    remove_coord_charge_mult(com_file)
    file_text = open(com_file, "r").readlines()
    with open(com_file, "w") as file:
        for line in file_text:
            if line.startswith("#"):
                file.write("# Restart\n")
            else:
                file.write(line)

# Removes the rwf files associated with the given log file
def clear_gau_files(log_file):
    with open(log_file, "r") as file:
        for line in file:
            line = line.strip()
            if line.startswith("Entering Link 1"):
                PID = line.split(" ")[-1].replace(".", "")
                INP_ID = str(int(PID) - 1)
    for f in glob.glob("Gau-{}*".format(PID)):
        os.remove(f)
    os.remove("Gau-{}.inp".format(INP_ID))



for com_file in com_files:
    log_file = com_file.replace(".com", ".log")
    error = error_fail(log_file)
    if needs_restart(com_file, log_file) and not error:
        route = get_route(com_file)
        normal_t_count = get_count(log_file, "Normal termination")
        if "opt" in route and "freq" in route:
            if normal_t_count == 1:
                restart_freq(com_file)
            elif normal_t_count == 0:
                restart_opt(com_file)
        elif "opt" in route:
            restart_opt(com_file)
        elif "freq" in route:
            restart_freq(com_file)
            clear_gau_files(log_file)
    elif convergence_fail(log_file):
        restart_opt(com_file, additional_opt_options=["calcfc"])
        clear_gau_files(log_file)
