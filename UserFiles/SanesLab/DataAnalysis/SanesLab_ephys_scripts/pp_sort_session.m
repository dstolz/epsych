function Spikes = pp_sort_session( subject, session, Spikes )
% 
%  pp_sort_session( subject, session) 
%    Loads Phys struct to run data through UMS spike sorting algorithm, and
%    creates the main output Spikes.clustered, which contains all relevant 
%    sorting info and results from UMS. Note: Spikes.sorted is created, by
%    replicating Spikes.clustered, and this will be where manual sorts are
%    stored. Spikes.man_sort is a vector of 0/1 for each channel, to be
%    used as a flag for which channels have been manually sorted. 
%
%    2 functions called:
%     - [thresh, reject] = calculate_thresholds(Phys)
%           Prompts user to select clean trials, for calculating thresholds
%           based on std for each channel.
%     - spks = pp_sort_channel
%           Currently, called individually for each channel. This script
%           is the one that calls the UMS functions to run the sorting. 
%    
%    Saves data files:
%     SUBJECT_sess-XX_Spikes.mat
%    
%    pp_sort_session( ..., Spikes )  load a Spikes struct into the
%    workspace and include as an input argument in order to begin sorting
%    from a later channel. 
%

tic

global fs

includePath='/Users/kpenikis/Documents/MATLAB/ums2k_02_23_2012';
addpath(genpath(includePath));


% Load data structures

datadir  = '/Users/kpenikis/Documents/SanesLab/Data/processed_data';
fprintf('\nloading data...\n')
filename = sprintf('%s_sess-%s_Phys',subject,session);
load(fullfile(datadir,subject,filename));
filename = sprintf('%s_sess-%s_Info',subject,session);
load(fullfile(datadir,subject,filename));
fs = Info.fs;

savedir  = '/Users/kpenikis/Documents/SanesLab/Data/processed_data';



% Determine channel to begin sorting
if nargin>2
    start_channel = max(Spikes.channel)+1;
else
    start_channel = 1;
    Spikes = struct();
end


% Launch GUI to manually select clean data segments and set thresholds

segment_length_s = diff(Info.t_win_ms)/1000;  %length of each data segment (sec)

[thresh, reject] = calculate_thresholds(Phys, segment_length_s);


% Sort each channel, individually for now, and fill Spikes struct

n_channels = size(Phys,3);

for ich = start_channel:n_channels
    if ich==8, 
        Spikes.channel(ich) = ich;
        continue
    end
    
    data = Phys(:,:,ich);
    fprintf('sorting ch %i... ',ich)
    
    spks = pp_sort_channel(data, thresh(ich), reject(ich));
    
    Spikes.channel(ich)   = ich;
    Spikes.man_sort(ich)  = 0;
    Spikes.clustered(ich) = spks;
    
    clear spks
    
    % save data after each channel
    savename = sprintf('%s_sess-%s_Spikes',subject,session);
    save(fullfile(savedir,subject,savename),'Spikes','-v7.3');
    
end

% Replicate the raw sorted data, where the final clus will be saved after
% manual sorting.
Spikes.sorted = Spikes.clustered;



% SAVE DATA 

% Save completed Spikes file
fprintf('\nsaving data...\n')
savename = sprintf('%s_sess-%s_Spikes',subject,session);
save(fullfile(savedir,subject,savename),'Spikes','-v7.3');



%
fprintf('\n**Finished sorting and saving data for this session.\n')
fprintf('------------------------------------------------------------\n')

toc




end