% organize data 
avStimPlumeSize_Hit = [70899.6386,5637.2931,1837.4721,6600.6280,11924.8850,6461.5015,1733.5736,21941.0879,438.0547,2787.6207,7247.8139,9059.7673,1652.6609,796.4631];
avPeriRewPlumeSize_Hit = [128463.9966,55344.0135,16422.2253,7974.2207,13293.9636,19419.2673,7902.9141,5976.2443,3300.3140,2048.7688,1733.5736,3659.7665,2469.0290,418.1431,398.2315,11827.4764,338.4968,2050.8924,537.6126,1075.2251,358.4084,497.7894,2807.5323];
avPostRewPlumeSize_Hit = [9255.6835,10762.9065,5655.1326,23708.7422,2533.2140,1052.5326,12117.5043,4868.0147,2013.7471,4202.6026,2363.9640,2574.0941,1558.4651,1418.3784,1698.5519,1418.3784,1453.4001,676.9936,2429.2123,358.4084];

avStimPlumeSize_Miss = [642.2233,249.7535,428.1488,107.0372,20067.4276,4692.9063,18929.2227,4868.0147,19851.8418,3225.6754,3185.8522];
avPeriRewPlumeSize_Miss = [160.5558,3121.9187,160.5558,160.5558,4955.5689];
avPostRewPlumeSize_Miss = [3956.5216,9055.6444,124.8767,606.5442,463.8279,802.7791,2943.5233,196.2349,196.2349,124.8767,338.9512,142.7163,3425.1907,160.5558,11837.3307,4938.0581,5218.2316,4150.0701,7547.1739,1792.0419,2787.6207,1314.1641];

% jack knife to get jack knifed averages (when jack knifing remove entire
% mouse from all time epochs at once) 
inds = 1:length(avStimPlumeSize_Hit);
AvStimPlumeSize_Hit = nan(1,length(avStimPlumeSize_Hit));
for j = inds
    AvStimPlumeSize_Hit(j) = mean(avStimPlumeSize_Hit(setdiff(1:end,j)));
end 
inds = 1:length(avPeriRewPlumeSize_Hit);
AvPeriRewPlumeSize_Hit = nan(1,length(avPeriRewPlumeSize_Hit));
for j = inds
    AvPeriRewPlumeSize_Hit(j) = mean(avPeriRewPlumeSize_Hit(setdiff(1:end,j)));
end 
inds = 1:length(avPostRewPlumeSize_Hit);
AvPostRewPlumeSize_Hit = nan(1,length(avPostRewPlumeSize_Hit));
for j = inds
    AvPostRewPlumeSize_Hit(j) = mean(avPostRewPlumeSize_Hit(setdiff(1:end,j)));
end 

inds = 1:length(avStimPlumeSize_Miss);
AvStimPlumeSize_Miss = nan(1,length(avStimPlumeSize_Miss));
for j = inds
    AvStimPlumeSize_Miss(j) = mean(avStimPlumeSize_Miss(setdiff(1:end,j)));
end 
inds = 1:length(avPeriRewPlumeSize_Miss);
AvPeriRewPlumeSize_Miss = nan(1,length(avPeriRewPlumeSize_Miss));
for j = inds
    AvPeriRewPlumeSize_Miss(j) = mean(avPeriRewPlumeSize_Miss(setdiff(1:end,j)));
end 
inds = 1:length(avPostRewPlumeSize_Miss);
AvPostRewPlumeSize_Miss = nan(1,length(avPostRewPlumeSize_Miss));
for j = inds
    AvPostRewPlumeSize_Miss(j) = mean(avPostRewPlumeSize_Miss(setdiff(1:end,j)));
end 

% determine the average and SE of the jack knifed averages 
avJStimPlumes_Hit = mean(AvStimPlumeSize_Hit);
avJPeriRewPlumes_Hit = mean(AvPeriRewPlumeSize_Hit);
avJPostRewPlumes_Hit = mean(AvPostRewPlumeSize_Hit);

avJStimPlumes_Miss = mean(AvStimPlumeSize_Miss);
avJPeriRewPlumes_Miss = mean(AvPeriRewPlumeSize_Miss); 
avJPostRewPlumes_Miss = mean(AvPostRewPlumeSize_Miss); 

