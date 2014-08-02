function data = TDT2mat(tank, block, varargin)
%TDT2MAT  TDT tank data extraction.
%   blocks = TDT2mat(TANK)
%   data = TDT2mat(TANK, BLOCK) 
%   data = TDT2mat(TANK, BLOCK,'parameter',value,...) 
%  
%   If the TANK name is the only input then a list of blocks will be
%   returned in a cell array.
%
%   Where TANK and BLOCK are strings, retrieve all data from specified
%   block in struct format.
%
%   data.epocs      contains all epoc store data (onsets, offsets, values)
%   data.snips      contains all snippet store data (timestamps, channels,
%                   and raw data)
%   data.streams    contains all continuous data (sampling rate and raw
%                   data)
%   data.info       contains some additional information about the block
%
%   "parameter", value pairs...
%       "server"    data tank server (default = "Local")
%       "T1" is a scalar, retrieve data starting at T1 (0 for start at
%           beginning of recording).
%       "T2" is a scalar, retrieve data ending at T2 (0 for end at ending
%           of recording).
%       "CHANNELS" limit channels returned. Set to 0 for all channels (default is 0)
%       "SORTNAME" is the sorted spikes to be returned. (default is online
%       sorted spikes).
%       "SILENT" a summary of tank data will be
%           returned if false (default).
%       "TYPE" specifies to return all or subset of datatypes
%                   ex: data = TDT2mat("MyTank","Block-1","TYPE",[2 3]);
%                           > returns epocs and snips data
%           1   ...   all (default)
%           2   ...   epocs
%           3   ...   snips
%           4   ...   streams
% 
%       "NAME" limits returned stream or snip data to a specific named
%       event.  This is useful in the case where multiple stream or snip
%       events exist in the tank.
%       
%
% Built by TDT, modified by DJS 5/2013

data = struct('epocs',[],'snips',[],'streams',[],'info',[]);

% defaults
T1       = 0;
T2       = 0;
SILENT   = 0;
CHANNELS = 0;
TYPE     = 1;
SORTNAME = 'TankSort';
SERVER   = 'Local';
NAME     = [];

% parse varargin
for i = 1:2:length(varargin)
    eval([upper(varargin{i}) '=varargin{i+1};']);
end

if TYPE == 1, TYPE = 1:4; end

TTXfig = figure('Visible','off','HandleVisibility','off');
TTX = actxcontrol('TTank.X','Parent',TTXfig);


if TTX.ConnectServer(SERVER, 'Me') ~= 1
    error(['Problem connecting to Tank server: ' SERVER])
end

if TTX.OpenTank(tank, 'R') ~= 1
    CloseUp(TTX,TTXfig);
    error(['Problem opening tank: ' tank]);
end

block_start_time = [];
blocks{1} = TTX.QueryBlockName(0);
i = 1;
while strcmp(blocks{i}, '') == 0
    i = i+1;
    b = TTX.QueryBlockName(i); 
    if isempty(b), break; end
    blocks{i} = b; %#ok<AGROW>
    TTX.SelectBlock(blocks{i});
    block_start_time(i) = TTX.CurBlockStartTime; %#ok<AGROW>
end


% make sure blocks are in chronological order
if ~isempty(block_start_time)
    [~,i] = sort(block_start_time);
    blocks = blocks(i);
end

if nargin == 1 || isempty(block)
    if isempty(blocks{1}), blocks = []; end
    data = blocks;
    CloseUp(TTX,TTXfig);
    return
end

if TTX.SelectBlock(['~' block]) ~= 1
    CloseUp(TTX,TTXfig);
    if ismember(block, blocks)
        error(['Block found, but problem selecting it: %s\n', ...
            'Try again and if problem persists, the block may be corrupted'],block);
    end
    error(['Block not found: ' block]);
end

TTX.SetGlobalV('WavesMemLimit',1e9);
TTX.SetGlobalV('MaxReturn',1e7);
TTX.SetGlobalV('Channel',CHANNELS);
TTX.SetGlobalV('T1', T1);
TTX.SetGlobalV('T2', T2);

