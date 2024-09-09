#!/usr/bin/env python3.9
from os import mkdir, chdir, getcwd, listdir, getenv, path
from sys import argv
import argparse
from remove_project import rm_dir

def get_component_list(dependencies=None):
    if dependencies == None:
        return

    port_list = []

    for comp in dependencies:
        #print(comp)
        comp_lines = open(f"{getenv('PROJECT_ROOT')}/cores/{comp}/hdl/{comp}.vhd").readlines()
        comp_lines = [line.strip() for line in comp_lines]
        try:
            generic_start = comp_lines.index("generic (")
            generic_end = comp_lines.index(");")
        except:
            generic_start = None
            generic_end = None
        try:
            port_start = comp_lines.index("port (")
            port_end = comp_lines.index("end entity;")
        except:
            port_start = None
            port_end = None

        #print(generic_start, generic_end)
        #print(port_start, port_end)

        if generic_start:
            for i in range(generic_start+1, generic_end):
                comp_lines[i] = "\t" + comp_lines[i]

        if port_start:
            for i in range(port_start+1, port_end-1):
                comp_lines[i] = "\t" + comp_lines[i]    

        if generic_start or port_start:
            port_list.append(f"component {comp}")

        if generic_start:
            port_list.extend(comp_lines[generic_start:generic_end+1])
        if port_start:
            port_list.extend(comp_lines[port_start:port_end])

        if generic_start or port_start:
            port_list.append(f"end component;\n")

    #print(port_list)

    return port_list
            


def main():
    
    argparser = argparse.ArgumentParser(description="Create a new project template")
    argparser.add_argument("project_name", help="Name of the project")
    argparser.add_argument("-d", "--dependencies", nargs='+', help="List of dependencies")
    argparser.add_argument("-p", "--part", help="Part number", default="xc7a35tcpg236-1")
    args = argparser.parse_args()
    

    project_root = getenv("PROJECT_ROOT")
    # Get the name of the project from the command line
    project_name = args.project_name
    # check if the project directory exists
    if path.isdir(f"{project_root}/cores/{project_name}"):
        rm_dir(f"{project_root}/cores/{project_name}")
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
            comoponent_list = get_component_list(args.dependencies)           
            for line in comoponent_list:
                f.write("\t" + line + "\n")
        f.write(f"begin\n\n")
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
        f.write(f"part: {args.part}\n")
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
