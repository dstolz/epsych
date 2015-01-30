%% Tetrode Spike detection from raw signal procedure:
%   1. Retrieve raw stream data from specied blocks of a tank
%   2. Filter (700 - 8000 Hz) for spike signal
%   3. Make each tank 'block' a 'trial' using ULTRAMEGASORT2000 software
%       https://physics.ucsd.edu/neurophysics/lab/UltraMegaSort2000%20Manual.pdf
%   

addpath('C:\MATLAB\work\Plugins\ums2k_02_23_2012');

%% Parametmers

datadir = 'D:\DataProcessing\JULIA';
sevevnt = 'Strm';

trodes = {1:4; 5:8};


% read from excel sheet
blocksheet = 'D:\DataProcessing\JULIA\JULIA_TankMap.xlsx';
% blocksheet = 'D:\DataProcessing\JULIA\JULIA_TankMap2.xlsx';
% blocksheet = 'D:\DataProcessing\JULIA\JULIA_TankMap2B.xlsx';
% blocksheet = 'D:\DataProcessing\JULIA\JULIA_TankMapv3.xlsx';
% blocksheet = 'D:\DataProcessing\JULIA\JULIA_TankMapTEST.xlsx';

Fs = 24414.0625;

thresh = 5.0;

RUN_ALGORITHM = false;

%% Read Excel file
% Excel file should be formatted as:
%   Column A - Site ID; Column B - Tank; Column C - Blocks Vector
%   First row is used as column names and is ignored

fprintf('Reading data from Excel sheet ''%s'' ...',blocksheet)
[~,~,raw] = xlsread(blocksheet);
fprintf(' done\n')

raw(1,:) = []; % remove header
sites  = raw(:,1);
[usites,i] = unique(sites);
tanks = raw(i,2);
rblocks = cellfun(@str2num,raw(:,3),'uniformoutput',false);
blocks = cell(size(usites));
for i = 1:length(usites)
    ind = ismember(sites,usites(i));
    
    idx = find(ind);
    
    b = [];
    for j = 1:length(idx)
        b = [b, rblocks{idx(j)}];
    end
    blocks{i} = b;
end



%% Design filters

% filter for spikes
Wp = [ 700  8000] * 2 / Fs;
Ws = [ 500 10000] * 2 / Fs;
[N,Wn] = buttord( Wp, Ws, 3, 20);
[Bspikes,Aspikes] = butter(N,Wn);

% filter for LFPs
NewFs = 2000; % Hz
Fsdenom = round(Fs/NewFs);
NewFs = Fs/Fsdenom;
Wp = [     1 250] * 2 / NewFs;
Ws = [2^-0.5 500] * 2 / NewFs;
[N,Wn] = buttord( Wp, Ws, 3, 20);
[Blfp,Alfp] = butter(N,Wn);


