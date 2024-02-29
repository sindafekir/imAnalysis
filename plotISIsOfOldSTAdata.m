%% reorganize terminals and vidList variables using one of the two methods
% below, as needed 
tterms{1} = terminals; clear terminals
terminals = tterms;
vvids{1} = vidList; clear vidList 
vidList = vvids;
%%
mouse = input('What mouse is this in the data file? ');
tterms{1} = terminals{mouse}; clear terminals
terminals = tterms;
vvids{1} = vidList{mouse}; clear vidList 
vidList = vvids;
FPS = FPSstack{mouse};

%% determine ISIs across the whole animal. 
mouse = 1;
spikeISIs = cell(1,length(vidList{mouse})); 
spikeISIsByVid = cell(1,length(vidList{mouse})); 
spikeISIsByAxon = cell(1,length(terminals{mouse})); 
for vid = 1:length(vidList{mouse})
    for ccell = 1:length(terminals{mouse})
        % determine ISI
        spikeISIs{vid}{terminals{mouse}(ccell)} = diff(sigLocs{vid}{terminals{mouse}(ccell)});
        % resort ISIs into the same cell for each vid 
        if ccell == 1 
            spikeISIsByVid{vid} = spikeISIs{vid}{terminals{mouse}(ccell)};
        elseif ccell > 1
            len1 = length(spikeISIsByVid{vid})+1;
            len2 = length(spikeISIs{vid}{terminals{mouse}(ccell)})+len1-1;
            spikeISIsByVid{vid}(len1:len2) = spikeISIs{vid}{terminals{mouse}(ccell)};
        end 
        % resort ISIs into the same cell array per axon
        if vid == 1 
            spikeISIsByAxon{ccell} = spikeISIs{vid}{terminals{mouse}(ccell)};
        elseif vid > 1 
            len1 = length(spikeISIsByAxon{ccell})+1;
            len2 = length(spikeISIs{vid}{terminals{mouse}(ccell)})+len1-1;
            spikeISIsByAxon{ccell}(len1:len2) = spikeISIs{vid}{terminals{mouse}(ccell)};
        end 
    end 
    % resort ISIs into the same cell over all for the whole animal 
    if vid == 1 
        allSpikeISIs = spikeISIsByVid{vid};
    elseif vid > 1 
        len1 = length(allSpikeISIs)+1;
        len2 = length(spikeISIsByVid{vid})+len1-1;
        allSpikeISIs(len1:len2) = spikeISIsByVid{vid};
    end 
end       
% convert frames to time 
allSpikeISIs = allSpikeISIs/FPS;
% plot distribution of ISIs for the whole animal 
figure;
histogram(allSpikeISIs);
%% keep only the data you need 
clearvars -except allSpikeISIs spikeISIsByAxon
%% get the data you need 
numGroups = input('How many groups are you plotting histograms for? '); 
for group = 1:numGroups
    numAnims = input(sprintf('How many animals are in group %d? ',group));
    for anim = 1:numAnims
        % import the data for each mouse 
        dir = uigetdir('*.*',sprintf('SELECT FILE LOCATION FOR MOUSE %d, GROUP %d?',anim,group));
        cd(dir);
        data = uigetfile('*.*',sprintf('SELECT THE .MAT FILE FOR MOUSE %d, GROUP %d',anim,group)); 
        dataMat = matfile(data); 
        allSpikeISIs{group}{anim} = dataMat.allSpikeISIs; 
        spikeISIsByAxon{group}{anim} = dataMat.spikeISIsByAxon; 
    end 
end 
%% plot distribution of ISIs for all animals color coded by group 
% this is hard coded to make specific figures 
figure;
allGroupData  = cell(1,numGroups);
groupMed = nan(1,2);
for group = 1:numGroups
    for anim = 1:length(allSpikeISIs{group})
        if group == 1 
            h = histogram(allSpikeISIs{group}{anim},'EdgeColor','r','FaceAlpha',0);
            % [values, edges] = histcounts(allSpikeISIs{group}{anim}, 'Normalization', 'probability');
            % centers = (edges(1:end-1)+edges(2:end))/2;
            % plot(centers, values, 'r',"LineWidth",2)
        elseif group == 2 
            histogram(allSpikeISIs{group}{anim},'EdgeColor','k','FaceAlpha',0);
            % [values, edges] = histcounts(allSpikeISIs{group}{anim}, 'Normalization', 'probability');
            % centers = (edges(1:end-1)+edges(2:end))/2;
            % plot(centers, values, 'k',"LineWidth",2)
        end 
        hold on; 
        % resort data to figure out the median value for each group 
        if anim == 1 
            allGroupData{group} = allSpikeISIs{group}{anim};
        elseif anim > 1
            len1 = length(allGroupData{group})+1;
            len2 = length(allSpikeISIs{group}{anim})+len1-1;
            allGroupData{group}(len1:len2) = allSpikeISIs{group}{anim};
        end 
        groupMed(group) = median(allGroupData{group});
    end 
end 
title(sprintf('Median Chrimson+ ISI: %d. Median Chrimson- ISI: %d.',groupMed(1),groupMed(2)))

%% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
figure;
avMeds = nan(1,2);
meds = cell(1,numGroups);
for group = 1:numGroups
    count = 1;
    for anim = 1:length(allSpikeISIs{group})
        for ccell = 1:length(spikeISIsByAxon{group}{anim})
            if group == 1 
                % h = histogram(spikeISIsByAxon{group}{anim}{ccell},'FaceColor','r','FaceAlpha',0.1,'LineWidth',1);
                [values, edges] = histcounts(spikeISIsByAxon{group}{anim}{ccell}, 'Normalization', 'probability');
                centers = (edges(1:end-1)+edges(2:end))/2;
                plot(centers, values, 'r',"LineWidth",2)
            elseif group == 2 
                % h = histogram(spikeISIsByAxon{group}{anim}{ccell},'FaceColor','k','FaceAlpha',0.1,'LineWidth',1);
                [values, edges] = histcounts(spikeISIsByAxon{group}{anim}{ccell}, 'Normalization', 'probability');
                centers = (edges(1:end-1)+edges(2:end))/2;
                plot(centers, values, 'k',"LineWidth",2)
            end 
            hold on; 
            % figure out the average median across groups 
            meds{group}(count) = median(spikeISIsByAxon{group}{anim}{ccell});
            count = count + 1;
            set(gca, 'XScale', 'log')
        end 
    end 
    avMeds(group) = mean(meds{group});
end 
title(sprintf('Median Chrimson+ ISI: %d. Median Chrimson- ISI: %d.',avMeds(1),avMeds(2)))