#!/usr/bin/env python3.9

from os import getenv, chdir
from sys import argv
from subprocess import run

def dependencie_files_list(dep):
    dep_yml = open(dep, 'r').readlines()
    # get directory of the dep file
    dep_dir = '/'.join(dep.split('/')[:-1]) + "/"
    #print(dep_dir)
    dep_files = []
    include_files = []
    if "dependencies:\n" in dep_yml:
        dep_idx = dep_yml.index("dependencies:\n") + 1
        while dep_idx < len(dep_yml):
            if "-" in dep_yml[dep_idx]:
                dep_files.append(dep_dir + dep_yml[dep_idx].replace('-', '').strip())
                dep_idx += 1
            else:
                break
    
    #print(dep_files)
    
    for dep_file in dep_files:
        include_files.extend(dependencie_files_list(f"{dep_file}"))
    
    file_idx = dep_yml.index('files:\n') + 1
    while file_idx < len(dep_yml):
        if "-" in dep_yml[file_idx]:
            include_files.append(f"{dep_dir}" + dep_yml[file_idx].replace('-', '').strip())
            file_idx += 1
        else:
            break
    return include_files

def main():
    work_dir = f"{getenv('PROJECT_ROOT')}/cores/{argv[1]}"
    # get files to include
    include_files = dependencie_files_list(f"{work_dir}/{argv[1]}.yml")
    chdir(f"{work_dir}/syn")
    run(["mkdir", "-p", "_syntax"])
    chdir(f"{work_dir}/syn/_syntax")
    with open("syntax_check.tcl", 'w') as f:
        f.write("create_project -force -name syntax_check\n")
        for file in include_files:
            f.write(f"add_files \"{file}\"\n")
        #f.write(f"set_property top {argv[1]} [current_fileset]\n")
        #f.write("update_compile_order -fileset sources_1\n")
        f.write("set_property FILE_TYPE {VHDL 2008} [get_files *.vhd]\n")
        f.write("check_syntax")
        f.write("exit")
    run(["vivado", "-mode", "tcl", "-source", "syntax_check.tcl"])

if __name__ == "__main__":
    main()