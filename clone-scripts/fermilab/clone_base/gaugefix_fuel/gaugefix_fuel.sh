#!/bin/bash
#PBS -q ds
#PBS -r n
#PBS -l nodes=1,walltime=00:20:00
#PBS -A LSD

# These scripts based on scripts by owitzel

#    1)   qsub -N connf8l24t48b48m00889_500.sh gluecorr.sh

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
   BINARY='/lqcdproj/LSD/8f/bin/USQCD/install_ds/qhmc/bin/qhmc  '

   export LD_LIBRARY_PATH=/usr/local/gcc-4.5.1/lib:/usr/local/gcc-4.5.1/lib64:/usr/local/mvapich2/lib:/usr/local/mvapich2/lib/shared:/usr/local/ofed/lib64:$LD_LIBRARY_PATH
   export PATH=/usr/local/gcc-4.5.1/bin:/usr/local/mvapich2/bin:$PATH

   MPIRUN="/usr/local/mvapich2/bin/mpirun "
   #NUMA="/usr/local/mvapich2/bin/numa_32_mv2"
   NUMA=""
   
   
elif  [ $bflag -ne 0 ] ; then
   BINARY='/lqcdproj/LSD/8f/bin/USQCD/install_bc/qhmc/bin/qhmc  '

   export PATH=/usr/local/mvapich2/bin:/usr/local/gcc-4.8.1/bin:$PATH
   export LD_LIBRARY_PATH=/usr/local/mvapich2/lib:/usr/local/gcc-4.8.1/lib:/usr/local/gcc-4.8.1/lib64:/usr/local/ofed/lib64:$LD_LIBRARY_PATH

   MPIRUN="/usr/local/mvapich2/bin/mpirun "
   source /usr/local/mvapich2/etc/mvapich2.conf.sh
   #NUMA="/usr/local/mvapich2/bin/numa_32_mv2"
   NUMA=""
   
elif [ $pflag -ne 0 ] ; then
   BINARY='/lqcdproj/LSD/8f/bin/USQCD/install_pi0/qhmc/bin/qhmc  '
   
   export PATH=/usr/local/mvapich2/bin:/usr/local/gcc-4.9.1/bin:$PATH
   export LD_LIBRARY_PATH=/usr/local/mvapich2/lib:/usr/local/gcc-4.9.1/lib:/usr/local/gcc-4.9.1/lib64:/usr/local/ofed/lib64:$LD_LIBRARY_PATH 
   MPIRUN="/usr/local/mvapich2/bin/mpirun "
   NUMA=" "
fi

src="./gaugefix_meas"

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

input="${src}_${config}.lua "
sed -e "s/:L:/${L}/g" -e "s/:T:/${T}/g" -e "s/:CONFIG:/${config}/g" -e "s/:MASS:/${M}/g" < "${src}.lua" > ${input}


####
echo "==============================================================="
echo "                    FUEL SCRIPT                                " 
echo "==============================================================="
cat ${input} 
echo "==============================================================="
###

 
#/project/rhqbbar/Scripts/MemCheck.pl &

# Command:

cmd="${MPIRUN} -np ${NCORES} ${NUMA} ${BINARY} ${input}"

echo $cmd

${MPIRUN} -np ${NCORES} ${NUMA} ${BINARY} ${input}

# Fix permissions.
chmod 664 ${input}
chmod 664 ./${PBS_O_WORKDIR}/${PBS_JOBNAME}-${PBS_JOBID}.out 2>&1


echo "done"
echo "# time-finish "`date`
