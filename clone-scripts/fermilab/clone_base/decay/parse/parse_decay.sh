#! /bin/bash
# parse.sh
# Does a naive extraction, without checking, of states. 
# Call: ./parse_decay.sh ../decayf8l16t32b50m060_ .sh-* 260 1250 10 32 [080]
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

fname=pll
rm -rf corr/corr.${fname}${mass_end}

fname=plc
rm -rf corr/corr.${fname}${mass_end}

fname=pcc
rm -rf corr/corr.${fname}${mass_end}

fname=rll
rm -rf corr/corr.${fname}${mass_end}

fname=rllx
rm -rf corr/corr.${fname}${mass_end}

fname=rlly
rm -rf corr/corr.${fname}${mass_end}

fname=rllz
rm -rf corr/corr.${fname}${mass_end}

fname=all
rm -rf corr/corr.${fname}${mass_end}

fname=allx
rm -rf corr/corr.${fname}${mass_end}

fname=ally
rm -rf corr/corr.${fname}${mass_end}

fname=allz
rm -rf corr/corr.${fname}${mass_end}

fname=rcc
rm -rf corr/corr.${fname}${mass_end}

fname=rccx
rm -rf corr/corr.${fname}${mass_end}

fname=rccy
rm -rf corr/corr.${fname}${mass_end}

fname=rccz
rm -rf corr/corr.${fname}${mass_end}

fname=acc
rm -rf corr/corr.${fname}${mass_end}

fname=accx
rm -rf corr/corr.${fname}${mass_end}

fname=accy
rm -rf corr/corr.${fname}${mass_end}

fname=accz
rm -rf corr/corr.${fname}${mass_end}


