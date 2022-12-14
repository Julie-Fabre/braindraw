
%% Histology main
% QQ to do: 
% - add option to use elastix
% - don't fit some parts that are prone to being moved (eg olf bulbs, posterior cortex (eg retrospenial
% ect) ?
% - add option to change atlas orientation post automatic alignement

%% ~ Images info
myPaths; % see https://github.com/Julie-Fabre/JF_Scripts_CortexLab/blob/master/load/myPaths.m. 
% loads in a bunch of paths, of which only one is used in this script: brainsawPath
animal = 'JF067';

% registration parameters
orientationType = 'psl'; % psl (for posterior, superior, left), means the first, top left voxel
% is the most posterior, superior, left part of the brain
channelColToRegister = 'green'; % channel you want to register 
channelColToTransform = 'red'; % channel you want to use to draw probes
atlasResolution_um = 25; % voxel size. currently in all dimensions, both for atlas and acquired image
atlasSpecies = 'mouse'; % atlas species
atlasType = 'allen'; % atlas name
brainglobeLocation = '/home/julie/.brainglobe/'; % where your brainglobe data lives 

% registration location/files
[atlasLocation, imgToRegister, imgToTransform, outputDir] =...
    bd_getLocations(brainglobeLocation, brainsawPath, animal, channelColToRegister, ...
    channelColToTransform, atlasType, atlasSpecies, atlasResolution_um);

%% ~ Load in images and template ~
[tv, av, st, bregma] = bd_loadAllenAtlas([atlasLocation.folder, filesep, atlasLocation.name]);

%% ~ Register ~
if isempty(dir([outputDir, filesep, 'downsampled_standard.tiff']))
    bd_brainreg([imgToRegister.folder, filesep, imgToRegister.name], outputDir, ...
        [imgToTransform.folder, filesep, imgToTransform.name],orientationType, atlasResolution_um)% run brainreg
end
registeredImage = loadtiff([outputDir, filesep, 'downsampled_standard.tiff']);
bd_convertToAPFormat(registeredImage, tv, av, outputDir) % get and save atlas data in standard

% AP format to be able to use AP functions

%% ~ Manually check and adjust registration ~
screenToUse = 2; % on which of your displays to create the following plots. 1 = main display, 2 = secondary and so on

