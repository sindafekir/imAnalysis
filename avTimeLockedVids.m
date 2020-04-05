%% determine weights from number of peaks per video 
% numPeaks1 = ;
numPeaks2 = 9;
numPeaks3 = 2;
numPeaks4 = 1;
% numPeaks5 = ;
% numPeaks6 = ;
numPeaks7 = 1;
% numPeaks8 = ;
% numPeaks9 = ;
numPeaks10 = 3;
numPeaks11 = 3;

totalPeaks = numPeaks2+numPeaks3+numPeaks4+numPeaks7+numPeaks10+numPeaks11; 

% w1 = numPeaks1/totalPeaks;
w2 = numPeaks2/totalPeaks;
w3 = numPeaks3/totalPeaks;
w4 = numPeaks4/totalPeaks;
% w5 = numPeaks5/totalPeaks;
% w6 = numPeaks6/totalPeaks;
w7 = numPeaks7/totalPeaks;
% w8 = numPeaks8/totalPeaks;
% w9 = numPeaks9/totalPeaks;
w10 = numPeaks10/totalPeaks;
w11 = numPeaks11/totalPeaks;

%% determine weighted average 

% avB = ((avB2*w2)+(avB3*w3)+(avB10*w10)+(avB11*w11));
% avC = ((avC2*w2)+(avC3*w3)+(avC10*w10)+(avC11*w11));
avV = ((avV2_0_9*w2)+(avV3_0_9*w3)+(avV4_0_9*w4)+(avV7_0_9*w7)+(avV10_0_9*w10)+(avV11_0_9*w11));


