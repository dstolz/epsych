%% Parametmers

datadir = 'D:\DataProcessing\JULIA\TANKS';
% datadir = 'D:\DataProcessing\DELORES';
sevevnt = 'Strm';

% trodes = {1:4; 5:8; 9:12};


% read from excel sheet
blocksheet = 'D:\DataProcessing\JULIA\JULIA_TankMap.xlsx'; % tank/phase
% blocksheet = 'D:\DataProcessing\JULIA\JULIA_TankMapTEST.xlsx'; % complete tank (too big)
% blocksheet = 'D:\DataProcessing\DELORES\DELORES_TankMap2.xlsx'; % tank/phase

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
Wp = [ 700  5000] * 2 / Fs;
Ws = [ 500  9000] * 2 / Fs;
% Ws = [ 500 10000] * 2 / Fs;
[N,Wn] = buttord( Wp, Ws, 3, 20);
[Bspikes,Aspikes] = butter(N,Wn);
% 


%% use parallel processing to speed up filtering multichannel data
if matlabpool('size') == 0, matlabpool local 6; end


%% Run
start_time = clock;
for s = 1:length(sites)
    tank = tanks{s};
    nblocks = length(blocks{s});
    
    data = single([]);
    for i = 1:nblocks
        fprintf('Processing Streamed Data from Tank ''%s'', Block-%d (%d of %d) ...',tank,blocks{s}(i),i,nblocks)
        sevdir = sprintf('%s%c%s%cBlock-%d%c',datadir,filesep,tank,filesep,blocks{s}(i),filesep);
        
        
        %% Retrieve Streamed Data
        SEV = TDT_SEV2mat(sevdir,sevevnt);
        
        
        %% Filter for Spike signal
        D = SEV.(sevevnt).data';
        clear SEV
        parfor j = 1:size(D,2)
            D(:,j) = single(filtfilt(Bspikes, Aspikes, double(D(:,j)))); % each block is a 'trial'
        end
        data(end+1:end+size(D,1),:) = D;
        clear D
        
%         tdtdata = TDT2mat(tank,sprintf('Block-%d',blocks{s}(i)),'type',2);
        
        
        % insert one second of zeros to separate blocks
        if i ~= nblocks
            data(end+1:end+floor(Fs),:) = 0;
        end
        
        fprintf(' done\n')
        
        
    end
    
    [npoints,nch] = size(data);
    
%     data = 1000*data'./(0.5*2^16); % scaling factor
    
    gain = 1;
    
    filename = fullfile(datadir,'DDT\',sprintf('%s.ddt',sites{s}));
    
    % write ddt file for Plexon
    fprintf('Writing to file: %s ...',filename)
    [errCode] = ddt_write_v(filename, nch, npoints, floor(Fs), double(data'));
    fprintf(' done\n')
    
    clear data
end

%%
if matlabpool('size') > 0, matlabpool close force local;    end

%%
fprintf('\nCompleted pre-processing of %d unique sites (total %d blocks) %s\n', ...
    length(sites),numel(cell2mat(blocks')),datestr(now))
fprintf('\tTotal time: %0.2f minutes\n',etime(clock,start_time)/60)

