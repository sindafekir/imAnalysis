% organize data 
maxPeriRewPerMouse = [74.40,91.53,28.34,25.41,11.73,11.73];
maxPostRewPerMouse = [75.01,30.23,7.82,5.86];

% jack knife to get jack knifed averages 
inds = 1:length(maxPeriRewPerMouse);
avMaxPeriRewPerMouse = nan(1,length(maxPeriRewPerMouse));
for j = inds
    avMaxPeriRewPerMouse(j) = mean(maxPeriRewPerMouse(setdiff(1:end,j)));
end 

inds = 1:length(maxPostRewPerMouse);
avMaxPostRewPerMouse = nan(1,length(maxPostRewPerMouse));
for j = inds
    avMaxPostRewPerMouse(j) = mean(maxPostRewPerMouse(setdiff(1:end,j)));
end 

% determine the average and SD of the jack knifed averages 
avJmaxPeriRewPerMouse = mean(avMaxPeriRewPerMouse);
avJmaxPostRewPerMouse = mean(avMaxPostRewPerMouse);

SEMperi = (std(avMaxPeriRewPerMouse))/(sqrt(size(avMaxPeriRewPerMouse,2)));
SEMpost = (std(avMaxPostRewPerMouse))/(sqrt(size(avMaxPostRewPerMouse,2)));

% wilcoxon rank sum test of jack knifed data (independent)
p = ranksum(avMaxPeriRewPerMouse,avMaxPostRewPerMouse);

% wilcoxon rank sum test of raw data (independent) 
p0 = ranksum(maxPeriRewPerMouse,maxPostRewPerMouse);

% % paired wilcoxon rank sum test of jack knifed data (dependent) 
% p2 = signrank(avMaxPeriRewPerMouse,avMaxPostRewPerMouse);
% 
% % paired wilcoxon rank sum test of raw data (dependent) 
% p02 = signrank(maxPeriRewPerMouse,maxPostRewPerMouse);
