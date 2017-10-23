#!/bin/bash


c=0
for i in {28..34}; do 
  echo doing $i

  let c=c+12
  
  echo "prep Files"

  name=$(echo $i.linear.knn.xdt.$c"train".12val.3feat_5_15_38.m)
  cp X.linear.knn.xdt.Ytrain.12val.3feat_5_15_38.m $name
  sed -i 's/xxNAMExx/'$name'.out/g' $name
  sed -i 's/xxTRAINSETSIZExx/'$c'/g' $name

  echo "run ML training and prediction"
  module load mathematica
  sleep 10
  echo "running wolfram on " $name
  nice -10  wolfram -script $name > predictions/$name.out &
  wait
  echo "completed wolfram on " $name
  sleep 10
done
wait
echo $done

