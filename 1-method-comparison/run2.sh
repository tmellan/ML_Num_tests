#!/bin/bash



for i in `echo {24..27}.*.m`; do 
  
  module load mathematica
  wolfram -script $i > predictions/$i.out &
  wait
done
wait
echo $done

#wolfram -script 20.linear.knn.rf.xdt.dt.18train.12val.25feature.m > predictions/20.linear.knn.rf.xdt.dt.18train.12val.25feature.m.out &
#wolfram -script 22.linear.knn.rf.xdt.dt.30train.12val.25feature.m > predictions/22.linear.knn.rf.xdt.dt.30train.12val.25feature.m.out &
#wait
#module load mathematica
#wolfram -script 23.linear.knn.rf.xdt.dt.36train.12val.25feature.m > predictions/23.linear.knn.rf.xdt.dt.36train.12val.25feature.m.out &
#wolfram -script 21.linear.knn.rf.xdt.dt.24train.12val.25feature.m > predictions/21.linear.knn.rf.xdt.dt.24train.12val.25feature.m.out &
#wait
#echo done
