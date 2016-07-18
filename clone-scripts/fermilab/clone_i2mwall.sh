#! /bin/bash

# Evan S Weinberg 2016
# Clones i2mwall measurements to a new measurement directory.
# Takes one argument, the ensemble folder. 

# Define an error and quit function.
echoerr() { >&2 echo "ERROR clone_i2mwall.sh $@"; exit; }

# Check number of arguments.
if [ "$#" -ne "1" ]
then
  echoerr "Invalid number of arguments: ./clone_i2mwall.sh [ensemble name]" 
fi

ensemble=$1

# Check and make sure ensemble exists.
if [ ! -d $ensemble ]
then
  echoerr "Ensemble ${ensemble} directory does not exist!"
fi

# Check and make sure i2mwall directory does not already exist!
if [ -d "${ensemble}/i2mwall" ]
then
  echoerr "A I=2 pion from moving wall source directory already exists in ${ensemble} directory!"
fi

# Good! Copy the base directory in.
cp -rp clone_base/i2mwall ${ensemble}

# Make the directory user+group read/writable.
find ${ensemble}/i2mwall -type d -exec chmod 775 {} +

# Make the files user+group read/writable.
find ${ensemble}/i2mwall -type f -exec chmod 664 {} +

chmod 775 ${ensemble}/i2mwall/parse/*.sh


