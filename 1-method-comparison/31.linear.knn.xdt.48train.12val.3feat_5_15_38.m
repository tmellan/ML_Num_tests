#!/usr/bin/env wolframscript

(*Numerai prediction using Mathematica*)
dir="/home/tamellan/Desktop/mathematica/ML_Num_tests/predictions/"
(*name="28.linear.knn.rf.xdt.dt.12train.12val.3feat_5_15_38.m"*)
(*bash script grep the name*)
name="31.linear.knn.xdt.48train.12val.3feat_5_15_38.m.out"
outputname=StringJoin[dir,name]

(*Parameters*)
selectedFeatures={3,5,38};
nMaxEraValTest=12;
nMaxEraTrain=48;
noTopFeatures=3;
l1RegParameter=2;
l2RegParameter=2;

(*methods={"LinearRegression","GaussianProcess","NearestNeighbors","NeuralNetwork","RandomForest"};*)
methods={"LinearRegression","NearestNeighbors","GradientBoostedTrees"};

(*To do*)
(*1) Make the validation set size a variable, and do validation testing for now just on one era*)
(*2) Create a new output set, which is polarised before the logloss is counted*)
(*3) Create another new output set which is standardised befoere logloss counted*)
(*4) Include the NN, gradient tree etc.*)
(* gpu training*)
(*Kill the rescale stuff and standarisation *)


