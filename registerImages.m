%% set the paramaters 
%{
volIm = input("Is this volume imaging data? Yes = 1. No = 0. "); 
if volIm == 1
    splitType = input('How must the data be split? Serial Split = 0. Alternating Split = 1. '); 
    numZplanes = input('How many Z planes are there? ');
elseif volIm == 0
    numZplanes = 1; 
end 
%}
%% get the images 
%{
disp('Importing Images')
cd(uigetdir('*.*','WHERE ARE THE PHOTOS? '));    
fileList = dir('*.tif*');
imStackDir = fileList(1).folder; 
redChanQ = input('Input 1 to import red channel. Input 0 otherwise. ');
greenChanQ = input('Input 1 to import green channel. Input 0 otherwise. ');
frameAvQ = input('Input 1 if you need to frame average. Input 0 otherwise. ');
if frameAvQ == 0 
    if redChanQ == 1 
        redStackLength = size(fileList,1)/2;
        image = imread(fileList(1).name); 
        redImageStack = zeros(size(image,1),size(image,2),redStackLength);
        for frame = 1:redStackLength 
            image = imread(fileList(frame).name); 
            redImageStack(:,:,frame) = image;
        end 
    end 
    if greenChanQ == 1 
        greenStackLength = size(fileList,1)/2;    
        count = 1; 
        greenImageStack = zeros(size(image,1),size(image,2),greenStackLength);
        for frame = redStackLength+1:(greenStackLength*2) 
            image = imread(fileList(frame).name); 
            greenImageStack(:,:,count) = image;
            count = count + 1;
        end 
    end
elseif frameAvQ == 1
    frameAvNum = input('How many frames do you want to average together? '); 
    xyDownQ = input('Input 1 if you need to downsample in the x and y dimensions. ');
    downFactor = 1;
    if xyDownQ == 1
        downFactor = input('How much do you want to downsample the x and y dimensions? ');
    end 
    if redChanQ == 1 
        redStackLength = ceil((size(fileList,1)/2)/frameAvNum);       
        image = imread(fileList(1).name); 
        avFrames = zeros(size(image,1),size(image,2),frameAvNum);
        redImageStack = zeros((size(image,1)/downFactor),(size(image,2)/downFactor),redStackLength);
        avFrame = 1;
        count = 1;
        for frame = 1:(size(fileList,1)/2)
            image = imread(fileList(frame).name); 
            avFrames(:,:,avFrame) = image;
            avFrame = avFrame + 1;
            if avFrame > frameAvNum       
                avIm = mean(avFrames,3);
                downAvIm1 = downsample(avIm,downFactor);
                downAvIm2 = downsample(downAvIm1',downFactor);
                redImageStack(:,:,count) = downAvIm2;
                count = count + 1;
                avFrame = 1;
            end                   
        end 
    end 
    if greenChanQ == 1 
        greenStackLength = ceil((size(fileList,1)/2)/frameAvNum);
        image = imread(fileList(1).name); 
        avFrames = zeros(size(image,1),size(image,2),frameAvNum);
        greenImageStack = zeros((size(image,1)/downFactor),(size(image,2)/downFactor),greenStackLength);
        avFrame = 1;
        count = 1; 
        for frame = (size(fileList,1)/2)+1:size(fileList,1) %CHECK THESE VALUES FOR BELOW TO BE CORRECT
            image = imread(fileList(frame).name); 
            avFrames(:,:,avFrame) = image;
            avFrame = avFrame + 1;
            if avFrame > frameAvNum      
                avIm = mean(avFrames,3);
                downAvIm1 = downsample(avIm,downFactor);
                downAvIm2 = downsample(downAvIm1',downFactor);
                greenImageStack(:,:,count) = downAvIm2;
                count = count + 1;
                avFrame = 1;
            end         
        end 
    end
end 
%}
%% separate volume imaging data into separate stacks per z plane and motion correction
%{
templateQ = input('Input 0 if you want the template to be the average of all frames. Not recommended if there is scramble. Input 1 otherwise. ');
if templateQ == 1
    if redChanQ == 1 
        fprintf('    %d red frames. ', size(redImageStack,3));
    end 
    if greenChanQ == 1
        fprintf('    %d green frames. ', size(greenImageStack,3));
    end 
    numTemplate = input('    Input the number of frames you want to use for the registration templates. ');
end 
if volIm == 1
    disp('Separating Z-planes')
    %reorganize data by zPlane and prep for motion correction 
    if redChanQ == 1
        [rZstacks] = splitStacks(redImageStack,splitType,numZplanes);
        [rVolStack] = reorgVolStack(redImageStack,splitType,numZplanes); 
    end 
    if greenChanQ == 1 
        [gZstacks] = splitStacks(greenImageStack,splitType,numZplanes);
        [gVolStack] = reorgVolStack(greenImageStack,splitType,numZplanes);
    end 
    
    %3D registration     
    disp('3D Motion Correction')
    %need minimum 4 planes in Z for 3D registration to work-time to interpolate
    if redChanQ == 1 
        rVolStack5 = zeros(size(rVolStack,1),size(rVolStack,2),size(gVolStack,3)+size(gVolStack,3)-1,size(gVolStack,4));
    end 
    if greenChanQ == 1 
        gVolStack5 = zeros(size(gVolStack,1),size(gVolStack,2),size(gVolStack,3)+size(gVolStack,3)-1,size(gVolStack,4));
    end 
    parfor ind = 1:size(gVolStack,4)
        count = 1;
        for zplane = 1:size(gVolStack,3)+size(gVolStack,3)-1
            if rem(zplane,2) == 0
                if redChanQ == 1 
                    rVolStack5(:,:,zplane,ind) = mean(rVolStack(:,:,count-1:count,ind),3);
                end 
                if greenChanQ == 1 
                    gVolStack5(:,:,zplane,ind) = mean(gVolStack(:,:,count-1:count,ind),3);
                end 
            elseif rem(zplane,2) == 1 
                if redChanQ == 1 
                    rVolStack5(:,:,zplane,ind) = rVolStack(:,:,count,ind);
                end 
                if greenChanQ == 1 
                    gVolStack5(:,:,zplane,ind) = gVolStack(:,:,count,ind);
                end 
                count = count +1;
            end 
        end 
    end 
    if redChanQ == 1 
        if templateQ == 0
            rTemplate = mean(rVolStack5,4);
        elseif templateQ == 1 
            rTemplate = mean(rVolStack5(:,:,1:numTemplate,:),4);
        end 
    end 
    if greenChanQ == 1 
        if templateQ == 0
            gTemplate = mean(gVolStack5,4);
        elseif templateQ == 1 
            gTemplate = mean(gVolStack5(:,:,1:numTemplate,:),4);
        end             
    end
    %create optimizer and metric, setting modality to multimodal because the
    %template and actual images look different (as template is mean = smoothed)
    [optimizer, metric] = imregconfig('multimodal')    ;
    %tune the poperties of the optimizer
    optimizer.InitialRadius = 0.004;
    optimizer.Epsilon = 1.5;
    optimizer.GrowthFactor = 1.01;
    optimizer.MaximumIterations = 300;
    for ind = 1:size(gVolStack,4)
        if redChanQ == 1 
            rrRegVolStack(:,:,:,ind) = imregister(rVolStack5(:,:,:,ind),rTemplate,'affine', optimizer, metric,'PyramidLevels',1);
        end 
        if greenChanQ == 1
            ggRegVolStack(:,:,:,ind) = imregister(gVolStack5(:,:,:,ind),gTemplate,'affine', optimizer, metric,'PyramidLevels',1);
        end 
    end 
    if redChanQ == 1 
        [rrVZstacks5] = volStack2splitStacks(rrRegVolStack);
        %get rid of extra z planes
        count = 1; 
        rrVZstacks3 = cell(1,size(gZstacks,2));
        for zPlane = 1:size(gZstacks,2)
            rrVZstacks3{zPlane} = rrVZstacks5{count};
            count = count+2;
        end 
        %package data for output 
        regStacks{2,4} = rrVZstacks3; regStacks{1,4} = 'rrVZstacks3';
    end 
    if greenChanQ == 1
        [ggVZstacks5] = volStack2splitStacks(ggRegVolStack);
        %get rid of extra z planes
        count = 1; 
        ggVZstacks3 = cell(1,size(gZstacks,2));
        for zPlane = 1:size(gZstacks,2)
            ggVZstacks3{zPlane} = ggVZstacks5{count};
            count = count+2;
        end 
        %package data for output 
        regStacks{2,3} = ggVZstacks3; regStacks{1,3} = 'ggVZstacks3';    
    end 

elseif volIm == 0   
    if redChanQ == 1 
        disp('2D Motion Correction')
        %2D register imaging data  
        if templateQ == 0
            rTemplate = mean(redImageStack,3);
        elseif templateQ == 1 
            rTemplate = mean(redImageStack(:,:,1:numTemplate),3);
        end             
%         rTemplate = mean(redImageStack(:,:,1:42),3);
        [rrRegStack,~] = registerVesStack(redImageStack,rTemplate);  
        rrRegZstacks{1} = rrRegStack;
        
        %package data for output 
        regStacks{2,2} = rrRegZstacks; regStacks{1,2} = 'rrRegZstacks';  
    end 
    if greenChanQ == 1
        disp('2D Motion Correction')
        %2D register imaging data    
        if templateQ == 0
            gTemplate = mean(greenImageStack,3);
        elseif templateQ == 1 
            gTemplate = mean(greenImageStack(:,:,1:numTemplate),3);
        end   
%         gTemplate = mean(greenImageStack(:,:,1:42),3);
        [ggRegStack,~] = registerVesStack(greenImageStack,gTemplate);  
        ggRegZstacks{1} = ggRegStack;
   
        %package data for output 
        regStacks{2,1} = ggRegZstacks; regStacks{1,1} = 'ggRegZstacks';
    end 
end 
%}
%% check registration 
%{
if volIm == 1     
    %check relationship b/w template and 3D registered images
    if redChanQ == 1
        count = 1; 
        rrTemp2regCorr3D = zeros(size(rZstacks,2),size(rrVZstacks3{1},3));
        for zPlane = 1:size(rZstacks,2)
            for ind = 1:size(rrVZstacks3{1},3)
                rrTemp2regCorr3D(zPlane,ind) = corr2(rTemplate(:,:,count),rrVZstacks3{zPlane}(:,:,ind));
            end 
            count = count+2;
        end 
    end 
    if greenChanQ == 1
        count = 1; 
        ggTemp2regCorr3D = zeros(size(gZstacks,2),size(ggVZstacks3{1},3));
        for zPlane = 1:size(gZstacks,2)
            for ind = 1:size(ggVZstacks3{1},3)
                ggTemp2regCorr3D(zPlane,ind) = corr2(gTemplate(:,:,count),ggVZstacks3{zPlane}(:,:,ind));
            end 
            count = count+2;
        end 
    end 
    
    %plot 3D registration for comparison 
    figure;
    subplot(1,2,1);
    hold all; 
    if greenChanQ == 1
        for zPlane = 1:size(gZstacks,2)
            plot(ggTemp2regCorr3D(zPlane,:));
            title({'Correlation Coefficient of 3D Motion Correction Template and Output';'Green Channel Registered with Green Channel Template'}); 
        end 
        subplot(1,2,2);
    end 
    hold all; 
    if redChanQ == 1
        for zPlane = 1:size(rZstacks,2)
            plot(rrTemp2regCorr3D(zPlane,:));
            title({'Correlation Coefficient of 3D Motion Correction Template and Output';'Red Channel Registered with Red Channel Template'}); 
        end
    end
elseif volIm == 0 
    if redChanQ == 1
        %check relationship b/w template and 2D registered images    
        rrTemp2regCorr2D = zeros(1,size(rrRegZstacks{1},3));
        for ind = 1:size(rrRegZstacks{1},3)
            rrTemp2regCorr2D(ind) = corr2(rTemplate,rrRegZstacks{1}(:,:,ind));
        end 
    end 
    if greenChanQ == 1
        %check relationship b/w template and 2D registered images     
        ggTemp2regCorr2D = zeros(1,size(ggRegZstacks{1},3));
        for ind = 1:size(ggRegZstacks{1},3)
            ggTemp2regCorr2D(ind) = corr2(gTemplate,ggRegZstacks{1}(:,:,ind));
        end 
    end 
    
    %plot 2D registrations for comparison 
    figure;
    if greenChanQ == 1
        subplot(1,2,1);
        plot(ggTemp2regCorr2D);
        title({'Correlation Coefficient of 2D Motion Correction Template and Output';'Green Channel Registered with Green Channel Template'}); 
    end 
    if redChanQ == 1
        subplot(1,2,2);
        plot(rrTemp2regCorr2D);
        title({'Correlation Coefficient of 2D Motion Correction Template and Output';'Red Channel Registered with Red Channel Template'}); 
    end 
end 

%
% implay(ggRegZstacks{1});
% implay(greenImageStack);
%}
%% save registered stacks 
%{
clearvars -except regStacks
vid = input('What number video is this? '); 

%make the directory and save the images 
dir1 = input('What folder are you saving these images in? ');
dir2 = strrep(dir1,'\','/');
filename = sprintf('%s/regStacks_vid%d',dir2,vid);
save(filename)
%}
 