%%
if ~isdir([datadir,'\DETECTED\']), mkdir([datadir,'\DETECTED\']); end
% if ~isdir([datadir,'\LFP\']), mkdir([datadir,'\LFP\']); end

%% use parallel processing to speed things up
if matlabpool('size') == 0, matlabpool local 8; end

%% Run
start_time = clock;
for s = 1:length(usites)
    tank = tanks{s};
    nblocks = length(blocks{s});
       
    data = double([]);
    clear S
    for t = 1:length(trodes)
        S{t} = ss_default_params(Fs,'thresh',thresh,'refractory_period',2.0, ...
            'window_size',1.25); %#ok<SAGROW>
    end
    
%     LFP = cell(nblocks,1);
    for i = 1:nblocks
        fprintf('\nProcessing Tank ''%s'', Block-%d (%d of %d)\n',tank,blocks{s}(i),i,nblocks)
        fprintf('\tRetrieving data from tank ...')
        sevdir = sprintf('%s%c%s%cBlock-%d%c',datadir,filesep,tank,filesep,blocks{s}(i),filesep);
        
        
        %% Retrieve Streamed Data
        SEV = TDT_SEV2mat(sevdir,sevevnt);
        
        strm = double(SEV.(sevevnt).data);
        Fs   = SEV.(sevevnt).fs;
        
        clear SEV
        
        fprintf(' done\n')
        
        %% Filter for Spike signal
        fprintf('\tFiltering ...')
        clear data
        data = zeros(1,size(strm,2),size(strm,1));
        parfor j = 1:size(strm,1)
            data(1,:,j) = filtfilt(Bspikes, Aspikes, strm(j,:)); % each block is a 'trial'
%             r = decimate(strm(j,:),Fsdenom);
%             LFP{i}(:,:,j) = filtfilt(Blfp, Alfp, r); % filter for LFPs
%             fprintf('.')
        end
        clear strm
        
        fprintf(' done\n')        
                
        for t = 1:length(trodes)
            fprintf('\tDetecting spikes on trode %d of %d (Ch: %s)\n\t\t',t,length(trodes),num2str(trodes{t}))
            S{t} = ss_NEOdetect(data(1,:,trodes{t}),S{t}); %#ok<SAGROW>
        end
        
        clear data
    end
    
%     %% Save LFP data
%     fprintf('\tSaving LFP data ...')
%     save(fullfile(datadir,'LFP\',sprintf('%s_LFP.mat',usites{s})),'LFP');
%     fprintf(' done\n')
%     clear LFP
    

    
    %% Save spikes structure
    for t = 1:length(S)
        try
            fprintf('\tAligning spikes ...')
            spikes = ss_align(S{t});    fprintf(' done\n');
            
            fprintf('\tSaving spikes structure ...')
            save(fullfile(datadir,'DETECTED\',sprintf('%s_trode_%d.mat',usites{s},t)),'spikes','-v7.3');
            fprintf(' done\n')
            % reset threshold
            thresh = 5.0;
        catch me
            if isequal(me.identifier,'MATLAB:nomem')
                i = i-1;
                thresh = thresh + 0.5;
                fprintf(['Encountered ''Out of Memory'' error during alignment process.  ', ...
                    'Retrying spike detection with higher threshold (thresh = %0.1f)\n'],thresh)
                
                break
            else
                rethrow(me);
            end
        end
        clear spikes
    end
    
    clear S
end
fprintf('\nCompleted pre-processing of %d unique sites (total %d blocks) %s\n', ...
    length(usites),numel(cell2mat(blocks')),datestr(now))
fprintf('\tTotal time: %0.2f hours\n',etime(clock,start_time)/3600)

%%
if matlabpool('size') > 0, matlabpool close force local;    end


%%
SCRATCH_BatchKlustKwik;

%%


return


%% Spike sorting using UltraMegaSort2000 GUI
load(fullfile(datadir,'JULIA_3_1_trode_1.mat'));
whos UMSspikes

% main tool
splitmerge_tool(UMSspikes)


%% Batch KlustaKwik processing script
edit SCRATCH_BatchKlustKwik.m

%% Use MClust with the UMSLoadingEngine

MClust


%% Other UltraMegaSort2000 utilities
% stand alone outlier tool
outlier_tool(UMSspikes)

%
% Note: In the code below, "clus", "clus1", "clus2", and "clus_list" are dummy
% variables.  The user should fill in these vlaues with cluster IDs found
% in the SPIKES object after running the algorithm above.
%

% plots for single clusters
plot_waveforms( UMSspikes, clus );
plot_stability( UMSspikes, clus);
plot_residuals( UMSspikes,clus);
plot_isi( UMSspikes, clus );
plot_detection_criterion( UMSspikes, clus );

% comparison plots
plot_fld( UMSspikes,clus1,clus2);
plot_xcorr( UMSspikes, clus1, clus2 );

% whole data plots
plot_features(UMSspikes );
plot_aggtree(UMSspikes);
show_clusters(UMSspikes, [clus_list]);
compare_clusters(UMSspikes, [clus_list]);

% outlier manipulation (see M-files for description on how to use)
UMSspikes = remove_outliers( UMSspikes, which );
UMSspikes = reintegrate_outliers( UMSspikes, indices, mini );

% quality metric functions
%
% Note: There are versions of these functions in the quality_measures
% directory that have an interface that does not depend on the SPIKES
% structure.  These are for use by people who only want to use the quality
% metrics but do not want to use the rest of the package for sorting.
% These functions have the same names as below but without the "ss_" prefix.
%
FN1 = ss_censored( UMSspikes, clus1 );
FP1 = ss_rpv_contamination( UMSspikes, clus1  );
FN2 = ss_undetected(UMSspikes,clus1);
confusion_matrix = ss_gaussian_overlap( UMSspikes, clus1, clus2 ); % call for every pair of clusters

