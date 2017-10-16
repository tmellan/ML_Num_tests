#!/bin/bash
a=25
b=25
c=48
grep -o -P 'LinearRegression, .{0,55}' $a.linear.knn.rf.xdt.dt.$c"train".12val.$b"feature.m.out" | tail -n 12 | awk '{print $4}' > lin.tmp
grep -o -P 'GradientBoostedTrees, .{0,55}' $a.linear.knn.rf.xdt.dt.$c"train".12val.$b"feature.m.out" | tail -n 12 | awk '{print $4}' > grad.tmp
#grep -o -P 'RandomForest, .{0,55}' $a.linear.knn.rf.xdt.dt.$c"train".12val.$b"feature.m.out" | tail -n 12 | awk '{print $4}' > rf.tmp
#grep -o -P 'DecisionTree, .{0,55}' $a.linear.knn.rf.xdt.dt.$c"train".12val.$b"feature.m.out" | tail -n 12 | awk '{print $4}' > dt.tmp
grep -o -P 'NearestNeighbors, .{0,55}' $a.linear.knn.rf.xdt.dt.$c"train".12val.$b"feature.m.out" | tail -n 12 | awk '{print $4}' > nn.tmp

echo Linear GradBoost kNN > name.tmp
paste lin.tmp grad.tmp nn.tmp > out.tmp
cat name.tmp out.tmp | column -t > ML.$a.$c.$b.out
rm *.tmp
