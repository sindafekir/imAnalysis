tterms{1} = terminals; clear terminals
terminals = tterms;
vvids{1} = vidList; clear vidList 
vidList = vvids;
%%
spikeISIs = cell(1,length(vidList{mouse})); 
for vid = 1:length(vidList{mouse})
    for ccell = 1:length(terminals{mouse})
        % determine ISI
        spikeISIs{vid}{terminals{mouse}(ccell)} = diff(sigLocs{vid}{terminals{mouse}(ccell)});
        % resort ISIs into the same cell for each axon 
        
        % resort ISIs into the same cell over all for the whole animal 

    end 
end       
% plot distribution of real and rand ISIs for sanity check 
figure;
histogram(spikeISIs{vid}{terminals{mouse}(ccell)});
title(sprintf("Real Spike ISIs. Vid %d. Axon %d. ",vid,terminals{mouse}(ccell)));