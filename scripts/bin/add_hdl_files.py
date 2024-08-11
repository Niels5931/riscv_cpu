#!/usr/bin/env python3.9

from os import chdir, listdir, getcwd
from sys import argv

def main():
    # Get the name of the project from the command line
    project_name = argv[1].strip('/')
    # Change to the project directory
    chdir(f"{getcwd()}/cores/{project_name}")
    # read all hdl files in the hdl directory
    hdl_files = [f for f in listdir('hdl') if f.endswith('.vhd')]
    # open the project yml file
    if "files:" not in open(f"{project_name}.yml").read():
        with open(f"{project_name}.yml", 'a') as f:
            f.write("\nfiles:\n")
            for hdl_file in hdl_files:
                f.write(f"- hdl/{hdl_file}\n")
    else:
        with open(f"{project_name}.yml", 'a') as f:
            for hdl_file in hdl_files:
                if hdl_file not in open(f"{project_name}.yml").read():
                    f.write(f"- hdl/{hdl_file}\n")

if __name__ == '__main__':
    main()