SEMstim_Hit = (std(AvStimPlumeSize_Hit))/(sqrt(size(AvStimPlumeSize_Hit,2)));
SEMperiRew_Hit = (std(AvPeriRewPlumeSize_Hit))/(sqrt(size(AvPeriRewPlumeSize_Hit,2)));
SEMpostRew_Hit = (std(AvPostRewPlumeSize_Hit))/(sqrt(size(AvPostRewPlumeSize_Hit,2)));

SEMstim_Miss = (std(AvStimPlumeSize_Miss))/(sqrt(size(AvStimPlumeSize_Miss,2)));
SEMperiRew_Miss = (std(AvPeriRewPlumeSize_Miss))/(sqrt(size(AvPeriRewPlumeSize_Miss,2)));
SEMpostRew_Miss = (std(AvPostRewPlumeSize_Miss))/(sqrt(size(AvPostRewPlumeSize_Miss,2)));

figure
scatter([1,2,3],[avJStimPlumes_Hit,avJPeriRewPlumes_Hit,avJPostRewPlumes_Hit],'LineWidth',4,'MarkerFaceColor','none','MarkerEdgeColor','red')
hold on; 
scatter([1,2,3],[avJStimPlumes_Hit+SEMstim_Hit,avJPeriRewPlumes_Hit+SEMperiRew_Hit,avJPostRewPlumes_Hit+SEMpostRew_Hit],'LineWidth',2,'MarkerFaceColor','none','MarkerEdgeColor','red')
hold on; 
scatter([1,2,3],[avJStimPlumes_Hit-SEMstim_Hit,avJPeriRewPlumes_Hit-SEMperiRew_Hit,avJPostRewPlumes_Hit-SEMpostRew_Hit],'LineWidth',2,'MarkerFaceColor','none','MarkerEdgeColor','red')
hold on;
scatter([1,2,3],[avJStimPlumes_Miss,avJPeriRewPlumes_Miss,avJPostRewPlumes_Miss],'LineWidth',4,'MarkerFaceColor','none','MarkerEdgeColor','black')
hold on; 
scatter([1,2,3],[avJStimPlumes_Miss+SEMstim_Miss,avJPeriRewPlumes_Miss+SEMperiRew_Miss,avJPostRewPlumes_Miss+SEMpostRew_Miss],'LineWidth',2,'MarkerFaceColor','none','MarkerEdgeColor','black')
hold on; 
scatter([1,2,3],[avJStimPlumes_Miss-SEMstim_Miss,avJPeriRewPlumes_Miss-SEMperiRew_Miss,avJPostRewPlumes_Miss-SEMpostRew_Miss],'LineWidth',2,'MarkerFaceColor','none','MarkerEdgeColor','black')
title('Red: Hit. Black: Miss')
% set(gca, 'yscale','log') 

% wilcoxon rank sum test of jack knifed data (independent) 
p_stimVsPeriRew_Hit = ranksum(AvStimPlumeSize_Hit,AvPeriRewPlumeSize_Hit);
p_stimVsPostRew_Hit = ranksum(AvStimPlumeSize_Hit,AvPostRewPlumeSize_Hit);
p_periRewVsPostRew_Hit = ranksum(AvPeriRewPlumeSize_Hit,AvPostRewPlumeSize_Hit);

p_stimVsPeriRew_Miss = ranksum(AvStimPlumeSize_Miss,AvPeriRewPlumeSize_Miss);
p_stimVsPostRew_Miss = ranksum(AvStimPlumeSize_Miss,AvPostRewPlumeSize_Miss);
p_PeriRewVsPostRew_Miss = ranksum(AvPeriRewPlumeSize_Miss,AvPostRewPlumeSize_Miss);

p_stim_HitVsMiss = ranksum(AvStimPlumeSize_Hit,AvStimPlumeSize_Miss);
p_periRew_HitVsMiss = ranksum(AvPeriRewPlumeSize_Hit,AvPeriRewPlumeSize_Miss);
p_postRew_HitVsMiss = ranksum(AvPostRewPlumeSize_Hit,AvPostRewPlumeSize_Miss);