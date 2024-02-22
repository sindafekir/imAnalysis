function [state_start_f,state_end_f] = behavior_FindStateBoundsRewardMiss(framePeriod,vid,mouse)

[parsedStruct,~]=csParser2(vid,mouse);
teensyState = parsedStruct.teensyStates; 
sessionTime = parsedStruct.sessionTime;
responses = parsedStruct.responses; 

%Find state start and end times 
[state_start_t,state_end_t] = find_state_bounds(teensyState,sessionTime,2);

if length(state_start_t) > length(state_end_t)
    state_start_t(:,length(state_end_t)+1) = []; 
    responses(length(state_end_t)+1,:) = [];
end 

% get the miss trials 
missTrials = find(responses == 0);
if any(missTrials > length(state_start_t))
    removeInds = find(missTrials >= length(state_start_t));
    missTrials(removeInds) = [];
end 
state_start_t = state_start_t(missTrials);
state_end_t = state_end_t(missTrials);

FPS = 1/framePeriod; 
state_start_f = (state_start_t)*FPS;
state_end_f = (state_end_t)*FPS;

% acount for the time shift 
timeShift = input('Input how much time (sec) there was between the stim and the reward. ');
frameShift = timeShift*FPS;
state_start_f = state_start_f + frameShift;
state_end_f = state_end_f + frameShift;
end 