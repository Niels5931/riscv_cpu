#!/usr/bin/env python3.9
from os import mkdir, chdir, getcwd, listdir, getenv
from sys import argv
import argparse
from remove_project import rm_dir

def main():
    
    argparser = argparse.ArgumentParser(description="Create a new project template")
    argparser.add_argument("project_name", help="Name of the project")
    argparser.add_argument("-d", "--dependencies", nargs='+', help="List of dependencies")
    args = argparser.parse_args()
    
    project_root = getenv("PROJECT_ROOT")
    # Get the name of the project from the command line
    project_name = args.project_name
    # check if the project directory exists
    if project_name in listdir(getcwd()):
        rm_dir(f"{getcwd()}/{project_name}")
    # Create the project directory
    chdir(f"{project_root}/cores")
    mkdir(project_name)
    # create yml file
    chdir(project_name)
    with open(f"{getcwd()}/{project_name}.yml", 'w') as f:
        f.write("#%SimplAPI=1.0\n\n")
        if args.dependencies:
            f.write(f"dependencies:\n")
            for dep in args.dependencies:
                f.write(f"- ../{dep}/{dep}.yml\n")
        f.write(f"files:\n- hdl/{project_name}.vhd")
    # Create the project subdirectories
    mkdir('hdl')
    mkdir('sim')
    mkdir('syn')

    # make top level files in hdl and sim
    with open(f"{getcwd()}/hdl/{project_name}.vhd", 'w') as f:
        f.write(f"library ieee;\n")
        f.write(f"use ieee.std_logic_1164.all;\n")
        f.write(f"use ieee.numeric_std.all;\n\n")
        f.write(f"entity {project_name} is\n")
        f.write(f"generic (\n")
        f.write(f"\t-- INSERT_GENERIC_HERE\n")
        f.write(f");\n")
        f.write(f"port (\n")
        f.write(f"\t-- INSERT_PORTS_HERE\n")
        f.write(f");\n")
        f.write(f"end entity;\n\n")
        f.write(f"architecture rtl of {project_name} is\n\n")
        if args.dependencies:
            for i in range(len(args.dependencies)):
                f.write(f"\tcomponent {args.dependencies[i]} \n")
                with open(f"../{args.dependencies[i]}/hdl/{args.dependencies[i]}.vhd", 'r') as dep:
                    file_lines = dep.readlines()
                    start = file_lines.index(f"entity {args.dependencies[i]} is\n")
                    end = file_lines.index(f"end entity;\n")
                    if "generic" in file_lines[start+1]:
                        f.write(f"\t\tgeneric (\n")
                        j = start + 2
                        while file_lines[j] != ");\n": #might require \t
                            f.write(f"\t\t{file_lines[j]}")
                            j += 1
                        f.write(f"\t\t);\n")
                    f.write(f"\t\tport (\n")
                    j = j + 2
                    while file_lines[j] != ");\n":
                        f.write(f"\t\t{file_lines[j]}")
                        j += 1
                    f.write(f"\t\t);\n")
                f.write(f"\tend component;\n")            
        f.write(f"\tbegin\n\n")
        f.write(f"end architecture;\n")

    with open(f"{getcwd()}/sim/{project_name}_tb.vhd", 'w') as f:
        f.write(f"library ieee;\n")
        f.write(f"use ieee.std_logic_1164.all;\n")
        f.write(f"use ieee.numeric_std.all;\n\n")
        f.write(f"entity {project_name}_tb is\n")
        f.write(f"end entity;\n\n")
        f.write(f"architecture tb of {project_name}_tb is\n\n")
        f.write(f"\tbegin\n\n")
        f.write(f"end architecture;\n")

    # make build.yml file in syn directory
    with open(f"{getcwd()}/syn/build.yml", 'w') as f:
        f.write("#%SimplAPI=1.0\n\n")
        f.write(f"project: {project_name}\n")
        f.write(f"part: INSERT_PART_HERE\n")
        f.write(f"top: {project_name}\n\n")
        f.write(f"dependencies:\n")
        f.write(f"- ../{project_name}.yml\n")

    # make sim.yml file in sim directory
    with open(f"{getcwd()}/sim/testbench.yml", "w") as f:
        f.write("#%SimplAPI=1.0\n\n")
        f.write(f"library: work\n")
        f.write(f"top: {project_name}_tb\n\n")
        f.write(f"dependencies:\n")
        f.write(f"- ../{project_name}.yml\n")
        f.write(f"files:\n")
        f.write(f"- {project_name}_tb.vhd\n")

if __name__ == '__main__':
    main()
