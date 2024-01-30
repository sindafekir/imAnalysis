function [state_start_f,state_end_f] = behavior_FindStateBoundsHitOrMiss(framePeriod,vid,mouse,state2)

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

% get the hit or miss trials 
if state2 == 0 % hit trials 
    hitTrials = find(responses == 1);
    state_start_t = state_start_t(hitTrials);
    state_end_t = state_end_t(hitTrials);
elseif state2 == 1 % miss trials 
    missTrials = find(responses == 0);
    state_start_t = state_start_t(missTrials);
    state_end_t = state_end_t(missTrials);
end 

FPS = 1/framePeriod; 

state_start_f = (state_start_t)*FPS;
state_end_f = (state_end_t)*FPS;
end 