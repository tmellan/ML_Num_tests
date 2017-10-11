#!/usr/bin/env wolframscript

(*Numerai prediction using Mathematica*)


(*To do*)
(*1) Make the validation set size a variable, and do validation testing for now just on one era*)
(*2) Create a new output set, which is polarised before the logloss is counted*)
(*3) Create another new output set which is standardised befoere logloss counted*)
(*4) Include the NN, gradient tree etc.*)


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
eraSizes=Table[{eras[[i]],Count[Transpose[numeraiData][[2]][[2;;-1]],eras[[i]]]},{i,1,Length@eras}]
cummulativeEraSizes=Total/@Table[Transpose[eraSizes][[2]][[1;;i]],{i,1,Length@eraSizes}]
Print@cummulativeEraSizes
trainPureData=Transpose[Transpose[numeraiData[[2;;-1]]][[4;;-1]]];
Dimensions[trainPureData]
(**)
(*(*Last 3 months, 6 months, 9 months, 12 months, 15, 18, 21, 24 months*)*)
lastnEras=Table[With[{n=h},trainPureData[[cummulativeEraSizes[[-1-n]]+1;;cummulativeEraSizes[[-1]]]]],{h,1,24,1}];
lastnEras//Dimensions


(*(*Prep the validation and training data -- using 1 month only*)*)
erasVal=DeleteDuplicates[Transpose[numeraiDataValidation][[2]][[2;;-1]]]
eraSizesVal=Table[{erasVal[[i]],Count[Transpose[numeraiDataValidation][[2]][[2;;-1]],erasVal[[i]]]},{i,1,Length@erasVal}]
Print@eraSizesVal
totalValSize=With[{noOfErasToTrain=1},Total@Transpose[eraSizesVal][[2]][[1;;-14+noOfErasToTrain]]]
totalTestSize=Total@Transpose[eraSizesVal][[2]][[-1;;-1]]

NumeraiValidationData=Transpose[Transpose[numeraiDataValidation[[2;;-1]][[1;;totalValSize]]][[4;;-1]]];
NumeraiTestData=Transpose[Transpose[numeraiDataValidation[[2;;-1]][[totalValSize+1;;-1]]][[4;;-1]]];


(*Train model and make predictions*)


