function [state_start_t,state_end_t] = find_state_bounds(teensyState,sessionTime,state)


[state]=find(teensyState==state);
diff_state = diff(state); 

new_stim = find(diff_state ~= 1); 
state_start_ind = new_stim+1; 
state_end_ind = new_stim; 

if isempty(new_stim) == 1
    state_start_ind = 1;
    state_end_ind = length(state); 
end 

state_start = zeros(1,length(state_start_ind));
for a = 1:length(state_start_ind)
    state_start(a) = state(state_start_ind(a));
end 

state_end = zeros(1,length(state_end_ind));
for b = 1:length(state_end_ind)
    state_end(b) = state(state_end_ind(b));
end 

if isempty(new_stim) == 0
    state_start = horzcat(state(1),state_start);
    state_end = horzcat(state_end,state(end));
end 
 
state_start_t = zeros(1,length(state_start));
for c = 1:length(state_start)
    if sessionTime(state_start(c)-1) == 0 
        continue 
    elseif sessionTime(state_start(c)-1) ~= 0 
        state_start_t(c) = sessionTime(state_start(c)); 
    end 
end 

state_end_t = zeros(1,length(state_end));
for d = 1:length(state_end)
    if teensyState(end) == 1
        if sessionTime(state_end(d)+1) == 0 
            continue 
        elseif sessionTime(state_end(d)+1) ~= 0 
            state_end_t(d) = sessionTime(state_end(d));
        end  
    elseif teensyState(end) == 8 && d < length(state_end)
        if sessionTime(state_end(d)+1) == 0 
            continue 
        elseif sessionTime(state_end(d)+1) ~= 0 
            state_end_t(d) = sessionTime(state_end(d));
        end 
    end 
end 

state_start_t = state_start_t(state_start_t ~= 0); 
state_end_t = state_end_t(state_end_t ~= 0); 

if teensyState(end) == 8
    state_start_t(:,length(state_end_t)+1) = [];
end 

if isempty(new_stim) == 1
    state_start_t = state_start_t*1000;
    state_end_t = state_end_t*1000;
end 
 

end 