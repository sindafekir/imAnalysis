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
imStackDir = fileList(1).folder; %userInput(UIr,1) = ("Where Photos Are Found"); userInput(UIr,2) = (imStackDir); UIr = UIr+1;
greenStackLength = size(fileList,1)/2;
redStackLength = size(fileList,1)/2;
image = imread(fileList(1).name); 
redImageStack = zeros(size(image,1),size(image,2),redStackLength);
for frame = 1:redStackLength 
    image = imread(fileList(frame).name); 
    redImageStack(:,:,frame) = image;
end 
count = 1; 
greenImageStack = zeros(size(image,1),size(image,2),greenStackLength);
for frame = redStackLength+1:(greenStackLength*2) 
    image = imread(fileList(frame).name); 
    greenImageStack(:,:,count) = image;
    count = count + 1;
end 
%}

%% separate volume imaging data into separate stacks per z plane and motion correction

if volIm == 1
    disp('Separating Z-planes')
    %reorganize data by zPlane and prep for motion correction 
    [gZstacks] = splitStacks(greenImageStack,splitType,numZplanes);
    [gVolStack] = reorgVolStack(greenImageStack,splitType,numZplanes);
    [rZstacks] = splitStacks(redImageStack,splitType,numZplanes);
    [rVolStack] = reorgVolStack(redImageStack,splitType,numZplanes);        

    %3D registration     
    disp('3D Motion Correction')
    %need minimum 4 planes in Z for 3D registration to work-time to interpolate
    gVolStack5 = zeros(size(gVolStack,1),size(gVolStack,2),size(gVolStack,3)+size(gVolStack,3)-1,size(gVolStack,4));
    rVolStack5 = zeros(size(rVolStack,1),size(rVolStack,2),size(gVolStack,3)+size(gVolStack,3)-1,size(gVolStack,4));
    parfor ind = 1:size(gVolStack,4)
        count = 1;
        for zplane = 1:size(gVolStack,3)+size(gVolStack,3)-1
            if rem(zplane,2) == 0
                gVolStack5(:,:,zplane,ind) = mean(gVolStack(:,:,count-1:count,ind),3);
                rVolStack5(:,:,zplane,ind) = mean(rVolStack(:,:,count-1:count,ind),3);
            elseif rem(zplane,2) == 1 
                gVolStack5(:,:,zplane,ind) = gVolStack(:,:,count,ind);
                rVolStack5(:,:,zplane,ind) = rVolStack(:,:,count,ind);
                count = count +1;
            end 
        end 
    end 

    gTemplate = mean(gVolStack5,4);
    rTemplate = mean(rVolStack5,4);
    %create optimizer and metric, setting modality to multimodal because the
    %template and actual images look different (as template is mean = smoothed)
    [optimizer, metric] = imregconfig('multimodal')    ;
    %tune the poperties of the optimizer
    optimizer.InitialRadius = 0.004;
    optimizer.Epsilon = 1.5;
    optimizer.GrowthFactor = 1.01;
    optimizer.MaximumIterations = 300;
    for ind = 1:size(gVolStack,4)
        ggRegVolStack(:,:,:,ind) = imregister(gVolStack5(:,:,:,ind),gTemplate,'affine', optimizer, metric,'PyramidLevels',1);
        rrRegVolStack(:,:,:,ind) = imregister(rVolStack5(:,:,:,ind),rTemplate,'affine', optimizer, metric,'PyramidLevels',1);
    end 
    [ggVZstacks5] = volStack2splitStacks(ggRegVolStack);
    [rrVZstacks5] = volStack2splitStacks(rrRegVolStack);
    %get rid of extra z planes
    count = 1; 
    ggVZstacks3 = cell(1,size(gZstacks,2));
    rrVZstacks3 = cell(1,size(gZstacks,2));
    for zPlane = 1:size(gZstacks,2)
        ggVZstacks3{zPlane} = ggVZstacks5{count};
        rrVZstacks3{zPlane} = rrVZstacks5{count};
        count = count+2;
    end 

    %package data for output 
    regStacks{2,3} = ggVZstacks3; regStacks{1,3} = 'ggVZstacks3';     
    regStacks{2,4} = rrVZstacks3; regStacks{1,4} = 'rrVZstacks3';

elseif volIm == 0   
    disp('2D Motion Correction')
    %2D register imaging data    
    gTemplate = mean(greenImageStack,3);
    [ggRegStack,~] = registerVesStack(greenImageStack,gTemplate);  
    ggRegZstacks{1} = ggRegStack;
    rTemplate = mean(redImageStack,3);
    [rrRegStack,~] = registerVesStack(redImageStack,rTemplate);  
    rrRegZstacks{1} = rrRegStack;

    %package data for output 
    regStacks{2,1} = ggRegZstacks; regStacks{1,1} = 'ggRegZstacks';
    regStacks{2,2} = rrRegZstacks; regStacks{1,2} = 'rrRegZstacks';  
end 
%}

%% check registration 
%{
if volIm == 1     
    %check relationship b/w template and 3D registered images
    count = 1; 
    ggTemp2regCorr3D = zeros(size(gZstacks,2),size(ggVZstacks3{1},3));
    rrTemp2regCorr3D = zeros(size(rZstacks,2),size(rrVZstacks3{1},3));
    for zPlane = 1:size(gZstacks,2)
        for ind = 1:size(ggVZstacks3{1},3)
            ggTemp2regCorr3D(zPlane,ind) = corr2(gTemplate(:,:,count),ggVZstacks3{zPlane}(:,:,ind));
            rrTemp2regCorr3D(zPlane,ind) = corr2(rTemplate(:,:,count),rrVZstacks3{zPlane}(:,:,ind));
        end 
        count = count+2;
    end 
    %plot 3D registration for comparison 
    figure;
    subplot(1,2,1);
    hold all; 
    for zPlane = 1:size(gZstacks,2)
        plot(ggTemp2regCorr3D(zPlane,:));
        title({'Correlation Coefficient of 3D Motion Correction Template and Output';'Green Channel Registered with Green Channel Template'}); 
    end 
    subplot(1,2,2);
    hold all; 
    for zPlane = 1:size(rZstacks,2)
        plot(rrTemp2regCorr3D(zPlane,:));
        title({'Correlation Coefficient of 3D Motion Correction Template and Output';'Red Channel Registered with Red Channel Template'}); 
    end     
elseif volIm == 0 
    %check relationship b/w template and 2D registered images     
    ggTemp2regCorr2D = zeros(1,size(ggRegZstacks{1},3));
    rrTemp2regCorr2D = zeros(1,size(rrRegZstacks{1},3));
    for ind = 1:size(ggRegZstacks{1},3)
        ggTemp2regCorr2D(ind) = corr2(gTemplate,ggRegZstacks{1}(:,:,ind));
        rrTemp2regCorr2D(ind) = corr2(rTemplate,rrRegZstacks{1}(:,:,ind));
    end 
    %plot 2D registrations for comparison 
    figure;
    subplot(1,2,1);
    plot(ggTemp2regCorr2D);
    title({'Correlation Coefficient of 2D Motion Correction Template and Output';'Green Channel Registered with Green Channel Template'}); 
    subplot(1,2,2);
    plot(rrTemp2regCorr2D);
    title({'Correlation Coefficient of 2D Motion Correction Template and Output';'Red Channel Registered with Red Channel Template'}); 
end 
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
