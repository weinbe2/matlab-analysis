#! /bin/bash
# parse.sh
# Does a naive extraction, without checking, of states. 
# Call: ./parse.sh ../himomf8l24t48b48m00889_ .sh-* 500 25000 80 info.dat
# 1) Beginning of file
# 2) End of file (assuming cfg number is in the middle).
# 3) starting cfg
# 4) end cfg
# 5) step size
# 6) input file where each row is a different output
#       Input file has three columns: file output, BEGIN/END flag, what column to grab besides 1.


if [ "$#" -ne "6" ]
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

while read line
do
  fname=$(echo $line | awk ' { print $1 ; } ');
  rm -rf corr/corr.${fname}
done < input.dat

for ((q=$begin_cfg;q<=$end_cfg;q+=$step_cfg))
do
  if [ -f ${begin_file}${q}${end_file} ]
  then
    while read line
    do
       fname=$(echo $line | awk ' { print $1 ; } ')
       be_str=$(echo $line | awk ' { print $2 ; } ')
       col=$(echo $line | awk ' { print $3 ; } ' )
       cut -d' ' -f"1,${col}" ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="BEGIN_${be_str}" -v ematch="END_${be_str}" ' $0 ~ bmatch {flag=1;next} $0 ~ ematch {flag=0} flag { printf "%d %s\n",cfg,$0 }' >> corr/corr.${fname}
    done < input.dat
  fi
done

