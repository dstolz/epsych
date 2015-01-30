%% Parametmers

datadir = 'D:\DataProcessing\JULIA';
sevevnt = 'Strm';

trodes = {1:4; 5:8};


% read from excel sheet
blocksheet = 'D:\DataProcessing\JULIA\JULIA_TankMap.xlsx'; % tank/phase
% blocksheet = 'D:\DataProcessing\JULIA\JULIA_TankMap2.xlsx'; % complete tank (too big)

Fs = 24414.0625;

%% Read Excel file
% Excel file should be formatted as:
%   Column A - Site ID; Column B - Tank; Column C - Blocks Vector
%   First row is used as column names and is ignored

fprintf('Reading data from Excel sheet ''%s'' ...',blocksheet)
[~,~,raw] = xlsread(blocksheet);
fprintf(' done\n')

raw(1,:) = []; % remove header
sites  = raw(:,1);
tanks  = raw(:,2);
blocks = cellfun(@str2num,raw(:,3),'UniformOutput',false);


if ~isdir([datadir,'\DDT\']), mkdir([datadir,'\DDT\']); end

%% Design filters

% filter for spikes
Wp = [ 700  8000] * 2 / Fs;
Ws = [ 500 10000] * 2 / Fs;
[N,Wn] = buttord( Wp, Ws, 3, 20);
[Bspikes,Aspikes] = butter(N,Wn);
% 
% % filter for LFPs
% NewFs = 2000; % Hz
% Fsdenom = round(Fs/NewFs);
% NewFs = Fs/Fsdenom;
% Wp = [     1 250] * 2 / NewFs;
% Ws = [2^-0.5 500] * 2 / NewFs;
% [N,Wn] = buttord( Wp, Ws, 3, 20);
% [Blfp,Alfp] = butter(N,Wn);

%% use parallel processing to speed up filtering multichannel data
if matlabpool('size') == 0, matlabpool local 8; end


%% Run
start_time = clock;
for s = 1:length(sites)
    tank = tanks{s};
    nblocks = length(blocks{s});
    
    data = [];
    for i = 1:nblocks
        fprintf('Processing Streamed Data from Tank ''%s'', Block-%d (%d of %d) ...',tank,blocks{s}(i),i,nblocks)
        sevdir = sprintf('%s%c%s%cBlock-%d%c',datadir,filesep,tank,filesep,blocks{s}(i),filesep);
        
        
        %% Retrieve Streamed Data
        SEV = TDT_SEV2mat(sevdir,sevevnt);
        
        
        %% Filter for Spike signal
        D = double(SEV.(sevevnt).data)'; % single -> double
        clear SEV
        fdata = zeros(size(D,1),size(D,2));
        parfor j = 1:size(D,2)
            fdata(:,j) = filtfilt(Bspikes, Aspikes, D(:,j)); % each block is a 'trial'
        end
        clear D
        data(end+1:end+size(fdata,1),:) = single(fdata); % double -> single
        clear fdata
        
        % insert one second of zeros to separate blocks
        if i ~= nblocks
            data(end+1:end+fix(Fs),:) = 0;
        end
        
        fprintf(' done\n')
        
        
    end
    
    [npoints,nch] = size(data);
    
    data = 1000*data'./(0.5*2^16);
    
    gain = 1;
    
    filename = fullfile(datadir,'DDT\',sprintf('%s.ddt',sites{s}));
    
    % write ddt file for Plexon
    fprintf('Writing to file: %s ...',filename)
    [errCode] = ddt_write_v(filename, nch, npoints, Fs, data);
    fprintf(' done\n')
    
    clear data
end

%%
if matlabpool('size') > 0, matlabpool close force local;    end

%%
fprintf('\nCompleted pre-processing of %d unique sites (total %d blocks) %s\n', ...
    length(sites),numel(cell2mat(blocks')),datestr(now))
fprintf('\tTotal time: %0.2f minutes\n',etime(clock,start_time)/60)

