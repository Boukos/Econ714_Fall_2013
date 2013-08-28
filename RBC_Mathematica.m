Clear["Global`*"];

AbsoluteTiming[
 
 (* Compiling the inner Loop *) 
 (* NOTE: Using the un-documented Compile`GetElement function instead \
of Part *)
 
 innerLoop = 
  Compile[{{mOutput, _Real, 2}, {vGridCapital, _Real, 
     1}, {nGridCapital, _Integer},
    {nGridProductivity, _Integer}, {expectedValueFunction, _Real, 
     2}},
   With[{initialCapital = First[vGridCapital]},
    Table[
     Module[{gridCapitalNextPeriod = 1}, 
      Table[
       With[{output = 
          Compile`GetElement[mOutput, nCapital, nProductivity]},
        Module[{
          valueProvisional = 0.,
          valueHighSoFar = -1000.0, 
          capitalChoice = initialCapital}, 
         Catch@Do[
           
           valueProvisional = 
            0.05 Log[
               output - 
                Compile`GetElement[vGridCapital, nCapitalNextPeriod]] +
             
             0.95 Compile`GetElement[expectedValueFunction, 
               nCapitalNextPeriod, nProductivity];
           If[valueProvisional > valueHighSoFar,
            valueHighSoFar = valueProvisional;
            
            capitalChoice = 
             Compile`GetElement[vGridCapital, nCapitalNextPeriod];
            gridCapitalNextPeriod = nCapitalNextPeriod;
            ,
            Throw[{valueHighSoFar, capitalChoice}]
            ],
            {nCapitalNextPeriod, gridCapitalNextPeriod, 
            nGridCapital}]]], 
       {nCapital, nGridCapital}]],
     {nProductivity, nGridProductivity}]
    ],
   CompilationTarget -> "C", "RuntimeOptions" -> "Speed" ];
 
 
 (* 1. Calibration*)
 \[Alpha] = 0.333333333333;
 \[Beta] = 0.95;
 
 (* Productivity values*)
 
 vProductivity = {0.9792, 0.9896, 1.0000, 1.0106, 1.0212};
 
 (* Transition matrix *)
 
 mTransition = {{0.9727, 0.0273, 0.0000, 0.0000, 0.0000},
   {0.0041, 0.9806, 0.0153, 0.0000, 0.0000},
   {0.0000, 0.0082, 0.9837, 0.0082, 0.0000},
   {0.0000, 0.0000, 0.0153, 0.9806, 0.0041},
   {0.0000, 0.0000, 0.0000, 0.0273, 0.9727}};
 mTransitionTransposed = Transpose[mTransition];
 
 (* 2. Steady State*)
 
 Subscript[k, ss] = (\[Alpha] \[Beta])^(1/(1 - \[Alpha]));
   Subscript[y, ss] = Subscript[k, ss]^\[Alpha];
   Subscript[c, ss] = Subscript[y, ss] - Subscript[k, ss];
 
 (* We generate the grid of capital*)
 
 vGridCapital = 
  Range[0.5 Subscript[k, ss], 1.5 Subscript[k, ss], 0.00001];
 nGridCapital = Length[vGridCapital];
 nGridProductivity = Length[vProductivity];
 
 (*3. Required matrices and vectors*)
 
 mOutput = ConstantArray[0, {nGridCapital, nGridProductivity}];
   mValueFunction = 
  ConstantArray[0, {nGridCapital, nGridProductivity}];
   mValueFunctionNew = 
  ConstantArray[0, {nGridCapital, nGridProductivity}];
   mPolicyFunction = 
  ConstantArray[0, {nGridCapital, nGridProductivity}]; 
 expectedValueFunction = 
  ConstantArray[0, {nGridCapital, nGridProductivity}];
 
 (*4. We pre-build output for each point in the grid*)
  
 mOutput = Transpose[{vGridCapital^\[Alpha]}].{vProductivity};
 
 (* FixedPoint *)
 tolerance = 0.0000001;
   iteration = 0;
 dis = 0;
 
 (* outer Loop function *)
 
 outerLoop[{mValueFunction_, mPolicyFunction_}] := Transpose[
   innerLoop[mOutput, vGridCapital, nGridCapital, nGridProductivity,
    Dot[mValueFunction, mTransitionTransposed]], 
   {3, 2, 1}];
 
 
 (* Iteration *)
 {mValueFunction, mPolicyFunction} = 
  FixedPoint[outerLoop, {mValueFunction, mPolicyFunction},
   SameTest ->
    (
     (dis = Max[Abs[#1[[1]] - #2[[1]]]];  
        iteration++;
       If[Mod[iteration, 10] == 0 ||  iteration == 1,
        Print[
         StringForm["Iteration = ``, Sup Diff = ``", iteration, 
          dis]]]; 
       dis < tolerance ) &
     )
   ];
 
 Print[StringForm["Iteration = ``, Sup Diff = ``", iteration, dis]];
 Print[StringForm["My check = ``", mPolicyFunction[[1000, 3]]]];
 
 ]

(* Mathematica Raw Program *)

