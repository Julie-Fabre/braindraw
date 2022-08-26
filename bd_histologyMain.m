
%% ~~ Histology main ~~ %%
% - add option to use elastix
% - don't fit some parts that are prone to being moved (eg olf bulbs, pposterior cortex (eg retrospenial
% ect) ?

%% Images info %%
myPaths; % see JF_scripts_cortexlab
animal = 'JF070';

% registration parameters
orientationType = 'psl';
channelColToRegister = 'green';
atlasUM = 25;
atlasSpecies = 'mouse';
atlasType = 'allen';

% registration location/files
atlasLocation = dir(['/home/julie/.brainglobe/', atlasType, '_', atlasSpecies, '_', num2str(atlasUM), 'um*']); % atlas location + atlas to use
channelToRegister = dir([brainsawPath, '/*/', animal, '/downsampled_stacks/025_micron/*', channelColToRegister, '*.tif*']);
outputDir = [channelToRegister.folder, filesep, 'brainReg'];

%% Load in images and template %%
[tv, av, st, bregma] = bd_loadAllenAtlas(atlasLocation.folder);

%% Register %%
bd_brainreg([channelToRegister.folder, filesep, channelToRegister.name], outputDir, orientationType, atlasUM)
registeredImage = loadtiff([outputDir, filesep, 'downsampled_standard.tiff']);
bd_convertToAPFormat(registeredImage, tv, av, outputDir)

%% Apply registration transform to other channel %% 
bd_applyBrainReg()

%% Manually check and adjust registration %%
screenToUse = 2;
bd_checkAndCorrectAlign(tv, av, st, registeredImage, outputDir, screenToUse)
% histology_ccf.mat : corresponding CCF slices
% atlas2histology_tform.mat : histology/ccf alignement/warp

%% Draw probes %%
bd_drawProbes(tv, av, st, registeredImage, outputDir)

%% Assign probes to days/sites and save data %%