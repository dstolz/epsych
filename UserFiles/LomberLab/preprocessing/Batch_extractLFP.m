%% Extract LFP signal
% Filter continuously sampled data for low-frequency LFPs and downsample
%
% Filter properties: Bandpass [1 200] Hz
% Downsample from raw data rate (~25 kHz) to ~1000 Hz
%
% DJS 5/2016


tank = 'D:\Data Tanks\CHRONIC_EPHYS_TANKS\HANSOLO_20160426';
blocks = TDT2mat(tank);

plxdir = 'D:\DataProcessing\HANSOLO\plxTEST\';
lfpdir = 'D:\DataProcessing\HANSOLO\lfpTEST\';

%%

if ~isdir(lfpdir), mkdir(lfpdir); end

[tankpath,tankname] = fileparts(tank);

for b = blocks
    fprintf('Processing ''%s''\n',char(b))
    
%     plxname = sprintf('%s_%s_*.plx',tankname,char(b)); % assuming created with offlineSpikeDetect
    plxname = sprintf('%s_%s.plx',tankname,char(b)); % assuming created with offlineSpikeDetect
    plx = dir([plxdir plxname]);
    
    if isempty(plx)
        fprintf(2,'Plexon file not found... skipping block\n')
        continue
    end
    
    plxfile = fullfile(plxdir,plx.name);
    fprintf('Using PLX file for despiking\n\t%s\n',plxfile)
    [LFP,Fs] = offlineExtractLFP(tank,char(b),[],600,[],[],plxfile);
    
    % save LFP data
    [~,n,~] = fileparts(plx.name);
    lfpfilename = fullfile(lfpdir,[n '_LFP.mat']);
    
    fprintf('Saving LFP file: %s\n',lfpfilename)
    save(lfpfilename,'LFP','Fs');
end