for ((q=$begin_cfg;q<=$end_cfg;q+=$step_cfg))
do
  if [ -f ${begin_file}${q}${end_file} ]
  then
    fname="pll"
    b_str="SINKS: PION_LL PION_LC PION_CC"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ; } $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0} flag == 1 && flag2 == 2 && t < nt { printf "%d %d %.15e\n",cfg,$1,$2 ; t=t+1; }' >> corr/corr.${fname}${mass_end}
    
    fname="plc"
    b_str="SINKS: PION_LL PION_LC PION_CC"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ; } $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0} flag == 1 && flag2 == 2 && t < nt { printf "%d %d %.15e\n",cfg,$1,$4 ; t=t+1; }' >> corr/corr.${fname}${mass_end}
    
    fname="pcc"
    b_str="SINKS: PION_LL PION_LC PION_CC"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ; } $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0} flag == 1 && flag2 == 2 && t < nt { printf "%d %d %.15e\n",cfg,$1,$6 ; t=t+1; }' >> corr/corr.${fname}${mass_end}
    
    fname="rll"
    b_str="SINKS: RHO_LL RHO_LL_X RHO_LL_Y RHO_LL_Z AXIAL_LL AXIAL_LL_X AXIAL_LL_Y AXIAL_LL_Z"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ;} $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0; next;} flag == 1 && flag2 == 2 && t < nt { printf "%d %d %.15e\n",cfg,$1,$2 ; t=t+1; }' >> corr/corr.${fname}${mass_end}
    
    fname="rllx"
    b_str="SINKS: RHO_LL RHO_LL_X RHO_LL_Y RHO_LL_Z AXIAL_LL AXIAL_LL_X AXIAL_LL_Y AXIAL_LL_Z"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ;} $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0; next;} flag == 1 && flag2 == 2 && t < nt { printf "%d %d %.15e\n",cfg,$1,$4 ; t=t+1; }' >> corr/corr.${fname}${mass_end}
    
    fname="rlly"
    b_str="SINKS: RHO_LL RHO_LL_X RHO_LL_Y RHO_LL_Z AXIAL_LL AXIAL_LL_X AXIAL_LL_Y AXIAL_LL_Z"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ;} $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0; next;} flag == 1 && flag2 == 2 && t < nt { printf "%d %d %.15e\n",cfg,$1,$6 ; t=t+1; }' >> corr/corr.${fname}${mass_end}
    
    fname="rllz"
    b_str="SINKS: RHO_LL RHO_LL_X RHO_LL_Y RHO_LL_Z AXIAL_LL AXIAL_LL_X AXIAL_LL_Y AXIAL_LL_Z"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ;} $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0; next;} flag == 1 && flag2 == 2 && t < nt { printf "%d %d %.15e\n",cfg,$1,$8 ; t=t+1; }' >> corr/corr.${fname}${mass_end}
    
    fname="all"
    b_str="SINKS: RHO_LL RHO_LL_X RHO_LL_Y RHO_LL_Z AXIAL_LL AXIAL_LL_X AXIAL_LL_Y AXIAL_LL_Z"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ;} $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0; next;} flag == 1 && flag2 == 2 && t < nt { printf "%d %d %.15e\n",cfg,$1,$10 ; t=t+1; }' >> corr/corr.${fname}${mass_end}
    
    fname="allx"
    b_str="SINKS: RHO_LL RHO_LL_X RHO_LL_Y RHO_LL_Z AXIAL_LL AXIAL_LL_X AXIAL_LL_Y AXIAL_LL_Z"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ;} $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0; next;} flag == 1 && flag2 == 2 && t < nt { printf "%d %d %.15e\n",cfg,$1,$12 ; t=t+1; }' >> corr/corr.${fname}${mass_end}
    
    fname="ally"
    b_str="SINKS: RHO_LL RHO_LL_X RHO_LL_Y RHO_LL_Z AXIAL_LL AXIAL_LL_X AXIAL_LL_Y AXIAL_LL_Z"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ;} $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0; next;} flag == 1 && flag2 == 2 && t < nt { printf "%d %d %.15e\n",cfg,$1,$14 ; t=t+1; }' >> corr/corr.${fname}${mass_end}
    
    fname="allz"
    b_str="SINKS: RHO_LL RHO_LL_X RHO_LL_Y RHO_LL_Z AXIAL_LL AXIAL_LL_X AXIAL_LL_Y AXIAL_LL_Z"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ;} $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0; next;} flag == 1 && flag2 == 2 && t < nt { printf "%d %d %.15e\n",cfg,$1,$16 ; t=t+1; }' >> corr/corr.${fname}${mass_end}
    
    fname="rcc"
    b_str="SINKS: RHO_CC RHO_CC_X RHO_CC_Y RHO_CC_Z AXIAL_CC AXIAL_CC_X AXIAL_CC_Y AXIAL_CC_Z"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ; } $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0} flag == 1 && flag2 == 2 && t < nt  { printf "%d %d %.15e\n",cfg,$1,$2 ; t=t+1 ; }' >> corr/corr.${fname}${mass_end}
    
    fname="rccx"
    b_str="SINKS: RHO_CC RHO_CC_X RHO_CC_Y RHO_CC_Z AXIAL_CC AXIAL_CC_X AXIAL_CC_Y AXIAL_CC_Z"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ; } $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0} flag == 1 && flag2 == 2 && t < nt  { printf "%d %d %.15e\n",cfg,$1,$4 ; t=t+1 ; }' >> corr/corr.${fname}${mass_end}
    
    fname="rccy"
    b_str="SINKS: RHO_CC RHO_CC_X RHO_CC_Y RHO_CC_Z AXIAL_CC AXIAL_CC_X AXIAL_CC_Y AXIAL_CC_Z"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ; } $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0} flag == 1 && flag2 == 2 && t < nt  { printf "%d %d %.15e\n",cfg,$1,$6 ; t=t+1 ; }' >> corr/corr.${fname}${mass_end}
    
    fname="rccz"
    b_str="SINKS: RHO_CC RHO_CC_X RHO_CC_Y RHO_CC_Z AXIAL_CC AXIAL_CC_X AXIAL_CC_Y AXIAL_CC_Z"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ; } $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0} flag == 1 && flag2 == 2 && t < nt  { printf "%d %d %.15e\n",cfg,$1,$8 ; t=t+1 ; }' >> corr/corr.${fname}${mass_end}
    
    fname="acc"
    b_str="SINKS: RHO_CC RHO_CC_X RHO_CC_Y RHO_CC_Z AXIAL_CC AXIAL_CC_X AXIAL_CC_Y AXIAL_CC_Z"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ; } $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0} flag == 1 && flag2 == 2 && t < nt  { printf "%d %d %.15e\n",cfg,$1,$10 ; t=t+1 ; }' >> corr/corr.${fname}${mass_end}
    
    fname="accx"
    b_str="SINKS: RHO_CC RHO_CC_X RHO_CC_Y RHO_CC_Z AXIAL_CC AXIAL_CC_X AXIAL_CC_Y AXIAL_CC_Z"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ; } $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0} flag == 1 && flag2 == 2 && t < nt  { printf "%d %d %.15e\n",cfg,$1,$12 ; t=t+1 ; }' >> corr/corr.${fname}${mass_end}
    
    fname="accy"
    b_str="SINKS: RHO_CC RHO_CC_X RHO_CC_Y RHO_CC_Z AXIAL_CC AXIAL_CC_X AXIAL_CC_Y AXIAL_CC_Z"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ; } $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0} flag == 1 && flag2 == 2 && t < nt  { printf "%d %d %.15e\n",cfg,$1,$14 ; t=t+1 ; }' >> corr/corr.${fname}${mass_end}
    
    fname="accz"
    b_str="SINKS: RHO_CC RHO_CC_X RHO_CC_Y RHO_CC_Z AXIAL_CC AXIAL_CC_X AXIAL_CC_Y AXIAL_CC_Z"
    e_str="ENDPROP"
    cat ${begin_file}${q}${end_file} | awk -v cfg="${q}" -v bmatch="${b_str}" -v ematch="${e_str}" -v nt="${nt}" ' BEGIN { flag=0; flag2=0 ; } $0 ~ bmatch {flag2=flag2+1; flag=flag+1;next} $0 ~ ematch {flag=0} flag == 1 && flag2 == 2 && t < nt  { printf "%d %d %.15e\n",cfg,$1,$16 ; t=t+1 ; }' >> corr/corr.${fname}${mass_end}
  fi
    
done

chmod 664 corr/*
