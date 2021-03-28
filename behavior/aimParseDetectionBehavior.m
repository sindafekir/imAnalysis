
[tHDF,tPth]=uigetfile('*.hdf','what what?');
csBehaviorHDFPath=[tPth tHDF];

csBehavHDFInfo=h5info(csBehaviorHDFPath);
curDatasetPath=['/' csBehavHDFInfo.Datasets.Name];
csSessionData=h5read(csBehaviorHDFPath,curDatasetPath);
csTrialData=csBehavHDFInfo.Datasets.Attributes;

% performance
perf.droppedSamples = numel(find(csSessionData(1,:)==0))-1;
perf.peakLoop = double(max(csSessionData(9,:)));
disp(["dropped samples: " num2str(perf.droppedSamples)])


%

% map of data labels and numerical indicies (for the data in the dataset only).
chStrMap={'interrupt','sessionTime','stateTime','teensyStates','loadCell','lickSensor',...
    'encoder','frame','interruptTime','analogInput0','analogInput1',...
    'analogInput2','analogInput3','pythonStates','thresholdedLicks'};

chIndMap=[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15];
% simple anonymous function to easily index the channels by name. This allows flexibility.
% use: chFind('interruptsco') will return 1.
chFind=@(b) chIndMap(find(strcmp(chStrMap,b)==1));