lStores = TTX.GetEventCodes(0);
for i = 1:length(lStores)
    name = TTX.CodeToString(lStores(i));
    if ~SILENT, fprintf('Store Name:\t%s\n', name); end
    
    TTX.GetCodeSpecs(lStores(i));
    type = TTX.EvTypeToString(TTX.EvType);
    if ~SILENT, fprintf('\t>EvType:     \t%s\n', type); end
    
    if bitand(TTX.EvType, 33025) == 33025 % catch RS4 header (33073)
        type = 'Stream';
    end
    
    switch type
        case 'Strobe+'
            if ~any(TYPE==2), continue; end
            d = TTX.GetEpocsV(name, T1, T2, 1e6)';
            data.epocs.(name).data  = d(:,1);
            data.epocs.(name).onset = d(:,2);
            if d(:,3) == zeros(size(d(:,3)))
                d(:,3) = [d(2:end,2); inf];
            end
            data.epocs.(name).offset = d(:,3);
            
        case 'Scalar'
            if ~any(TYPE==2), continue; end
            N = TTX.ReadEventsSimple(name);
            data.epocs.(name).data  = TTX.ParseEvV(0, N);
            data.epocs.(name).onset = TTX.ParseEvInfoV(0, N, 6);
            
        case 'Stream'
            if (any(TYPE==4) && isempty(NAME)) || (~isempty(NAME) && strcmp(name,NAME))
                data.streams.(name).data = TTX.ReadWavesV(name);
                num_channels = size(data.streams.(name).data,2);
            else
                TTX.SetGlobalV('T1', 0);
                TTX.SetGlobalV('T2', 1);
                t = TTX.ReadWavesV(name);
                TTX.SetGlobalV('T1', T1);
                TTX.SetGlobalV('T2', T2);
                num_channels = size(t,2);
            end
            if ~SILENT, fprintf('\t>N channels: \t%d\n', num_channels);  end
            data.streams.(name).chan = 1:num_channels;
            data.streams.(name).fs = TTX.EvSampFreq;
            if ~SILENT, fprintf('\t>Data Size:  \t%d\n',TTX.EvDataSize); end
            if ~SILENT, fprintf('\t>Samp Rate:  \t%f\n',TTX.EvSampFreq); end
            
        case 'Snip'
            if (any(TYPE==3) && isempty(NAME)) || (~isempty(NAME) && strcmp(name,NAME))
                data.snips.(name) = struct('data',[],'chan',[],'sort',[],'ts',[],'index',[]);
                TTX.SetUseSortName(SORTNAME);
                data.snips.(name).sortname = SORTNAME;
                t = 0:100:1e4;
                for k = 1:length(t)-1;
                    N = TTX.ReadEventsV(1e6, name, 0, 0, t(k), t(k+1), 'ALL');
                    if ~N, continue; end
                    data.snips.(name).data(end+1:end+N,:) = TTX.ParseEvV(0, N)';
                    data.snips.(name).chan(end+1:end+N)   = TTX.ParseEvInfoV(0, N, 4);
                    data.snips.(name).sort(end+1:end+N)   = TTX.ParseEvInfoV(0, N, 5);
                    data.snips.(name).ts(end+1:end+N)     = TTX.ParseEvInfoV(0, N, 6);
                    
                end
                for k = 1:length(t)-1;
                    N = TTX.ReadEventsV(1e6,name,0,0,t(k),t(k+1),'IDXPSQ');
                    if ~N, continue; end
                    data.snips.(name).index(end+1:end+N)  = TTX.GetEvTsqIdx;
                end
            else
                TTX.ReadEventsV(2^9, name, 0, 0, 0, 0, 'ALL');
            end
            s = 1;
            while 1
                sorts{s} = TTX.GetSortName(name, s-1); %#ok<AGROW>
                if isempty(sorts{s}), sorts{s} = 'TankSort'; break; end %#ok<AGROW>
                s = s + 1;
            end
            data.snips.(name).sorts = sorts;
            data.snips.(name).fs = TTX.EvSampFreq;
            if ~SILENT, fprintf('\t>Sort ID:    \t%s\n',SORTNAME);         end
            if ~SILENT, fprintf('\t>Data Size:  \t%d\n',TTX.EvDataSize); end
            if ~SILENT, fprintf('\t>Samp Rate:  \t%f\n',TTX.EvSampFreq); end
            
    end
    if ~SILENT, disp(' '); end
end

% get general block info
t1                  = TTX.CurBlockStartTime;
data.info.date      = TTX.FancyTime(t1,'Y-O-D');
data.info.begintime = TTX.FancyTime(t1,'H:M:S');
t2                  = TTX.CurBlockStopTime;
data.info.endtime   = TTX.FancyTime(t2,   'H:M:S');
data.info.duration  = TTX.FancyTime(t2-t1,'H:M:S');
data.info.blockname = block;
data.info.tankpath  = TTX.GetTankItem(tank,'PT');
data.info.legacy    = strcmp(TTX.GetTankItem(tank,'VERSION'),'10');

data = orderfields(data);

CloseUp(TTX,TTXfig)




function CloseUp(TTX,TTXfig)
TTX.CloseTank;
TTX.ReleaseServer;
close(TTXfig);

