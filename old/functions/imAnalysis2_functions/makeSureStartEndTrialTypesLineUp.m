function [state_start_f,state_end_f,TrialTypes] = makeSureStartEndTrialTypesLineUp(reg_Stacks,state_start_f,state_end_f,TrialTypes,numZplanes)
state_start_f = floor(state_start_f/numZplanes); 
state_end_f = ceil(state_end_f/numZplanes);

state_start_f = floor(state_start_f);
checkStartf = 1;
while checkStartf == 1
    if state_start_f(end) > size(reg_Stacks{1},3)
        state_start_f(end) = [];
        state_end_f(end) = [];
        
    elseif state_start_f(end) <= size(reg_Stacks{1},3)
        checkStartf = 0;
    end 
end

if length(TrialTypes) > length(state_start_f)
    TrialTypes(length(state_start_f)+1:end,:) = [];
end  

if length(state_end_f) > length(state_start_f)
    state_end_f(length(state_start_f)+1:end,:) = [];
end  
end 