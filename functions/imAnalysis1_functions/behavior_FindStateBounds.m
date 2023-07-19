function [state_start_f,state_end_f] = behavior_FindStateBounds(state,framePeriod,vid,mouse)

% parse hdf file      
[parsedStruct,~]=csParser2(vid,mouse);
teensyState = parsedStruct.teensyStates; 
sessionTime = parsedStruct.sessionTime;

%Find state start and end times 
[state_start_t,state_end_t] = find_state_bounds(teensyState,sessionTime,state);

if length(state_start_t) > length(state_end_t)
    state_start_t(:,length(state_end_t)+1) = []; 
end 

FPS = 1/framePeriod; 

state_start_f = (state_start_t)*FPS;
state_end_f = (state_end_t)*FPS;
end 