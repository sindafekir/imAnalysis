%% average across FOV, plane in Z, and trials  
FOVarray = cell(1,length(Rdata));
FOVav = cell(1,length(Rdata));
Zarray = cell(1,length(Rdata));
Zav = cell(1,length(Rdata));
Tarray = cell(1,length(Rdata));
Tav = cell(1,length(Rdata));
for mouse = 1:length(Rdata)
    for ROI = 1:length(Rdata{mouse})
        for Z = 1:length(Rdata{mouse}{ROI})
            for trialType = 1:length(Rdata{mouse}{ROI}{Z})
                for trial = 1:length(Rdata{mouse}{ROI}{Z}{trialType})
                    for FOV = 1:length(Rdata{mouse}{ROI}{Z}{trialType}{trial})
                        FOVarray{mouse}{ROI}{Z}{trialType}{trial}(FOV,:) = Rdata{mouse}{ROI}{Z}{trialType}{trial}{FOV}; 
                    end 
                    FOVav{mouse}{ROI}{Z}{trialType}{trial} = mean(FOVarray{mouse}{ROI}{Z}{trialType}{trial},1);
                    Zarray{mouse}{ROI}{trialType}{trial}(Z,:) = FOVav{mouse}{ROI}{Z}{trialType}{trial};
                    Zav{mouse}{ROI}{trialType}{trial} = mean(Zarray{mouse}{ROI}{trialType}{trial},1);
                    Tarray{mouse}{ROI}{trialType}(trial,:) = Zav{mouse}{ROI}{trialType}{trial};
                end 
                Tav{mouse}{ROI}{trialType} = mean(Tarray{mouse}{ROI}{trialType},1);
            end             
        end         
    end 
end 

%% create power spectrums of each baseline period per ROI 
pSpects = cell(1,length(Rdata));
freqAxes = cell(1,length(Rdata));
for mouse = 1:length(Rdata)
    for ROI = 1:length(Rdata{mouse})
        for trialType = 1:length(Tav{mouse}{ROI})
            if trialType == 1 || trialType == 3
                FPS = length(Tav{mouse}{ROI}{trialType})/42;
            elseif trialType == 2 || trialType == 4
                FPS = length(Tav{mouse}{ROI}{trialType})/60;
            end 
            
            X = fft(Tav{mouse}{ROI}{trialType}); 
            X2sided = abs(X); %this gives you the 2 sided FT 
            X1sided = X2sided(1:length(X2sided)/2); % the one sided FT 
            pSpects{mouse}{ROI}{trialType} = X1sided;
            N = length(X1sided);

            %determine frequency limit we can resolve
            Lsec = N/FPS;
            f = FPS*((Lsec/2))/Lsec;

            % plot the frequency amplitudes
            freqAxis = linspace(0,f,N);
            freqAxes{mouse}{ROI}{trialType} = freqAxis;
            figure; plot(freqAxis,X1sided); 
            title(sprintf('Mouse %d ROI %d trialType %d Amplitudes as a function of frequency',mouse,ROI,trialType));
            
            
        end 
    end 
end 

% test = Tav{1}{1}{1};
% FPS = 11.35;
% 
% X = fft(test); 
% X2sided = abs(X); %this gives you the 2 sided FT 
% X1sided = X2sided(1:length(X2sided)/2); % the one sided FT 
% N = length(X1sided);
% 
% %determine frequency limit we can resolve
% Lsec = N/FPS;
% f = FPS*((Lsec/2))/Lsec;
% 
% % plot the frequency amplitudes
% freqAxis = linspace(0,f,N);
% figure; plot(freqAxis,X1sided); 
% title('Amplitudes as a function of frequency');
    


%% jitter baseline period start times 

%% average overlap in jittered baseline periods 

%% create power spectrums of jittered baseline period averages 


%% plot TS objects - THIS WORKS JUST NEED TO DO THIS ITERATIVELY WHEN THE TIME COMES 
endTime = 618/SF53_ROI2_FPS;
Tval2 = ((1/SF53_ROI2_FPS): (1/SF53_ROI2_FPS) : (618/SF53_ROI2_FPS));

test2 = timeseries(SF53_ROI2_Bdata{1}{4}{1}{1},Tval2);
plot(test1)
hold on
plot(test2)
