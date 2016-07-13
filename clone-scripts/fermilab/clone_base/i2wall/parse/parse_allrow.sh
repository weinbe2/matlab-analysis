#! /bin/bash
# parse.sh
# Does a naive extraction, without checking, of states. 
# ./parse_allrow.sh ../i2wallf21l16t48b6586m0194_ .sh-* 1000 3000 40 input.dat 500
# For i=2, call:  ./parse.sh ../i2wallf8l16t32b50m060_ .sh-* 260 1250 10 input.dat [060]
# 1) Beginning of file
# 2) End of file (assuming cfg number is in the middle).
# 3) starting cfg
# 4) end cfg
# 5) step size
# 6) input file where each row is a different output
#       Input file has three columns: file output, BEGIN/END flag, what column to grab besides 1.
#       0 means grab the whole row.
# 7) A line number to start parsing a file from---this means we only look for
#       BEGIN/END flags after this line.
# 8) optional: append a non-unitary mass to the filename.


if [ "$#" -ne "7" ] && [ "$#" -ne "8" ]
then
  echo "Incorrect number of arguments."
  exit
fi

begin_file=$1
end_file=$2
begin_cfg=$3
end_cfg=$4
step_cfg=$5
info_file=$6
line_skip=$7
mass_end=""
if [ "$#" -eq "8" ]
then
  mass="_"$8
  mass_end="_"$8
fi

while read line
do
  fname=$(echo $line | awk ' { print $1 ; } ');
  rm -rf corr/corr.${fname}${mass_end}
done < $info_file

for ((q=$begin_cfg;q<=$end_cfg;q+=$step_cfg))
do
  if [ -f ${begin_file}${q}${end_file} ]
  then
    while read line
    do
       fname=$(echo $line | awk ' { print $1 ; } ')
       be_str=$(echo $line | awk ' { print $2 ; } ')
       col=$(echo $line | awk ' { print $3 ; } ' )
       if [ "${col}" -ne "0" ]
       then
         tail -n +${line_skip} ${begin_file}${q}${end_file} | cut -d' ' -f"1,${col}" | awk -v cfg="${q}" -v bmatch="BEGIN_${be_str}" -v ematch="END_${be_str}" ' $0 ~ bmatch {flag=1;next} $0 ~ ematch {flag=0} flag { printf "%d %s\n",cfg,$0 }' >> corr/corr.${fname}${mass_end}
       else
         tail -n +${line_skip} ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="BEGIN_${be_str}" -v ematch="END_${be_str}" ' $0 ~ bmatch {flag=1;next} $0 ~ ematch {flag=0} flag { printf "%d %s\n",cfg,$0 }' >> corr/corr.${fname}${mass_end}
       fi
    done < $info_file
  fi
done

chmod 664 corr/*

