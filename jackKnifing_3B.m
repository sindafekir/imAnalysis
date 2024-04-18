% organize data 
numPreStimPlumes_Hit = [3,0,2,5,6];
numStimPlumes_Hit = [0,1,4,9,8];
numPeriRewPlumes_Hit = [6,0,3,5,10];
numPostRewPlumes_Hit = [3,0,4,12,6];

numPreStimPlumes_Miss = [6,1,17,2,6];
numStimPlumes_Miss = [4,0,9,11,3];
numPeriRewPlumes_Miss = [0,0,10,1,0];
numPostRewPlumes_Miss = [1,0,12,7,4];

% jack knife to get jack knifed averages (when jack knifing remove entire
% mouse from all time epochs at once) 
inds = 1:length(numPreStimPlumes_Hit);
avNumPreStimPlumes_Hit = nan(1,length(numPreStimPlumes_Hit));
avNumStimPlumes_Hit = nan(1,length(numPreStimPlumes_Hit));
avNumPeriRewPlumes_Hit = nan(1,length(numPreStimPlumes_Hit));
avNumPostRewPlumes_Hit = nan(1,length(numPreStimPlumes_Hit));
for j = inds
    avNumPreStimPlumes_Hit(j) = mean(numPreStimPlumes_Hit(setdiff(1:end,j)));
    avNumStimPlumes_Hit(j) = mean(numStimPlumes_Hit(setdiff(1:end,j)));
    avNumPeriRewPlumes_Hit(j) = mean(numPeriRewPlumes_Hit(setdiff(1:end,j)));
    avNumPostRewPlumes_Hit(j) = mean(numPostRewPlumes_Hit(setdiff(1:end,j)));
end 

inds = 1:length(numPreStimPlumes_Miss);
avNumPreStimPlumes_Miss = nan(1,length(numPreStimPlumes_Miss));
avNumStimPlumes_Miss = nan(1,length(numPreStimPlumes_Miss));
avNumPeriRewPlumes_Miss = nan(1,length(numPreStimPlumes_Miss));
avNumPostRewPlumes_Miss = nan(1,length(numPreStimPlumes_Miss));
for j = inds
    avNumPreStimPlumes_Miss(j) = mean(numPreStimPlumes_Miss(setdiff(1:end,j)));
    avNumStimPlumes_Miss(j) = mean(numStimPlumes_Miss(setdiff(1:end,j)));
    avNumPeriRewPlumes_Miss(j) = mean(numPeriRewPlumes_Miss(setdiff(1:end,j)));
    avNumPostRewPlumes_Miss(j) = mean(numPostRewPlumes_Miss(setdiff(1:end,j)));
end 

% determine the average and SD of the jack knifed averages 
avJnumPreStimPlumes_Hit = mean(avNumPreStimPlumes_Hit);
avJnumStimPlumes_Hit = mean(avNumStimPlumes_Hit);
avJnumPeriRewPlumes_Hit = mean(avNumPeriRewPlumes_Hit);
avJnumPostRewPlumes_Hit = mean(avNumPostRewPlumes_Hit);

avJnumPreStimPlumes_Miss = mean(avNumPreStimPlumes_Miss); 
avJnumStimPlumes_Miss = mean(avNumStimPlumes_Miss);
avJnumPeriRewPlumes_Miss = mean(avNumPeriRewPlumes_Miss); 
avJnumPostRewPlumes_Miss = mean(avNumPostRewPlumes_Miss); 

SEMpreStim_Hit = (std(avNumPreStimPlumes_Hit))/(sqrt(size(avNumPreStimPlumes_Hit,2)));
SEMstim_Hit = (std(avNumStimPlumes_Hit))/(sqrt(size(avNumStimPlumes_Hit,2)));
SEMperiRew_Hit = (std(avNumPeriRewPlumes_Hit))/(sqrt(size(avNumPeriRewPlumes_Hit,2)));
SEMpostRew_Hit = (std(avNumPostRewPlumes_Hit))/(sqrt(size(avNumPostRewPlumes_Hit,2)));

