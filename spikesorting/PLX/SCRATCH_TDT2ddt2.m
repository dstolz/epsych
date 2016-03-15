%% Parametmers
%
% Set 'datadir' to the path where your tank(s) exist or your computer.  This is not the tank name, but the directory just above it.
%
% Set 'sevevnt' as the name of the streamed data macro that was set in your RPvds circuit.  It will be 4 characters long.
%
% 'trodes' is a cell array of electrode groupings (such as tetrodes).  Modify this for your purpose.  For example, if you have 8 individual electrodes, set trodes = {1, 2, 3, 4, 5, 6, 7, 8}.  Or you can use trodes = num2cell(1:8).
%
% You will need to create an Excel file that should be formatted as:
% Column A - Site ID; Column B - Tank; Column C - Blocks Vector
% Blocks vector allows you to analyze multiple blocks as if they were one big block.  If you want to combine blocks, set this vector to the block numbers, such as 1, 2, 3, 4.  Or just set to a single block
% Enter the full path to this file in the variable called 'blocksheet'.
% The first row in the Excel sheet is used as column names and is ignored
%
% You may need a lot of RAM to run this on large datasets.  The script also uses the Parallel Processing toolbox.  Comment out lines that give you trouble if you don't have this toolbox.
%
% Daniel.Stolzberg@gmail.com 2015

% datadir = 'D:\KingKong_Cloud\BIG_DATA\JULIA\TANKS';
datadir = 'D:\KingKong_Cloud\BIG_DATA\DELORES\TANKS';
sevevnt = 'Strm';

% trodes = {1:4};
% trodes = {1:4, 5:8};
trodes = {1:4, 5:8, 9:12};


% read from excel sheet
blocksheet = 'D:\KingKong_Cloud\BIG_DATA\DELORES\DELORES_TankMap_ALL2.xlsx';
% blocksheet = 'D:\KingKong_Cloud\BIG_DATA\JULIA\JULIA_TankMap.xlsx'; % tank/phase
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
[N,Wn] = buttord( Wp, Ws, 3, 20);
[Bspikes,Aspikes] = butter(N,Wn);
%


%% use parallel processing to speed up filtering multichannel data
if matlabpool('size') == 0, matlabpool local 8; end


%% Run
start_time = clock;
for s = 1:length(sites)
    tank = tanks{s};
    nblocks = length(blocks{s});
    
    
    
    for t = 1:length(trodes)
        data = single([]);

        for i = 1:nblocks
            sevdir = sprintf('%s%c%s%cBlock-%d%c',datadir,filesep,tank,filesep,blocks{s}(i),filesep);
            
            
            %% Retrieve Streamed Data
            SEV = TDT_SEV2mat(sevdir,sevevnt);
            
            fprintf('Processing Streamed Data from Tank ''%s'', Block-%d (%d of %d), Trode %d of %d ...', ...
                tank,blocks{s}(i),i,nblocks,t,length(trodes))
            
            
            D = SEV.Strm.data(trodes{t},:)';
            clear SEV
            
            % Filter for Spike signal
            parfor j = 1:size(D,2)
                D(:,j) = single(filtfilt(Bspikes, Aspikes, double(D(:,j)))); % each block is a 'trial'
            end
            data(end+1:end+size(D,1),:) = D;
            clear D
            
            % insert one second of zeros to separate blocks
            if i ~= nblocks
                data(end+1:end+floor(Fs),:) = 0;
            end
            
            
            
            fprintf(' done\n')
            
        end
        
        [npoints,nch] = size(data);
        
        gain = 1;
        
        filename = fullfile(datadir,'DDT\',sprintf('%s-Trode_%d.ddt',sites{s},t));
        
        % write ddt file for Plexon
        fprintf('Writing to file: %s ...',filename)
        [errCode] = ddt_write_v(filename, nch, npoints, floor(Fs), double(data'));
        fprintf(' done\n')
        
        clear data
    end
    
end

%%
if matlabpool('size') > 0, matlabpool close force local;    end

%%
fprintf('\nCompleted pre-processing of %d unique sites (total %d blocks) %s\n', ...
    length(sites),numel(cell2mat(blocks')),datestr(now))
fprintf('\tTotal time: %0.2f minutes\n',etime(clock,start_time)/60)