% A) Parse the dataset.
for n=1:numel(chStrMap)
    try
        disp(['parsedStruct.' chStrMap{n} '=double(csSessionData(chFind(''' chStrMap{n} '''),:));'])
        eval(['parsedStruct.' chStrMap{n} '=double(csSessionData(chFind(''' chStrMap{n} '''),:));'])
    catch
        a=1;
    end
end

% scale things (teensy ADC is 12-bit/3.3V)
parsedStruct.sessionTime=parsedStruct.sessionTime/1000;
parsedStruct.stateTime=parsedStruct.stateTime/1000;
parsedStruct.analogInput0=(parsedStruct.analogInput0/4095)*3.3;
parsedStruct.analogInput1=(parsedStruct.analogInput1/4095)*3.3;
parsedStruct.analogInput2=(parsedStruct.analogInput2/4095)*3.3;
parsedStruct.analogInput3=(parsedStruct.analogInput3/4095)*3.3;
parsedStruct.encoder=(parsedStruct.encoder/4095)*3.3;

% we don't use the encoder voltage, but convert it into motion variables
parsedStruct.position=decodeShaftEncoder(parsedStruct.encoder,3);
parsedStruct.velocity=nPointDeriv(parsedStruct.position,parsedStruct.sessionTime,1000);
% there can be divide by zeros
parsedStruct.velocity(find(isnan(parsedStruct.velocity)==1))=0;
parsedStruct.binaryVelocity=binarizeResponse(parsedStruct.velocity,0.005);
parsedStruct.motionBoutStarts=find(diff(parsedStruct.binaryVelocity)>0.8);

% B) Define a trial by the onset of the stimulus state (usually state2). 
% Store the stim-onset samples, make a binary vector and count trials.
% State is logged on teensy and in python, and can differ during transitions. However, the teensyState
% is the actual state.



% C) Resolve 'attribute' data.
% Data that do not change within a 'trial' are stored as attributes for the
% parent dataset, which is the ms-ms data that comprise all trials.
% For the most part, these attribute data are stimulus parameters. Here we
% parse the attribute data. Some stimulus parameters are generated for all 
% trials at run-time. This prevents having to recalculate things that are pre-determined. 
% For these I pad the arrays by a large amount, just in case the user wants to
% increase the number of trials. Thus, we will usually end up with more of
% these than trials we ran. So, we need to trim these to the length of the trials ran.
% This stuff is most likley to change with format changes.

for n=1:numel(csTrialData)
    tName = csTrialData(n).Name;
    try
        tData = double(csTrialData(n).Value);
    catch
        tData = csTrialData(n).Value;
    end
    eval(['parsedStruct.' tName '=tData;'])
end

parsedStruct.completedTrials=numel(parsedStruct.trialDurs);
% 
% % contrasts as a fraction.
% attDataScalars=[1,1,1,0.001,0.001];
% attDataLabels={'contrasts','orientations','spatialFreqs','waitTimePads','trialDurs'};
% attDataNames={'contrasts','orientations','spatialFreqs','waitTimes','trialDurations'};
% 
[parsedStruct.stimSamps,parsedStruct.stimVector]=getStateSamps(parsedStruct.teensyStates,2,1);

bData = parsedStruct; 

parsed = [];


% find the sample of the start of each trial, including catch trials, and
% concatenate
[stimOnSamps,stimOnVect]=getStateSamps(bData.teensyStates,2,1);
[catchOnSamps,catchOnVect]=getStateSamps(bData.teensyStates,3,1);
stimSamps = [stimOnSamps, catchOnSamps];
stimSamps = sort(stimSamps);

% find the timing in ms of each reward and lick
[rewardOnSamps, rewardOnVect] = getStateSamps(bData.teensyStates,4,1);
[licks, licksVect] = getStateSamps(bData.thresholdedLicks, 1, 1);

lickWindow = 1500;

% loop over the first one hundred trials and extract hit/miss information
for n = 1:size(stimSamps,2)
   % for touch
   parsed.amplitude(n)=bData.c1_amp(n);
   % for vision
   %parsed.amplitude(n)=bData.contrast(n);
   
   tempLick = find(bData.thresholdedLicks(stimSamps(n):stimSamps(n)+lickWindow)==1);
   tempRun = find(bData.binaryVelocity(stimSamps(n):stimSamps(n)+ lickWindow) == 1);
   
   % check to see if the animal licked in the window
   if numel(tempLick)>0
      % it licked
      parsed.lick(n) = 1;
      parsed.lickLatency(n) = tempLick(1) - stimSamps(n);
      parsed.lickCount(n) = numel(tempLick);
      if parsed.amplitude(n)>0
         parsed.response_hits(n) = 1;
         parsed.response_miss(n) = 0;
         parsed.response_fa(n) = NaN;
         parsed.response_cr(n) = NaN;
      elseif parsed.amplitude(n) == 0
         parsed.response_fa(n) = 1;
         parsed.response_cr(n) = 0;
         parsed.response_hits(n) = NaN;
         parsed.response_miss(n) = NaN;
      end
   elseif numel(tempLick)==0
      parsed.lick(n) = 0;
      parsed.lickLatency(n) = NaN;
      parsed.lickCount(n) = 0;
      if parsed.amplitude(n)>0
         parsed.response_hits(n) = 0;
         parsed.response_miss(n) = 1;
         parsed.response_fa(n) = NaN;
         parsed.response_cr(n) = NaN;
      elseif parsed.amplitude(n) == 0
         parsed.response_fa(n) = 0;
         parsed.response_cr(n) = 1;
         parsed.response_hits(n) = NaN;
         parsed.response_miss(n) = NaN;
      end
   end
   
   % extract whether or not the mouse ran during the report window
   if numel(tempRun) > 0
      parsed.run(n) = 1;
      tempVel = bData.velocity(stimSamps(n):stimSamps(n)+ lickWindow);
      parsed.vel(n) = nanmean(abs(tempVel));
   else
      parsed.run(n) = 0;
      parsed.vel(n) = 0;
   end
   
end




% Hit rate, false alarm rate, dPrime
smtWin = 50;
parsed.hitRate = nPointMean(parsed.response_hits, smtWin)';
parsed.faRate = nPointMean(parsed.response_fa, smtWin)';
parsed.dPrime = norminv(parsed.hitRate) - norminv(parsed.faRate);


figure
subplot(2,1,1)
plot(parsed.hitRate,'k-')
hold all,plot(parsed.faRate,'b-');

legend('FA', 'Hit')
xlabel('Trial Number');
title('Hit Rate and False Alarm Rate');
ylabel('p(H) and p(FA)')
ylim([0,1]);


subplot(2,1,2)

%d' plot
plot(parsed.dPrime,'k-')


xlabel('Trial Number');
title('D Prime')
legend('d-prime')
ylabel('d Prime')
ylim([-0.5,3])

dFWindow = [-1000,3000];
stimInds = stimOnSamps;
nStim = numel(stimOnSamps);

preSamps = -dFWindow(1)/1000;
postSamps = dFWindow(2)/1000;

[licks, licksVect] = getStateSamps(bData.thresholdedLicks, 1, 1);

for n=2:nStim
    if stimInds(n)+dFWindow(2) < length(licksVect)
        tempLickVect = licksVect(stimInds(n)+dFWindow(1):stimInds(n)+dFWindow(2))==1;
        tempLickVect = tempLickVect';
        lickTrig(1:length(tempLickVect),n)=tempLickVect;
    end 
end


[ x_bins2 ,mean_rate] = rasterSmooth([-preSamps:0.001:postSamps],lickTrig,2,'k');

    figure
subplot(211);rasterSmooth([-preSamps:0.001:postSamps],lickTrig,1,'k');
subplot(212);
plot(x_bins2,mean_rate,'k','linewidth',2);ylim([0 15]);ylabel('Licks/Second');xlabel('Time (s)');
ax=axis;line([0 0],[ax(3) ax(4)],'color','r','linewidth', 2,'linestyle','--');