SEMpreStim_Miss = (std(avNumPreStimPlumes_Miss))/(sqrt(size(avNumPreStimPlumes_Miss,2)));
SEMstim_Miss = (std(avNumStimPlumes_Miss))/(sqrt(size(avNumStimPlumes_Miss,2)));
SEMperiRew_Miss = (std(avNumPeriRewPlumes_Miss))/(sqrt(size(avNumPeriRewPlumes_Miss,2)));
SEMpostRew_Miss = (std(avNumPostRewPlumes_Miss))/(sqrt(size(avNumPostRewPlumes_Miss,2)));

scatter([1,2,3,4],[avJnumPreStimPlumes_Hit,avJnumStimPlumes_Hit,avJnumPeriRewPlumes_Hit,avJnumPostRewPlumes_Hit],'LineWidth',4,'MarkerFaceColor','none','MarkerEdgeColor','red')
hold on; 
scatter([1,2,3,4],[avJnumPreStimPlumes_Hit+SEMpreStim_Hit,avJnumStimPlumes_Hit+SEMstim_Hit,avJnumPeriRewPlumes_Hit+SEMperiRew_Hit,avJnumPostRewPlumes_Hit+SEMpostRew_Hit],'LineWidth',2,'MarkerFaceColor','none','MarkerEdgeColor','red')
hold on; 
scatter([1,2,3,4],[avJnumPreStimPlumes_Hit-SEMpreStim_Hit,avJnumStimPlumes_Hit-SEMstim_Hit,avJnumPeriRewPlumes_Hit-SEMperiRew_Hit,avJnumPostRewPlumes_Hit-SEMpostRew_Hit],'LineWidth',2,'MarkerFaceColor','none','MarkerEdgeColor','red')
hold on;
scatter([1,2,3,4],[avJnumPreStimPlumes_Miss,avJnumStimPlumes_Miss,avJnumPeriRewPlumes_Miss,avJnumPostRewPlumes_Miss],'LineWidth',4,'MarkerFaceColor','none','MarkerEdgeColor','black')
hold on; 
scatter([1,2,3,4],[avJnumPreStimPlumes_Miss+SEMpreStim_Miss,avJnumStimPlumes_Miss+SEMstim_Miss,avJnumPeriRewPlumes_Miss+SEMperiRew_Miss,avJnumPostRewPlumes_Miss+SEMpostRew_Miss],'LineWidth',2,'MarkerFaceColor','none','MarkerEdgeColor','black')
hold on; 
scatter([1,2,3,4],[avJnumPreStimPlumes_Miss-SEMpreStim_Miss,avJnumStimPlumes_Miss-SEMstim_Miss,avJnumPeriRewPlumes_Miss-SEMperiRew_Miss,avJnumPostRewPlumes_Miss-SEMpostRew_Miss],'LineWidth',2,'MarkerFaceColor','none','MarkerEdgeColor','black')
title('Red: Hit. Black: Miss')

% paired wilcoxon rank sum test of jack knifed data (dependent) 
p_preStimVsStim_Hit = signrank(avNumPreStimPlumes_Hit,avNumStimPlumes_Hit);
p_preStimVsPeriRew_Hit = signrank(avNumPreStimPlumes_Hit,avNumPeriRewPlumes_Hit);
p_preStimVsPostRew_Hit = signrank(avNumPreStimPlumes_Hit,avNumPostRewPlumes_Hit);

p_preStimVsStim_Miss = signrank(avNumPreStimPlumes_Miss,avNumStimPlumes_Miss);
p_preStimVsPeriRew_Miss = signrank(avNumPreStimPlumes_Miss,avNumPeriRewPlumes_Miss);
p_preStimVsPostRew_Miss = signrank(avNumPreStimPlumes_Miss,avNumPostRewPlumes_Miss);

p_preStim_HitVsMiss = signrank(avNumPreStimPlumes_Hit,avNumPreStimPlumes_Miss);
p_Stim_HitVsMiss = signrank(avNumStimPlumes_Hit,avNumStimPlumes_Miss);
p_periRew_HitVsMiss = signrank(avNumPeriRewPlumes_Hit,avNumPeriRewPlumes_Miss);
p_postRew_HitVsMiss = signrank(avNumPostRewPlumes_Hit,avNumPostRewPlumes_Miss);
