% organize data 
avPeriRewPlumeSize_Pav = [18.9241,8.8845,19.1906,9.0622,32.3605,41.2160];
avPostRewPlumeSize_Pav = [6.2192,4.3534,34.7875,20.0796];

avStimPlumeSize_Op = [385.0916,181.3686,108.0866,205.1547,146.5074,195.5378,82.5511,245.1518,73.0091,121.2009,173.2307,300.0011,110.1774,113.7804];
avPeriRewPlumeSize_Op = [664.1715,337.6633,239.5522,295.3415,199.3765,135.3161,124.8767,165.3130,117.8684,68.2923,72.2322,98.6444,85.1389,59.7347,79.6463,202.4344,67.6994,128.1808,44.8010,89.6021,89.6021,62.2237,215.9640];
avPostRewPlumeSize_Op = [168.0151,273.6832,186.7205,430.5274,120.6292,80.9640,276.0876,129.5802,54.2836,140.0868,78.7988,102.9638,67.7594,67.5418,80.8834,74.6515,85.4941,96.7134,161.9475,39.8232];

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