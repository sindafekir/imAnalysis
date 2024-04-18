% organize data 
maxPeriRewPerMouse = [752.5,2061,2219];
maxPostRewPerMouse = [87.96,837.8,325.5];

% jack knife to get jack knifed averages 
inds = 1:length(maxPostRewPerMouse);
avMaxPeriRewPerMouse = nan(1,length(maxPostRewPerMouse));
avMaxPostRewPerMouse = nan(1,length(maxPostRewPerMouse));
for j = inds
    avMaxPeriRewPerMouse(j) = mean(maxPeriRewPerMouse(setdiff(1:end,j)));
    avMaxPostRewPerMouse(j) = mean(maxPostRewPerMouse(setdiff(1:end,j)));
end 

% determine the average and SD of the jack knifed averages 
avJmaxPeriRewPerMouse = mean(avMaxPeriRewPerMouse);
avJmaxPostRewPerMouse = mean(avMaxPostRewPerMouse);

SEMperi = (std(avMaxPeriRewPerMouse))/(sqrt(size(avMaxPeriRewPerMouse,2)));
SEMpost = (std(avMaxPostRewPerMouse))/(sqrt(size(avMaxPostRewPerMouse,2)));

% % wilcoxon rank sum test of jack knifed data (independent)
% p = ranksum(avMaxPeriRewPerMouse,avMaxPostRewPerMouse);
% 
% % wilcoxon rank sum test of raw data (independent) 
% p0 = ranksum(maxPeriRewPerMouse,maxPostRewPerMouse);

% paired wilcoxon rank sum test of jack knifed data (dependent) 
p2 = signrank(avMaxPeriRewPerMouse,avMaxPostRewPerMouse);

% paired wilcoxon rank sum test of raw data (dependent) 
p02 = signrank(maxPeriRewPerMouse,maxPostRewPerMouse);


