#! /bin/bash

# Evan S Weinberg 2016
# Clones decay measurements to a new measurement directory.
# Takes one argument, the ensemble folder. 

# Define an error and quit function.
echoerr() { >&2 echo "ERROR clone_decay.sh $@"; exit; }

# Check number of arguments.
if [ "$#" -ne "1" ]
then
  echoerr "Invalid number of arguments: ./clone_decay.sh [ensemble name]" 
fi

ensemble=$1

# Check and make sure ensemble exists.
if [ ! -d $ensemble ]
then
  echoerr "Ensemble ${ensemble} directory does not exist!"
fi

# Check and make sure decay directory does not already exist!
if [ -d "${ensemble}/decay" ]
then
  echoerr "A decay directory already exists in ${ensemble} directory!"
fi

# Good! Copy the base directory in.
cp -rp clone_base/decay ${ensemble}

# Make the directory user+group read/writable.
find ${ensemble}/decay -type d -exec chmod 775 {} +

# Make the files user+group read/writable.
find ${ensemble}/decay -type f -exec chmod 664 {} +

chmod 775 ${ensemble}/decay/parse/*.sh


