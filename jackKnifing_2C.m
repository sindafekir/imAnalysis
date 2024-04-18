% organize data 
numPreStimPlumes_Pav = [1,0,0];
numStimPlumes_Pav = [0,0,0];
numPeriRewPlumes_Pav = [4,1,1];
numPostRewPlumes_Pav = [2,1,1];

numPreStimPlumes_Op = [3,0,2,5,6];
numStimPlumes_Op = [0,1,4,9,8];
numPeriRewPlumes_Op = [6,3,4,1,9];
numPostRewPlumes_Op = [3,4,12,0,6];

% jack knife to get jack knifed averages (when jack knifing remove entire
% mouse from all time epochs at once) 
inds = 1:length(numPreStimPlumes_Pav);
avNumPreStimPlumes_Pav = nan(1,length(numPreStimPlumes_Pav));
avNumStimPlumes_Pav = nan(1,length(numPreStimPlumes_Pav));
avNumPeriRewPlumes_Pav = nan(1,length(numPreStimPlumes_Pav));
avNumPostRewPlumes_Pav = nan(1,length(numPreStimPlumes_Pav));
for j = inds
    avNumPreStimPlumes_Pav(j) = mean(numPreStimPlumes_Pav(setdiff(1:end,j)));
    avNumStimPlumes_Pav(j) = mean(numStimPlumes_Pav(setdiff(1:end,j)));
    avNumPeriRewPlumes_Pav(j) = mean(numPeriRewPlumes_Pav(setdiff(1:end,j)));
    avNumPostRewPlumes_Pav(j) = mean(numPostRewPlumes_Pav(setdiff(1:end,j)));
end 

inds = 1:length(numPreStimPlumes_Op);
avNumPreStimPlumes_Op = nan(1,length(numPreStimPlumes_Op));
avNumStimPlumes_Op = nan(1,length(numPreStimPlumes_Op));
avNumPeriRewPlumes_Op = nan(1,length(numPreStimPlumes_Op));
avNumPostRewPlumes_Op = nan(1,length(numPreStimPlumes_Op));
for j = inds
    avNumPreStimPlumes_Op(j) = mean(numPreStimPlumes_Op(setdiff(1:end,j)));
    avNumStimPlumes_Op(j) = mean(numStimPlumes_Op(setdiff(1:end,j)));
    avNumPeriRewPlumes_Op(j) = mean(numPeriRewPlumes_Op(setdiff(1:end,j)));
    avNumPostRewPlumes_Op(j) = mean(numPostRewPlumes_Op(setdiff(1:end,j)));
end 

% determine the average and SD of the jack knifed averages 
avJnumPreStimPlumes_Pav = mean(avNumPreStimPlumes_Pav);
avJnumStimPlumes_Pav = mean(avNumStimPlumes_Pav);
avJnumPeriRewPlumes_Pav = mean(avNumPeriRewPlumes_Pav);
avJnumPostRewPlumes_Pav = mean(avNumPostRewPlumes_Pav);

avJnumPreStimPlumes_Op = mean(avNumPreStimPlumes_Op); 
avJnumStimPlumes_Op = mean(avNumStimPlumes_Op);
avJnumPeriRewPlumes_Op = mean(avNumPeriRewPlumes_Op); 
avJnumPostRewPlumes_Op = mean(avNumPostRewPlumes_Op); 

SEMpreStim_Pav = (std(avNumPreStimPlumes_Pav))/(sqrt(size(avNumPreStimPlumes_Pav,2)));
SEMstim_Pav = (std(avNumStimPlumes_Pav))/(sqrt(size(avNumStimPlumes_Pav,2)));
SEMperiRew_Pav = (std(avNumPeriRewPlumes_Pav))/(sqrt(size(avNumPeriRewPlumes_Pav,2)));
SEMpostRew_Pav = (std(avNumPostRewPlumes_Pav))/(sqrt(size(avNumPostRewPlumes_Pav,2)));

