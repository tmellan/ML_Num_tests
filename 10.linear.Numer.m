#!/usr/bin/env wolframscript

(*Numerai prediction using Mathematica*)

(*To do*)
(*1) Make the validation set size a variable, and do validation testing for now just on one era*)
(*2) Create a new output set, which is polarised before the logloss is counted*)
(*3) Create another new output set which is standardised befoere logloss counted*)
(*4) Include the NN, gradient tree etc.*)


(*Import data*)
numeraiData=Import["/home/tamellan/Desktop/Numerai/numerai_training_data.csv"];
Print[Dimensions[numeraiData]]
Print@Dimensions[numeraiData]
numeraiDataValidation=Import["/home/tamellan/Desktop/Numerai/numerai_tournament_data.csv"];

(*numeraiDataValidation//Dimensions*)
trainDim=numeraiData//Dimensions
validationDim=numeraiDataValidation//Dimensions


(*(*Prep the train data*)*)
eras=DeleteDuplicates[Transpose[numeraiData][[2]][[2;;-1]]];
eraSizes=Table[{eras[[i]],Count[Transpose[numeraiData][[2]][[2;;-1]],eras[[i]]]},{i,1,Length@eras}];
Print@eraSizes
cummulativeEraSizes=Total/@Table[Transpose[eraSizes][[2]][[1;;i]],{i,1,Length@eraSizes}];
Print@cummulativeEraSizes
trainPureData=Transpose[Transpose[numeraiData[[2;;-1]]][[4;;-1]]];
Print@Dimensions[trainPureData]
(**)
(*(*Last 3 months, 6 months, 9 months, 12 months, 15, 18, 21, 24 months*)*)
lastnEras=Table[With[{n=h},trainPureData[[cummulativeEraSizes[[-1-n]]+1;;cummulativeEraSizes[[-1]]]]],{h,1,24,1}];
lastnEras//Dimensions//Print


(*(*Prep the validation and training data -- using 1 month only*)*)
erasVal=DeleteDuplicates[Transpose[numeraiDataValidation][[2]][[2;;-1]]]
Print@erasVal
eraSizesVal=Table[{erasVal[[i]],Count[Transpose[numeraiDataValidation][[2]][[2;;-1]],erasVal[[i]]]},{i,1,Length@erasVal}]
Print@eraSizesVal
totalValSize=With[{noOfErasToTrain=1},Total@Transpose[eraSizesVal][[2]][[1;;-14+noOfErasToTrain]]]
totalTestSize=Total@Transpose[eraSizesVal][[2]][[-1;;-1]]

NumeraiValidationData=Transpose[Transpose[numeraiDataValidation[[2;;-1]][[1;;totalValSize]]][[4;;-1]]];
NumeraiTestData=Transpose[Transpose[numeraiDataValidation[[2;;-1]][[totalValSize+1;;-1]]][[4;;-1]]];
