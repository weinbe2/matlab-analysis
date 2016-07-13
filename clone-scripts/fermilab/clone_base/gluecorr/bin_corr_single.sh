#! /bin/bash

# Calculate r^2, sort by r^2, bin by equal r^2, sort by r^2 again, print "[r] [binned value]"

awk ' { x=($1*$1+$2*$2+$3*$3+$4*$4) ; print x,$5 } ' $1 | sort -k1 -n | awk '
    NR>=1{
        arr[$1]   += $2
        count[$1] += 1
    }
    END{
        for (a in arr) {
            printf "%d %.15e\n",a,(arr[a] / count[a])
        }
    }
' | sort -k1 -n | awk ' { printf "%.15e %s\n",sqrt($1),$2 } ' > $2
