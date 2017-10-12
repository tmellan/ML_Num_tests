#!/bin/bash

list="15.linear.knn.rf.xdt.dt.12train.12val.10feature.m 16.linear.knn.rf.xdt.dt.12train.12val.15feature.m 17.linear.knn.rf.xdt.dt.12train.12val.25feature.m 18.linear.knn.rf.xdt.dt.12train.12val.30feature.m 19.linear.knn.rf.xdt.dt.12train.12val.40feature.m"
dir=`pwd`

for i in $list; do 
  module load mathematica
  wolfram -script $i > $dir/predictions/$i.out &
  wait
  echo $i done waitin
done
echo COMPLETE
