#!/usr/bin/env python3.9

from os import getenv
from sys import argv

def main():
    work_dir = f"{getenv('PROJECT_ROOT')}/cores/{argv[1]}"
    # read the top hdl file
    top_file = open(f"{work_dir}/hdl/{argv[1]}.vhd", 'r').readlines()
    # get port list
    #generic_start = top_file.index("generic (\n")
    #generic_end = top_file.index(");\n")
    ports_start = top_file.index("port (\n")
    ports_end = [i for i in enumerate(top_file) if i[1] == ");\n"][0][0]
    # get the port list
    ports = top_file[ports_start+1:ports_end]
    # get the generic list
    #generics = top_file[generic_start+1:generic_end]

    signal_list = []

    for p in ports:
        if not p.strip().startswith("--"):
            #print(p)
            port_name = p.split(":")[0].strip()
            port_direction = p.split(":")[1].split()[0].strip()
            port_type = p.split(":")[1].split(";")[0].strip()
            #print(port_direction)
            if "in" in port_direction:
                signal_list.append(f"\tsignal {port_name.replace('_i','_in_s')}: {port_type.replace('in','')};\n")
            else:
                signal_list.append(f"\tsignal {port_name.replace('_o','_out_s')}: {port_type.replace('out','')};\n")

    #print(signal_list)

    with open (f"{work_dir}/sim/{argv[1]}_tb.vhd", 'w') as f:
        f.write(f"library ieee;\n")
        f.write(f"use ieee.std_logic_1164.all;\n")
        f.write(f"use ieee.numeric_std.all;\n\n")
        f.write(f"entity {argv[1]}_tb is\n")
        f.write(f"end entity;\n\n")
        f.write(f"architecture rtl of {argv[1]}_tb is\n\n")
        f.write(f"\tcomponent {argv[1]} is\n")
        #f.write(f"generic (\n")
        #for g in generics:
        #    f.write(f"\t{g}")
        #f.write(f");\n")
        f.write(f"\tport (\n")
        for p in ports:
            f.write(f"\t{p}")
        f.write(f"\t);\n")
        f.write(f"\tend component;\n\n")
        for s in signal_list:
            f.write(s)
        
        f.write(f"\nbegin\n\n")
        f.write(f"\tDUT: {argv[1]} port map (\n")
        for p in ports:
            if not p.strip().startswith("--"):
                if not p == ports[-1]:
                    f.write(f"\t\t{p.split(':')[0].strip()} => {p.split(':')[0].strip().replace('_i','_in_s').replace('_o','_out_s')},\n")  
                else:
                    f.write(f"\t\t{p.split(':')[0].strip()} => {p.split(':')[0].strip().replace('_i','_in_s').replace('_o','_out_s')}\n")
        f.write(f"\t);\n\n")
        f.write(f"end architecture;\n")


if __name__ == "__main__":
    main()
            