(*Import data*)
numeraiData=Import["/home/tamellan/Desktop/Numerai/numerai_training_data.csv"];
(*numeraiData//Dimensions*)
numeraiDataValidation=Import["/home/tamellan/Desktop/Numerai/numerai_tournament_data.csv"];
(*numeraiDataValidation//Dimensions*)
trainDim=numeraiData//Dimensions
Print@trainDim
validationDim=numeraiDataValidation//Dimensions
Print@validationDim
(*(*Prep the train data*)*)
eras=DeleteDuplicates[Transpose[numeraiData][[2]][[2;;-1]]];
eraSizes=Table[{eras[[i]],Count[Transpose[numeraiData][[2]][[2;;-1]],eras[[i]]]},{i,1,Length@eras}];
cummulativeEraSizes=Total/@Table[Transpose[eraSizes][[2]][[1;;i]],{i,1,Length@eraSizes}];
Print@cummulativeEraSizes
trainPureData=Transpose[Transpose[numeraiData[[2;;-1]]][[4;;-1]]];
Dimensions[trainPureData]
(*(*Last 3 months, 6 months, 9 months, 12 months, 15, 18, 21, 24 months*)*)
lastnEras=Table[With[{n=h},trainPureData[[cummulativeEraSizes[[-1-n]]+1;;cummulativeEraSizes[[-1]]]]],{h,1,nMaxEraTrain,1}];
lastnEras//Dimensions
Print["Last n eras: "]
Print[lastnEras//Dimensions]
(*(*Prep the validation and training data -- using 1 month only*)*)
erasVal=DeleteDuplicates[Transpose[numeraiDataValidation][[2]][[2;;-1]]];
eraSizesVal=Table[{erasVal[[i]],Count[Transpose[numeraiDataValidation][[2]][[2;;-1]],erasVal[[i]]]},{i,1,Length@erasVal}];
Print@eraSizesVal
cummulativeEraSizesVal=Total/@Table[Transpose[eraSizesVal][[2]][[1;;i]],{i,1,Length@eraSizesVal}]
Print@cummulativeEraSizesVal
valPureData=Transpose[Transpose[numeraiDataValidation[[2;;-1]]][[4;;-1]]];
(*(*Last 3 months, 6 months, 9 months, 12 months, 15, 18, 21, 24 months*)*)
nErasVal=Table[With[{n=h},valPureData[[1;;cummulativeEraSizesVal[[h]]]]],{h,1,nMaxEraValTest,1}];
nErasVal//Dimensions
Print["nErasVal: "]
Print[nErasVal//Dimensions]

(********************************************************************************************************************************)
(*Train model and make predictions*)

Clear[results,raw]
results={}; raw={};

(*(*Loop*)*)
(*Training*)

For[q=nMaxEraTrain-1,q<nMaxEraTrain,q++;
trainSetSize=Dimensions[lastnEras[[q]]][[1]];
NumeraiTrainingData=lastnEras[[q]];

correlationTable=Table[{i,Correlation[Transpose[NumeraiTrainingData][[i]],Transpose[NumeraiTrainingData][[-1]]]},{i,1,Dimensions[NumeraiTrainingData][[2]]}];
bestCorrelations=Reverse@Ordering[Abs@Transpose[correlationTable][[2]]][[-noTopFeatures;;-1]];
bestCorrs=Transpose[correlationTable[[bestCorrelations]]][[1]];
(*(*Select top ten or n generally features to train set*)*)
topTen=Transpose[NumeraiTrainingData][[bestCorrs]];
(*(*Training*)*)
trainInput=Transpose[topTen[[2;;-1]]];
trainOutput=topTen[[1]];
(*Map input to output*)
f[arg_]:=arg[[1]]->arg[[2]];
trainSet=Table[f[{trainInput[[i]],trainOutput[[i]]}],{i,1,Length[trainInput]}];
(*Train Net*)
nets=Table[Predict[trainSet,Method->methods[[i]],PerformanceGoal->"Quality"],{i,1,Length@methods}]//AbsoluteTiming;
timings=StringJoin[{"Net train time: ",ToString@nets[[1]]," s"}];
net=nets[[2]];

(*Apply net to the training data -- optional*)
(*netTrainOutput=Table[Table[net[[j]][trainInput[[i]]],{i,1,Length@trainInput}],{j,1,Length@net}];
actualTrain=Table[{i,trainOutput[[i]]},{i,1,Length[trainInput]}];
netTrain=Table[Table[{i,netTrainOutput[[j]][[i]]},{i,1,Length[trainInput]}],{j,1,Length@net}];*)
]
Print["Loop one done - training"]

(*Prediction loop in index R*)
Clear[q,topTenVal]
results={}; raw={};
For[q=0,q<nMaxEraValTest,q++;
valSetSize=Dimensions[nErasVal[[q]]][[1]];
NumeraiValidationData=nErasVal[[q]];
topTenVal=Transpose[NumeraiValidationData][[bestCorrs]];
trainInputVal=Transpose[topTenVal[[2;;-1]]];
trainOutputVal=topTenVal[[1]];
f[arg_]:=arg[[1]]->arg[[2]];
trainSetVal=Table[f[{trainInputVal[[i]],trainOutputVal[[i]]}],{i,1,Length[trainInputVal]}];
netTrainOutputVal=Table[Table[net[[j]][trainInputVal[[i]]],{i,1,Length@trainInputVal}],{j,1,Length@net}];
actualTrainVal=Table[{i,trainOutputVal[[i]]},{i,1,Length[trainInputVal]}];
netTrainVal=Table[Table[{i,netTrainOutputVal[[j]][[i]]},{i,1,Length[trainInputVal]}],{j,1,Length@net}];
trueResults=Transpose[actualTrainVal][[2]];
predictedResults=Table[Transpose[netTrainVal[[i]]][[2]],{i,1,Length@net}];
Clear[logloss];
loglossfun[binary_,prediction_]:=Table[-(binary[[i]]*Log[prediction[[i]]]+(1-binary[[i]])*Log[1-prediction[[i]]]),{i,1,Length@binary}];
logloss=Table[Mean@loglossfun[trueResults,predictedResults[[i]]],{i,1,Length@net}];
loglossSD=Table[StandardDeviation@loglossfun[trueResults,predictedResults[[i]]],{i,1,Length@net}];
loglossAccuracy=Table[StandardDeviation@loglossfun[trueResults,predictedResults[[i]]]/Sqrt[Length@predictedResults[[i]]],{i,1,Length@net}];
loglossRS=Table[Mean@DeleteCases[loglossfun[trueResults,Rescale[Standardize[predictedResults[[i]]]]],Indeterminate],{i,1,Length@net}];
loglossSDRS=Table[StandardDeviation@DeleteCases[loglossfun[trueResults,Rescale[Standardize[predictedResults[[i]]]]],Indeterminate],{i,1,Length@net}];
loglossAccuracyRS=Table[StandardDeviation@DeleteCases[loglossfun[trueResults,Rescale[Standardize[predictedResults[[i]]]]],Indeterminate]/Sqrt[Length@predictedResults[[i]]],{i,1,Length@net}];
polar2[f_]:=Table[If[f[[i]]>Mean[f],1,0],{i,1,Length@f}];
polarisedOutputVal2=Table[polar2@netTrainOutputVal[[i]],{i,1,Length[net]}]; 
jobsize={"Train-set size: ",trainSetSize," Validation-set size: ",valSetSize}; 
labels={{"Method","correlation","accuracy","logloss","logloss-error"}}; 
scores=Join[labels,Table[{methods[[i]],Correlation[trainOutputVal,polarisedOutputVal2[[i]]],(Correlation[trainOutputVal,polarisedOutputVal2[[i]]]+1)/2//N,logloss[[i]],loglossAccuracy[[i]]},{i,1,Length@methods}]//N]; 
jobScoresRaw={{q},jobsize,{timings},{"Best features: ",ToString@topfeatures},scores}; 
AppendTo[raw,jobScoresRaw]; 
jobScores={{q}[[1]]//TableForm,jobsize//TableForm,{timings}[[1]]//TableForm,{"Best features: ",topfeatures}//TableForm,scores//TableForm};
AppendTo[results,jobScores];
numeraiTest=results//TableForm;
Print[" "]
Print@numeraiTest[[-1]][[-1]]
]
Print["numeraiTest:"]
Print@numeraiTest
Export[outputname",numeraiTest]
