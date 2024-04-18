% organize data 
avPeriRewPlumeSize_Pav = [696.8151,295.1447,752.5212,301.9858,2060.8,2219.2];
avPostRewPlumeSize_Pav = [87.957,80.1386,837.79,325.5006];

avStimPlumeSize_Op = [70899.6386,5637.2931,1837.4721,6600.6280,11924.8850,6461.5015,1733.5736,21941.0879,438.0547,2787.6207,7247.8139,9059.7673,1652.6609,796.4631];
avPeriRewPlumeSize_Op = [128463.9966,55344.0135,16422.2253,7974.2207,13293.9636,19419.2673,7902.9141,5976.2443,3300.3140,2048.7688,1733.5736,3659.7665,2469.0290,418.1431,398.2315,11827.4764,338.4968,2050.8924,537.6126,1075.2251,358.4084,497.7894,2807.5323];
avPostRewPlumeSize_Op = [9255.6835,10762.9065,5655.1326,23708.7422,2533.2140,1052.5326,12117.5043,4868.0147,2013.7471,4202.6026,2363.9640,2574.0941,1558.4651,1418.3784,1698.5519,1418.3784,1453.4001,676.9936,2429.2123,358.4084];

% jack knife to get jack knifed averages (when jack knifing remove entire
% mouse from all time epochs at once) 
inds = 1:length(avPeriRewPlumeSize_Pav);
AvPeriRewPlumeSize_Pav = nan(1,length(avPeriRewPlumeSize_Pav));
for j = inds
    AvPeriRewPlumeSize_Pav(j) = mean(avPeriRewPlumeSize_Pav(setdiff(1:end,j)));
end 
inds = 1:length(avPostRewPlumeSize_Pav);
AvPostRewPlumeSize_Pav = nan(1,length(avPostRewPlumeSize_Pav));
for j = inds
    AvPostRewPlumeSize_Pav(j) = mean(avPostRewPlumeSize_Pav(setdiff(1:end,j)));
end 

inds = 1:length(avStimPlumeSize_Op);
AvStimPlumeSize_Op = nan(1,length(avStimPlumeSize_Op));
for j = inds
    AvStimPlumeSize_Op(j) = mean(avStimPlumeSize_Op(setdiff(1:end,j)));
end 
inds = 1:length(avPeriRewPlumeSize_Op);
AvPeriRewPlumeSize_Op = nan(1,length(avPeriRewPlumeSize_Op));
for j = inds
    AvPeriRewPlumeSize_Op(j) = mean(avPeriRewPlumeSize_Op(setdiff(1:end,j)));
end 
inds = 1:length(avPostRewPlumeSize_Op);
AvPostRewPlumeSize_Op = nan(1,length(avPostRewPlumeSize_Op));
for j = inds
    AvPostRewPlumeSize_Op(j) = mean(avPostRewPlumeSize_Op(setdiff(1:end,j)));
end 



% determine the average and SE of the jack knifed averages 
avJPeriRewPlumes_Pav = mean(AvPeriRewPlumeSize_Pav);
avJPostRewPlumes_Pav = mean(AvPostRewPlumeSize_Pav);

avJStimPlumes_Op = mean(AvStimPlumeSize_Op);
avJPeriRewPlumes_Op = mean(AvPeriRewPlumeSize_Op); 
avJPostRewPlumes_Op = mean(AvPostRewPlumeSize_Op); 

SEMperiRew_Pav = (std(AvPeriRewPlumeSize_Pav))/(sqrt(size(AvPeriRewPlumeSize_Pav,2)));
SEMpostRew_Pav = (std(AvPostRewPlumeSize_Pav))/(sqrt(size(AvPostRewPlumeSize_Pav,2)));

SEMstim_Op = (std(AvStimPlumeSize_Op))/(sqrt(size(AvStimPlumeSize_Op,2)));
SEMperiRew_Op = (std(AvPeriRewPlumeSize_Op))/(sqrt(size(AvPeriRewPlumeSize_Op,2)));
SEMpostRew_Op = (std(AvPostRewPlumeSize_Op))/(sqrt(size(AvPostRewPlumeSize_Op,2)));

figure
scatter([2,3],[avJPeriRewPlumes_Pav,avJPostRewPlumes_Pav],'LineWidth',4,'MarkerFaceColor','none','MarkerEdgeColor','red')
hold on; 
scatter([2,3],[avJPeriRewPlumes_Pav+SEMperiRew_Pav,avJPostRewPlumes_Pav+SEMpostRew_Pav],'LineWidth',2,'MarkerFaceColor','none','MarkerEdgeColor','red')
hold on; 
scatter([2,3],[avJPeriRewPlumes_Pav-SEMperiRew_Pav,avJPostRewPlumes_Pav-SEMpostRew_Pav],'LineWidth',2,'MarkerFaceColor','none','MarkerEdgeColor','red')
hold on;
scatter([1,2,3],[avJStimPlumes_Op,avJPeriRewPlumes_Op,avJPostRewPlumes_Op],'LineWidth',4,'MarkerFaceColor','none','MarkerEdgeColor','black')
hold on; 
scatter([1,2,3],[avJStimPlumes_Op+SEMstim_Op,avJPeriRewPlumes_Op+SEMperiRew_Op,avJPostRewPlumes_Op+SEMpostRew_Op],'LineWidth',2,'MarkerFaceColor','none','MarkerEdgeColor','black')
hold on; 
scatter([1,2,3],[avJStimPlumes_Op-SEMstim_Op,avJPeriRewPlumes_Op-SEMperiRew_Op,avJPostRewPlumes_Op-SEMpostRew_Op],'LineWidth',2,'MarkerFaceColor','none','MarkerEdgeColor','black')
title('Red: Pavlovian. Black: Operant')
% set(gca, 'yscale','log') 

% wilcoxon rank sum test of jack knifed data (independent) 
p_periRewVsPostRew_Pav = ranksum(AvPeriRewPlumeSize_Pav,AvPostRewPlumeSize_Pav);

p_stimVsPeriRew_Op = ranksum(AvStimPlumeSize_Op,AvPeriRewPlumeSize_Op);
p_stimVsPostRew_Op = ranksum(AvStimPlumeSize_Op,AvPostRewPlumeSize_Op);
p_PeriRewVsPostRew_Op = ranksum(AvPeriRewPlumeSize_Op,AvPostRewPlumeSize_Op);

p_periRew_PavVsOp = ranksum(AvPeriRewPlumeSize_Pav,AvPeriRewPlumeSize_Op);
p_postRew_PavVsOp = ranksum(AvPostRewPlumeSize_Pav,AvPostRewPlumeSize_Op);