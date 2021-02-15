%% set paramaters
chColor = input('Input 0 for green channel. Input 1 for red channel. '); 

%% get registered images 
regImDir = uigetdir('*.*','WHERE ARE THE REGISTERED IMAGES?');
cd(regImDir);
regMatFileName = uigetfile('*.*','GET THE REGISTERED IMAGES');
regMat = matfile(regMatFileName);
regStacks = regMat.regStacks;

%% 