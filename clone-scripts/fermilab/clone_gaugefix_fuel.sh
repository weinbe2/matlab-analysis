#! /bin/bash

# Evan S Weinberg 2016
# Clones gaugefix FUEL measurements to a new measurement directory.
# Takes one argument, the ensemble folder. 

# Define an error and quit function.
echoerr() { >&2 echo "ERROR clone_gaugefix_fuel.sh $@"; exit; }

# Check number of arguments.
if [ "$#" -ne "1" ]
then
  echoerr "Invalid number of arguments: ./clone_gaugefix_fuel.sh [ensemble name]" 
fi

ensemble=$1

# Check and make sure ensemble exists.
if [ ! -d $ensemble ]
then
  echoerr "Ensemble ${ensemble} directory does not exist!"
fi

# Check and make sure connected directory does not already exist!
if [ -d "${ensemble}/gaugefix_fuel" ]
then
  echoerr "A gaugefix_fuel directory already exists in ${ensemble} directory!"
fi

# Create a directory to save gauge fixed directories in.
if [ ! -d "${ensemble}/config_gfix" ]
then
  mkdir ${ensemble}/config_gfix
fi

# Good! Copy the base directory in.
cp -rp clone_base/gaugefix_fuel ${ensemble}

# Make the directory user+group read/writable.
find ${ensemble}/gaugefix_fuel -type d -exec chmod 775 {} +

# Make the files user+group read/writable.
find ${ensemble}/gaugefix_fuel -type f -exec chmod 664 {} +