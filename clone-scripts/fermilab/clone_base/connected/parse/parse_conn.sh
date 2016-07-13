#! /bin/bash
# parse.sh
# Does a naive extraction, without checking, of states. 
# Call: ./parse_conn.sh ../connf8l16t32b50m060_ .sh-* 260 1250 10 32 [080]
# 1) Beginning of file
# 2) End of file (assuming cfg number is in the middle).
# 3) starting cfg
# 4) end cfg
# 5) step size
# 6) nt
# 7) OPTIONAL: partially quenched mass ending.


if [ "$#" -ne "6" ] && [ "$#" -ne "7" ]
then
  echo "Incorrect number of arguments."
  exit
fi

begin_file=$1
end_file=$2
begin_cfg=$3
end_cfg=$4
step_cfg=$5
nt=$6
mass_end=""
if [ "$#" -eq "7" ]
then
  mass_end="_"$7
fi

# Clean up.

fname=ps2
rm -rf corr/corr.${fname}${mass_end}

fname=ps
rm -rf corr/corr.${fname}${mass_end}

fname=sc
rm -rf corr/corr.${fname}${mass_end}

fname=i5
rm -rf corr/corr.${fname}${mass_end}

fname=ij
rm -rf corr/corr.${fname}${mass_end}

fname=r0
rm -rf corr/corr.${fname}${mass_end}

fname=ris
rm -rf corr/corr.${fname}${mass_end}

fname=rij
rm -rf corr/corr.${fname}${mass_end}

fname=ri5
rm -rf corr/corr.${fname}${mass_end}

fname=nu
rm -rf corr/corr.${fname}${mass_end}

fname=de
rm -rf corr/corr.${fname}${mass_end}


for ((q=$begin_cfg;q<=$end_cfg;q+=$step_cfg))
do
  if [ -f ${begin_file}${q}${end_file} ]
  then
    fname="ps2"
    b_str="SINKS: POINT_KAON_5 WALL_KAON_5"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ; } $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0} flag == 1 && flag2 == 2 && t < nt { printf "%d %d %.15e\n",cfg,$1,$2 ; t=t+1; }' >> corr/corr.${fname}${mass_end}
    
    fname="ps"
    b_str="SINKS: PION_PS PION_SC PION_i5 PION_ij"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ;} $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0; next;} flag == 1 && flag2 == 2 && t < nt { printf "%d %d %.15e\n",cfg,$1,$2 ; t=t+1; }' >> corr/corr.${fname}${mass_end}
    
    fname="sc"
    b_str="SINKS: PION_PS PION_SC PION_i5 PION_ij"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ; } $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0} flag == 1 && flag2 == 2 && t < nt  { printf "%d %d %.15e\n",cfg,$1,$4 ; t=t+1 ; }' >> corr/corr.${fname}${mass_end}
    
    fname="i5"
    b_str="SINKS: PION_PS PION_SC PION_i5 PION_ij"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ; } $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0} flag == 1 && flag2 == 2 && t < nt { printf "%d %d %.15e\n",cfg,$1,$6 ; t=t+1 ; }' >> corr/corr.${fname}${mass_end}
    
    fname="ij"
    b_str="SINKS: PION_PS PION_SC PION_i5 PION_ij"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ; } $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0} flag == 1 && flag2 == 2 && t < nt { printf "%d %d %.15e\n",cfg,$1,$8 ; t=t+1 ; }' >> corr/corr.${fname}${mass_end}
  fi
  
    fname="r0"
    b_str="SINKS: RHO_0 RHO_is RHO_ij RHO_i5"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ; } $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0} flag == 1 && flag2 == 2 && t < nt { printf "%d %d %.15e\n",cfg,$1,$2 ; t=t+1 ; }' >> corr/corr.${fname}${mass_end}
    
    fname="ris"
    b_str="SINKS: RHO_0 RHO_is RHO_ij RHO_i5"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ; } $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0} flag == 1 && flag2 == 2 && t < nt { printf "%d %d %.15e\n",cfg,$1,$4 ; t=t+1 ; }' >> corr/corr.${fname}${mass_end}
    
    fname="rij"
    b_str="SINKS: RHO_0 RHO_is RHO_ij RHO_i5"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ; } $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0} flag == 1 && flag2 == 2 && t < nt { printf "%d %d %.15e\n",cfg,$1,$6 ; t=t+1 ; }' >> corr/corr.${fname}${mass_end}
    
    fname="ri5"
    b_str="SINKS: RHO_0 RHO_is RHO_ij RHO_i5"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ; } $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0} flag == 1 && flag2 == 2 && t < nt { printf "%d %d %.15e\n",cfg,$1,$8 ; t=t+1 ; }' >> corr/corr.${fname}${mass_end}
    
    fname="nu"
    b_str="SINKS: NUCLEON DELTA"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ; } $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0} flag == 1 && flag2 == 2 && t < nt { printf "%d %d %.15e\n",cfg,$1,$2 ; t=t+1 ; }' >> corr/corr.${fname}${mass_end}
    
    fname="de"
    b_str="SINKS: NUCLEON DELTA"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ; } $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0} flag == 1 && flag2 == 2 && t < nt { printf "%d %d %.15e\n",cfg,$1,$4 ; t=t+1 ; }' >> corr/corr.${fname}${mass_end}
    
done

chmod 664 corr/*