SEMpreStim_Op = (std(avNumPreStimPlumes_Op))/(sqrt(size(avNumPreStimPlumes_Op,2)));
SEMstim_Op = (std(avNumStimPlumes_Op))/(sqrt(size(avNumStimPlumes_Op,2)));
SEMperiRew_Op = (std(avNumPeriRewPlumes_Op))/(sqrt(size(avNumPeriRewPlumes_Op,2)));
SEMpostRew_Op = (std(avNumPostRewPlumes_Op))/(sqrt(size(avNumPostRewPlumes_Op,2)));

scatter([1,2,3,4],[avJnumPreStimPlumes_Pav,avJnumStimPlumes_Pav,avJnumPeriRewPlumes_Pav,avJnumPostRewPlumes_Pav],'LineWidth',4,'MarkerFaceColor','none','MarkerEdgeColor','red')
hold on; 
scatter([1,2,3,4],[avJnumPreStimPlumes_Pav+SEMpreStim_Pav,avJnumStimPlumes_Pav+SEMstim_Pav,avJnumPeriRewPlumes_Pav+SEMperiRew_Pav,avJnumPostRewPlumes_Pav+SEMpostRew_Pav],'LineWidth',2,'MarkerFaceColor','none','MarkerEdgeColor','red')
hold on; 
scatter([1,2,3,4],[avJnumPreStimPlumes_Pav-SEMpreStim_Pav,avJnumStimPlumes_Pav-SEMstim_Pav,avJnumPeriRewPlumes_Pav-SEMperiRew_Pav,avJnumPostRewPlumes_Pav-SEMpostRew_Pav],'LineWidth',2,'MarkerFaceColor','none','MarkerEdgeColor','red')
hold on;
scatter([1,2,3,4],[avJnumPreStimPlumes_Op,avJnumStimPlumes_Op,avJnumPeriRewPlumes_Op,avJnumPostRewPlumes_Op],'LineWidth',4,'MarkerFaceColor','none','MarkerEdgeColor','black')
hold on; 
scatter([1,2,3,4],[avJnumPreStimPlumes_Op+SEMpreStim_Op,avJnumStimPlumes_Op+SEMstim_Op,avJnumPeriRewPlumes_Op+SEMperiRew_Op,avJnumPostRewPlumes_Op+SEMpostRew_Op],'LineWidth',2,'MarkerFaceColor','none','MarkerEdgeColor','black')
hold on; 
scatter([1,2,3,4],[avJnumPreStimPlumes_Op-SEMpreStim_Op,avJnumStimPlumes_Op-SEMstim_Op,avJnumPeriRewPlumes_Op-SEMperiRew_Op,avJnumPostRewPlumes_Op-SEMpostRew_Op],'LineWidth',2,'MarkerFaceColor','none','MarkerEdgeColor','black')
title('Red: Pavlovian. Black: Operant')

% paired wilcoxon rank sum test of jack knifed data (dependent) 
p_preStimVsPeriRew_Pav = signrank(avNumPreStimPlumes_Pav,avNumPeriRewPlumes_Pav);
p_preStimVsPostRew_Pav = signrank(avNumPreStimPlumes_Pav,avNumPostRewPlumes_Pav);

p_preStimVsStim_Op = signrank(avNumPreStimPlumes_Op,avNumStimPlumes_Op);
p_preStimVsPeriRew_Op = signrank(avNumPreStimPlumes_Op,avNumPeriRewPlumes_Op);
p_preStimVsPostRew_Op = signrank(avNumPreStimPlumes_Op,avNumPostRewPlumes_Op);

% wilcoxon rank sum test of jack knifed data (independent)
p_preStim_PavVsOp = ranksum(avNumPreStimPlumes_Pav,avNumPreStimPlumes_Op);
p_Stim_PavVsOp = ranksum(avNumStimPlumes_Pav,avNumStimPlumes_Op);
p_periRew_PavVsOp = ranksum(avNumPeriRewPlumes_Pav,avNumPeriRewPlumes_Op);
p_postRew_PavVsOp = ranksum(avNumPostRewPlumes_Pav,avNumPostRewPlumes_Op);
