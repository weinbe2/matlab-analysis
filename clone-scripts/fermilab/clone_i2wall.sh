#! /bin/bash

# Evan S Weinberg 2016
# Clones i2wall measurements to a new measurement directory.
# Takes one argument, the ensemble folder. 

# Define an error and quit function.
echoerr() { >&2 echo "ERROR clone_i2wall.sh $@"; exit; }

# Check number of arguments.
if [ "$#" -ne "1" ]
then
  echoerr "Invalid number of arguments: ./clone_i2wall.sh [ensemble name]" 
fi

ensemble=$1

# Check and make sure ensemble exists.
if [ ! -d $ensemble ]
then
  echoerr "Ensemble ${ensemble} directory does not exist!"
fi

# Check and make sure i2wall directory does not already exist!
if [ -d "${ensemble}/i2wall" ]
then
  echoerr "A I=2 pion from wall source directory already exists in ${ensemble} directory!"
fi

# Good! Copy the base directory in.
cp -rp clone_base/i2wall ${ensemble}

# Make the directory user+group read/writable.
find ${ensemble}/i2wall -type d -exec chmod 775 {} +

# Make the files user+group read/writable.
find ${ensemble}/i2wall -type f -exec chmod 664 {} +