#!/bin/bash
#PBS -q ds
#PBS -r n
#PBS -l nodes=1,walltime=00:20:00
#PBS -A LSD

# These scripts based on scripts by owitzel

#    1)   qsub -N gcrf8l24t48b48m00889_500.sh gluecorr.sh

### create files with read permissions for everyone 
umask 022

### immediately write a combined stdout / stderr file
exec >   ${PBS_O_WORKDIR}/${PBS_JOBNAME}-${PBS_JOBID}.out 2>&1

dflag=`hostname | grep -c ds `
bflag=`hostname | grep -c bc `
pflag=`hostname | grep -c pi `

echo $dflag
echo $bflag
echo $pflag

echo "# time-start "`date`

### determine the number of allocated nodes and cores
if [ $pflag -ne 0 ] ; then
   CpN=16
else
   CpN=32
fi
NNODES=`cat ${PBS_NODEFILE} | wc -l`
NCORES=$[${NNODES}*${CpN}]

echo "Files in /scratch/"
ls -l /scratch/

### cd to directory where the job was submitted
cd ${PBS_O_WORKDIR}

echo "--------------------------------"
echo "PBS job running on: `hostname`"
echo "in directory:       `pwd`"
echo "PBS jobid:          ${PBS_JOBID}"
echo "nodes:              ${NNODES}"
echo "cores:              ${NCORES}"
echo "Nodefile:"
cat ${PBS_NODEFILE}
echo "--------------------------------"


############################################################## 
### enter your bash commands here

if  [ $dflag -ne 0 ] ; then
   BINARY='/lqcdproj/LSD/8f/install/GLU/bin/GLU '
elif  [ $bflag -ne 0 ] ; then
   BINARY='/lqcdproj/LSD/8f/install/GLU/bin/GLU ' # untested
elif [ $pflag -ne 0 ] ; then
   BINARY='/lqcdproj/LSD/8f/install/GLU/bin/GLU ' # untested
fi

src="gfix_cfg"

# Extract configuration number from jobname (use -N for submission)
i=`expr index "${PBS_JOBNAME}" _`
j=`expr index "${PBS_JOBNAME}" .`
runname=${PBS_JOBNAME:0:$i-1}
echo "runname: ${runname}"
config=${PBS_JOBNAME:$i:$j-$i-1}
echo "config: ${config}"

short_runname=`echo $runname | sed -e s/gfix//`

run=${PBS_JOBNAME}
fname=`echo $run | sed -e s/.sh// -e s/gfix//`
x=`echo $fname | sed -e s/plus/xxxx/`
l=`expr index $x l`
t=`expr index $x t`
b=`expr index $x b`
m=`expr index $x m`
u=`expr index $x _`
T=${x:$t:$b-$t-1}
L=${x:$l:$t-$l-1}
M=${x:$m:$u-$m-1}
echo $M

echo "fname: ${fname}"
pname=`pwd`
#echo "pname ${pname}"
jname=`basename ${pname}`
#echo "jname: ${jname}"
seed=$RANDOM
echo "Seed: ${seed}"

input="${src}_${config} "
sed -e "s/:CFG_NAME:/${short_runname}/g" -e "s/:CFG_NUM:/$config/g" -e "s/:MEAS_NAME:/${fname}/g" < ${src} > ${input}


####
echo "==============================================================="
echo "                    GLU SCRIPT                                 " 
echo "==============================================================="
cat ${input} 
echo "==============================================================="
###

 
#/project/rhqbbar/Scripts/MemCheck.pl &

# Command:

cmd="${BINARY} -c ${input} -i /lqcdproj/LSD/8f/${short_runname}/config/config.${config}.lime -o /lqcdproj/LSD/8f/${short_runname}/config_gfix/config.${config}.gfix.lime"

echo $cmd

# Output filename doesn't matter!
${BINARY} -c ${input} -i /lqcdproj/LSD/8f/${short_runname}/config/config.${config}.lime -o /lqcdproj/LSD/8f/${short_runname}/config_gfix/config.${config}.gfix.lime


echo "done"
echo "# time-finish "`date`