Clear[results,raw]
results={}; raw={};
(*(*Parameter*)*)
noTopFeatures=25;
l1RegParameter=2;
l2RegParameter=2;
(**)
(*(*Loop*)*)
For[q=0,q<13,q++;
trainSetSize=Dimensions[lastnEras[[q]]][[1]];
valSetSize=Length[NumeraiValidationData];
testSetSize=Length[NumeraiTestData];

NumeraiTrainingData=lastnEras[[q]];
correlationTable=Table[{i,Correlation[Transpose[NumeraiTrainingData][[i]],Transpose[NumeraiTrainingData][[-1]]]},{i,1,Dimensions[NumeraiTrainingData][[2]]}];
bestCorrelations=Reverse@Ordering[Abs@Transpose[correlationTable][[2]]][[-noTopFeatures;;-1]];
bestCorrs=Transpose[correlationTable[[bestCorrelations]]][[1]];

(*(*Select top ten or n generally features to train set*)*)
topTen=Transpose[NumeraiTrainingData][[bestCorrs]];
topTenVal=Transpose[NumeraiValidationData][[bestCorrs]];
topTenTest=Transpose[NumeraiTestData][[bestCorrs]];

(*(*Training*)*)
trainInput=Transpose[topTen[[2;;-1]]];
trainOutput=topTen[[1]];

(*(*Validation*)*)
trainInputVal=Transpose[topTenVal[[2;;-1]]];
trainOutputVal=topTenVal[[1]];

(*Test*)
trainInputTest=Transpose[topTenTest[[2;;-1]]];
trainOutputTest=topTenTest[[1]];

(*Map input to output*)
f[arg_]:=arg[[1]]->arg[[2]];
trainSet=Table[f[{trainInput[[i]],trainOutput[[i]]}],{i,1,Length[trainInput]}];
trainSetVal=Table[f[{trainInputVal[[i]],trainOutputVal[[i]]}],{i,1,Length[trainInputVal]}];

(*methods={"LinearRegression","GaussianProcess","NearestNeighbors","NeuralNetwork","RandomForest"};*)
methods={"LinearRegression"};
(*Train Net*)
nets=Table[Predict[trainSet,Method->methods[[i]],PerformanceGoal->"Quality"],{i,1,Length@methods}]//AbsoluteTiming;
timings=StringJoin[{"Net train time: ",ToString@nets[[1]]," s"}];
net=nets[[2]];

(*Apply net to the training data*)
netTrainOutput=Table[Table[net[[j]][trainInput[[i]]],{i,1,Length@trainInput}],{j,1,Length@net}];

actualTrain=Table[{i,trainOutput[[i]]},{i,1,Length[trainInput]}];
netTrain=Table[Table[{i,netTrainOutput[[j]][[i]]},{i,1,Length[trainInput]}],{j,1,Length@net}];

(*Apply net to the testing data*)
netTrainOutputVal=Table[Table[net[[j]][trainInputVal[[i]]],{i,1,Length@trainInputVal}],{j,1,Length@net}];

(*Parse trained data*)
actualTrainVal=Table[{i,trainOutputVal[[i]]},{i,1,Length[trainInputVal]}];
netTrainVal=Table[Table[{i,netTrainOutputVal[[j]][[i]]},{i,1,Length[trainInputVal]}],{j,1,Length@net}];
(*Analyse results*)
(*Predicted and actual results on test data*)
trueResults=Transpose[actualTrainVal][[2]];
predictedResults=Transpose[netTrainVal[[1]]][[2]];

(*Define log loss function*)
Clear[logloss];
loglossfun[binary_,prediction_]:=Table[-(binary[[i]]*Log[prediction[[i]]]+(1-binary[[i]])*Log[1-prediction[[i]]]),{i,1,Length@binary}];
(*Calculate the log loss for each time step, then find the mean*)
(*Log loss stats*)
logloss=Mean@loglossfun[trueResults,predictedResults];
loglossSD=StandardDeviation@loglossfun[trueResults,predictedResults];
loglossAccuracy=StandardDeviation@loglossfun[trueResults,predictedResults]/Sqrt[Length@predictedResults];

(*Calculate the log loss on RESCALED STATS*)
(*Log loss on rescaled stats*)
loglossRS=Mean@DeleteCases[loglossfun[trueResults,Rescale[Standardize[predictedResults]]],Indeterminate];
loglossSDRS=StandardDeviation@DeleteCases[loglossfun[trueResults,Rescale[Standardize[predictedResults]]],Indeterminate];
loglossAccuracyRS=StandardDeviation@DeleteCases[loglossfun[trueResults,Rescale[Standardize[predictedResults]]],Indeterminate]/Sqrt[Length@predictedResults];

(*Define binary accuracy*)
polar2[f_]:=Table[If[f[[i]]>Mean[f],1,0],{i,1,Length@f}];
polarisedOutputVal2=Table[polar2@netTrainOutputVal[[i]],{i,1,Length[net]}];

(*Output binary accuracy - method, correlation, success*)
jobsize={"Train-set size: ",trainSetSize," Validation-set size: ",valSetSize};

labels={{"Method","correlation","accuracy","logloss","logloss-error","RS-logloss","RS-logloss-error"}};
scores=Join[labels,Table[{methods[[i]],Correlation[trainOutputVal,polarisedOutputVal2[[i]]],(Correlation[trainOutputVal,polarisedOutputVal2[[i]]]+1)/2//N,logloss,loglossAccuracy,loglossRS,loglossAccuracyRS},{i,1,Length@methods}]//N];

(*Output results*)
jobScoresRaw={{q},jobsize,{timings},{"Best features: ",ToString@topfeatures},scores};
AppendTo[raw,jobScoresRaw];

jobScores={{q}[[1]]//TableForm,jobsize//TableForm,{timings}[[1]]//TableForm,{"Best features: ",topfeatures}//TableForm,scores//TableForm};
AppendTo[results,jobScores];

numeraiTest=results//TableForm;
Export["/home/tamellan/Desktop/Numerai/4.linear1.25feature.nTrainingEra.1valEra.numerai.dat",raw];
Print@numeraiTest[[-1]][[-1]]
]
