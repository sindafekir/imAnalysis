function [state_start_t,state_end_t] = find_state_boundsHIT(teensyState,sessionTime)

% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% RUN EVERYTHING BELOW TO GET STATE TWO AND STATE 4 START AND END TIMES
% THEN USE THOSE TO FIND THE HIT TRIALS 

[state2]=find(teensyState==2);
[state4]=find(teensyState==4);

% find state 2 - stim start and end times 
diff_state = diff(state2); 

new_stim = find(diff_state ~= 1); 
state_start_ind = new_stim+1; 
state_end_ind = new_stim; 

if isempty(new_stim) == 1
    state_start_ind = 1;
    state_end_ind = length(state2); 
end 

state_start = zeros(1,length(state_start_ind));
for a = 1:length(state_start_ind)
    state_start(a) = state2(state_start_ind(a));
end 

state_end = zeros(1,length(state_end_ind));
for b = 1:length(state_end_ind)
    state_end(b) = state2(state_end_ind(b));
end 

if isempty(new_stim) == 0
    state_start = horzcat(state2(1),state_start);
    state_end = horzcat(state_end,state2(end));
end 
 
state2_start_t = zeros(1,length(state_start));
for c = 1:length(state_start)
    if sessionTime(state_start(c)-1) == 0 
        continue 
    elseif sessionTime(state_start(c)-1) ~= 0 
        state2_start_t(c) = sessionTime(state_start(c)); 
    end 
end 

state2_end_t = zeros(1,length(state_end));
for d = 1:length(state_end)
    if teensyState(end) == 1
        if sessionTime(state_end(d)+1) == 0 
            continue 
        elseif sessionTime(state_end(d)+1) ~= 0 
            state2_end_t(d) = sessionTime(state_end(d));
        end  
    elseif teensyState(end) == 8 && d < length(state_end)
        if sessionTime(state_end(d)+1) == 0 
            continue 
        elseif sessionTime(state_end(d)+1) ~= 0 
            state2_end_t(d) = sessionTime(state_end(d));
        end 
    elseif teensyState(end) == 2 && d < length(state_end)
        if sessionTime(state_end(d)+1) == 0 
            continue 
        elseif sessionTime(state_end(d)+1) ~= 0 
            state2_end_t(d) = sessionTime(state_end(d));
        end 
    elseif teensyState(end) == 4 && d < length(state_end)
        if sessionTime(state_end(d)+1) == 0 
            continue 
        elseif sessionTime(state_end(d)+1) ~= 0 
            state2_end_t(d) = sessionTime(state_end(d));
        end     
    end 
end 

state2_start_t = state2_start_t(state2_start_t ~= 0); 
state2_end_t = state2_end_t(state2_end_t ~= 0); 

if teensyState(end) == 8
    state2_start_t(:,length(state2_end_t)+1) = [];
end 

if isempty(new_stim) == 1
    state2_start_t = state2_start_t*1000;
    state2_end_t = state2_end_t*1000;
end 
 
% find state 4 - reward start and end times 
diff_state = diff(state4); 

new_stim = find(diff_state ~= 1); 
state_start_ind = new_stim+1; 
state_end_ind = new_stim; 

if isempty(new_stim) == 1
    state_start_ind = 1;
    state_end_ind = length(state4); 
end 

state_start = zeros(1,length(state_start_ind));
for a = 1:length(state_start_ind)
    state_start(a) = state4(state_start_ind(a));
end 

state_end = zeros(1,length(state_end_ind));
for b = 1:length(state_end_ind)
    state_end(b) = state4(state_end_ind(b));
end 

if isempty(new_stim) == 0
    state_start = horzcat(state4(1),state_start);
    state_end = horzcat(state_end,state4(end));
end 
 
state4_start_t = zeros(1,length(state_start));
for c = 1:length(state_start)
    if sessionTime(state_start(c)-1) == 0 
        continue 
    elseif sessionTime(state_start(c)-1) ~= 0 
        state4_start_t(c) = sessionTime(state_start(c)); 
    end 
end 

state4_end_t = zeros(1,length(state_end));
for d = 1:length(state_end)
    if teensyState(end) == 1
        if sessionTime(state_end(d)+1) == 0 
            continue 
        elseif sessionTime(state_end(d)+1) ~= 0 
            state4_end_t(d) = sessionTime(state_end(d));
        end  
    elseif teensyState(end) == 8 && d < length(state_end)
        if sessionTime(state_end(d)+1) == 0 
            continue 
        elseif sessionTime(state_end(d)+1) ~= 0 
            state4_end_t(d) = sessionTime(state_end(d));
        end 
    elseif teensyState(end) == 2 && d < length(state_end)
        if sessionTime(state_end(d)+1) == 0 
            continue 
        elseif sessionTime(state_end(d)+1) ~= 0 
            state4_end_t(d) = sessionTime(state_end(d));
        end 
    elseif teensyState(end) == 4 && d < length(state_end)
        if sessionTime(state_end(d)+1) == 0 
            continue 
        elseif sessionTime(state_end(d)+1) ~= 0 
            state4_end_t(d) = sessionTime(state_end(d));
        end     
    end 
end 

state4_start_t = state4_start_t(state4_start_t ~= 0); 
state4_end_t = state4_end_t(state4_end_t ~= 0); 

if teensyState(end) == 8
    state4_start_t(:,length(state4_end_t)+1) = [];
end 

if isempty(new_stim) == 1
    state4_start_t = state4_start_t*1000;
    state4_end_t = state4_end_t*1000;
end 

% figure out what trials are hit trials (are rewarded) 


end 