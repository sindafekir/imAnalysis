% organize data 
avStimPlumeSize_Hit = [385.0916,181.3686,108.0866,205.1547,146.5074,195.5378,82.5511,245.1518,73.0091,121.2009,173.2307,300.0011,110.1774,113.7804];
avPeriRewPlumeSize_Hit = [664.1715,337.6633,239.5522,295.3415,199.3765,135.3161,124.8767,165.3130,117.8684,68.2923,72.2322,98.6444,85.1389,59.7347,79.6463,202.4344,67.6994,128.1808,44.8010,89.6021,89.6021,62.2237,215.9640];
avPostRewPlumeSize_Hit = [168.0151,273.6832,186.7205,430.5274,120.6292,80.9640,276.0876,129.5802,54.2836,140.0868,78.7988,102.9638,67.7594,67.5418,80.8834,74.6515,85.4941,96.7134,161.9475,39.8232];

avStimPlumeSize_Miss = [27.9228,27.7504,47.5721,17.8395,208.9225,160.0129,502.9839,134.6524,492.9832,161.2838,132.7438];
avPeriRewPlumeSize_Miss = [17.8395,105.1917,40.1390,32.1112,198.2228];
avPostRewPlumeSize_Miss = [247.2826,754.6370,20.8128,55.1404,77.3047,72.9799,94.7341,17.8395,17.8395,17.8395,48.4216,35.6791,155.6905,17.8395,216.7722,158.2014,248.4872,218.4247,539.0838,105.4142,154.8678,146.0182];

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