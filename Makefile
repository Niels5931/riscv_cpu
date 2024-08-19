TARGET?=$(PROJECT_NAME)

SHELL := /bin/bash

clean:
	@rm -rf cores/* 

sim:
	echo "Running simulation of $(TARGET)"
	cd cores/$(TARGET)/sim && simpl xsim

build:
	source source_simpl
	echo "Building $(TARGET)"
	cd cores/$(TARGET)/syn && simpl vivado

project:
	echo "Creating project for $(TARGET)"
	make_project.py $(TARGET)
	cd cores/$(TARGET)/_project/ && vivado -mode tcl -source project.tcl
	cd cores/$(TARGET)/_project/ && vivado project.xpr

open:
	cd cores/$(TARGET)/_project/ && vivado project.xpr

check_syntax:
	source source_simpl && check_syntax.py $(TARGET)