%% ~~ Check and adjust orientation ~~
% Adjust the atlas to one slice (using arrow keys to navigate in the allen ccf and pressing eneter once you're happy) 
% and this transformation will then be applied to all other slices and saved in a histology_ccf.mat file.
% If you register several slices, the average transform will be applied to
% all other slices and saved. 
if isempty(dir([outputDir, filesep, 'manual', filesep, 'histology_ccf.mat']))
    bd_checkAndCorrectAtlasOrientation(tv, av, st, registeredImage, outputDir, screenToUse); 
end
%% ~~ [WIP] Check adjust border alignement/scaling ~~
if isempty(dir([outputDir, filesep, 'manual', filesep, 'atlas2histology_tform.mat']))
    bd_checkAndCorrectAtlasAlignment(tv, av, st, registeredImage, outputDir, screenToUse)
end
% histology_ccf.mat : corresponding CCF slices
% atlas2histology_tform.mat : ccf to histology alignement/warp

%% ~ Draw probes ~
% QQ to add: draw both bspine fit and affine, choose which to use for each
% probe 
transformedImageDir = dir([outputDir, filesep, 'downsampled_standard_*.tiff']);
transformedImage = loadtiff([transformedImageDir.folder, filesep, transformedImageDir.name]);
bd_drawProbes(tv, av, st, transformedImage, outputDir, screenToUse) % draw probes. it you have more than 9 probes, 
% use shift to add 10, alt to add 20 and ctrl to add 30 (so shift+1 lets you select probe 11) 

%% ~ Assign probes to days/sites ~
% combine all probe ccfs 
probe_ccf_full = probe_ccf;
load([outputDir, '/probe_ccf.mat'])
probe_ccf_full(1).points = probe_ccf(1).points;
probe_ccf_full(1).trajectory_coords = probe_ccf(1).trajectory_coords;
probe_ccf_full(1).trajectory_areas = probe_ccf(1).trajectory_areas;
save([outputDir, '/probe_ccf.mat'], 'probe_ccf')
% load([outputDir, filesep, 'probe_ccf1.mat'])
% probe_ccf_full = probe_ccf;
% load([outputDir, filesep, 'probe_ccf2.mat'])
% theseP = find(logical(abs(cellfun(@isempty,{probe_ccf.points})-1)));
% for iProbe = theseP
% probe_ccf_full(iProbe).points = probe_ccf(iProbe).points;
% probe_ccf_full(iProbe).trajectory_coords = probe_ccf(iProbe).trajectory_coords;
% probe_ccf_full(iProbe).trajectory_areas = probe_ccf(iProbe).trajectory_areas;
% end
% load([outputDir, filesep, 'probe_ccf3.mat'])
% theseP = find(logical(abs(cellfun(@isempty,{probe_ccf.points})-1)));
% for iProbe = theseP
% probe_ccf_full(iProbe).points = probe_ccf(iProbe).points;
% probe_ccf_full(iProbe).trajectory_coords = probe_ccf(iProbe).trajectory_coords;
% probe_ccf_full(iProbe).trajectory_areas = probe_ccf(iProbe).trajectory_areas;
% end
% 4 shank-ify 
% fourShankStarts = [5,9,13,17,21,25,29];
% iProbe = fourShankStarts(7);
% max_points = min(size(probe_ccf_full(iProbe).points,1), size(probe_ccf_full(iProbe+1).points,1));
% four_shank_breadth = nanmean((probe_ccf_full(iProbe).points(1:max_points,:)  - ...
%            probe_ccf_full(iProbe+1).points(1:max_points,:)) / 2);
%        
% probe_ccf_full(iProbe+1).points = probe_ccf_full(iProbe).points - four_shank_breadth;
% probe_ccf_full(iProbe+2).points = probe_ccf_full(iProbe+1).points - (four_shank_breadth);
% probe_ccf_full(iProbe+3).points = probe_ccf_full(iProbe+1).points - (2*four_shank_breadth);


bd_plotHistoPerMouse(animal);

% plot and assign
probe2ephys = struct; 
load([outputDir, '/probe2ephys.mat'])
probe2ephys(21).day = 1;
probe2ephys(21).site = 2;
probe2ephys(21).shank = NaN;
probe2ephys(21).recording = [1,2];

probe2ephys(4).day = 1;
probe2ephys(4).site = 1;
probe2ephys(4).shank = NaN;
probe2ephys(4).recording = [1,2];

probe2ephys(1).day = 3;
probe2ephys(1).site = 1;
probe2ephys(1).shank = NaN;

probe2ephys(2).day = 2;
probe2ephys(2).site = 3;
probe2ephys(2).shank = NaN;


probe2ephys(3).day = 2;
probe2ephys(3).site = 1;
probe2ephys(3).shank = NaN;

probe2ephys(5).day = 4;
probe2ephys(5).site = 1;
probe2ephys(5).shank = 1;

probe2ephys(6).day = 4;
probe2ephys(6).site = 1;
probe2ephys(6).shank = 2;


probe2ephys(7).day = 4;
probe2ephys(7).site = 1;
probe2ephys(7).shank = 3;


probe2ephys(8).day = 4;
probe2ephys(8).site = 1;
probe2ephys(8).shank = 4;


probe2ephys(9).day = 3;
probe2ephys(9).site = 2;
probe2ephys(9).shank = 1;

probe2ephys(13).day = 2;
probe2ephys(13).site = 4;
probe2ephys(13).shank = 1;

probe2ephys(17).day = 2;
probe2ephys(17).site = 2;
probe2ephys(17).shank = 1;


save([outputDir, '/probe2ephys.mat'], 'probe2ephys')
save([outputDir, '/probe2ephys_safe.mat'], 'probe2ephys')
%% ~ Align ephys and histology ~
% - add "5 min histology recs" look at
% - check out imro file , plot 
% - plot probe in image overlay (rotated on probe axis)
iProbe = 4;
site = probe2ephys(iProbe).site;
experiments = AP_find_experimentsJF(animal, '', true);
experiments = experiments([experiments.ephys]);
day = experiments(probe2ephys(iProbe).day).day;
if isfield(probe2ephys, 'recording') && ~isempty(probe2ephys(iProbe).recording)
    recording = probe2ephys(iProbe).recording(1);
else
    recording = [];
end
shank = probe2ephys(iProbe).shank;
experiment = 2;
lfp=NaN;
load_sync=true;
JF_load_experiment;

bd_alignEphysAndHistology(st, outputDir, ...
                spike_times, spike_templates, template_depths, ...
                spike_xdepths, template_xdepths,lfp, channel_positions(:,2),channel_positions(:,1), ...
                iProbe, isSpikeGlx, shank);

%% ~ Various useful plotting functions ~ 