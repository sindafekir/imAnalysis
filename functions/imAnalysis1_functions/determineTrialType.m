function [TrialTypes] = determineTrialType(LED1_amp,LED2_amp)

TrialTypes = zeros(length(LED2_amp),2);
for a = 1:length(LED2_amp)
    TrialTypes(a,1) = a;
     
    if LED2_amp(a) == 0 && LED1_amp(a) == 0
        TrialTypes(a,2) = 0;  
        
    elseif LED1_amp(a) > 0 && LED2_amp(a) == 0 
        TrialTypes(a,2) = 1;

    elseif LED2_amp(a) > 0 && LED1_amp(a) == 0 
        TrialTypes(a,2) = 2;
                  
    end 
            
end 

end 