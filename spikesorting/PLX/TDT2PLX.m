function TDT2PLX(tank,blocks,varargin)
% TDT2PLX(TANK,BLOCKS)
% TDT2PLX(...,parameter,'value',..)
%
%   TANK is a string (char) to the absolute path to the tank or the name of
%   a registered tank.
%
%   BLOCKS is a cell array of block names.  All blocks from the specified
%   tank will be selected if left empty (default).
%
% IMPORTANT NOTE: When sorting spike waveforms using Plexon Offline Sorter,
% ensure the option to "Export Invalidated Units" is enabled.
%
%   parameter       default value
%   ---------       -------------
%   PLXDIR          (tank dir)      % Directory to save PLX files
%   SERVER          'Local';        % Tank server
%   EVENT           (depends)       % Event name.  If not specified, then
%                                     the default event will be the first
%                                     snip type event.
%   CHANNELS        []              % Use a subset of channels specified by
%                                     an array of channels. If empty, use
%                                     all channels with spikes.
%   SCALE           5.5e6           % Rescale spike waveforms for
%                                     OfflineSorter
% 
% See also, PLX2TDT
%
% DJS 2013
%
% Daniel.Stolzberg@gmail.com


% defaults are modifiable using varargin parameter, value pairs
PLXDIR        = [];
SERVER        = 'Local';
EVENT         = [];
CHANNELS      = [];
SCALE         = 5.5e6;

if isempty(blocks)
    blocks = TDT2mat(tank); % returns all blocks from tank
end

% parse varargin
for i = 1:2:length(varargin)
    eval([upper(varargin{i}) '=varargin{i+1};']);
end




% write plx file
for i = 1:length(blocks)
    fprintf('Retrieving "%s" (%d of %d) ...',blocks{i},i,length(blocks))
    
    d = TDT2mat(tank,blocks{i},'server',SERVER,'silent',true,'type',3);
    if isempty(EVENT) || isempty(d.snips)
        if isempty(d.snips)
            fprintf(' No spiking events found in "%s"\n',blocks{i})
            continue
        end
        EVENT = fieldnames(d.snips);
        EVENT = EVENT{1};
    end
    
    if isempty(PLXDIR)
        PLXDIR = d.info.tankpath;
    end
    
    d = d.snips.(EVENT);
    
    d.data = d.data * SCALE; % scale for Plexon
    
    channels = unique(d.chan);
    if ~isempty(CHANNELS)
        channels = CHANNELS(ismember(CHANNELS,channels));
    end
    
    if i == 1
        ts   = cell(512,1);
        wave = cell(512,1);
        sort = cell(512,1);
        k = zeros(512,1);
    else
        ind = cellfun(@isempty,ts);
        k(~ind) = cellfun(@(x) x(end),ts(~ind));
    end
    
    for ch = channels
        ind = d.chan == ch;
        n = sum(ind);
        if ~n, continue; end
        ts{ch}(end+1:end+n)     = d.ts(ind) + k(ch);
        wave{ch}(end+1:end+n,:) = d.data(ind,:);
%         sort{ch}(end+1:end+n)   = d.sort(ind);
        sort{ch}(end+1:end+n)   = zeros(1,sum(ind)); % ignore any previous sorting
    end
        
    fs  = d.fs;
    npw = size(d.data,2);
    
    clear d
    fprintf(' done\n')
end

maxts = max(cell2mat(ts'));

emptychs = cellfun(@isempty,ts);
ts(emptychs)   = [];
wave(emptychs) = [];
sort(emptychs) = [];
validchs = find(~emptychs)';

% get block ids for file name
bids = cellfun(@(x) str2num(x(find(x=='-',1,'last')+1:end)),blocks); %#ok<ST2NM>
bstr = sprintf('%d_',bids); bstr(end) = [];
plxfilename = sprintf('%s_blocks_%s.plx',tank,bstr);
fprintf('Writing headers for "%s"\n',plxfilename)
plxfilename = fullfile(PLXDIR,plxfilename);
fid = writeplxfilehdr(plxfilename,fs,length(validchs),npw,maxts);
for ch = validchs
    writeplxchannelhdr(fid,ch,npw)
end
for i = 1:length(validchs)
    fprintf('Writing channel% 3d\t# spikes:% 7d\n',validchs(i),length(ts{i}))
    writeplxdata(fid,validchs(i),fs,ts{i},sort{i},npw,wave{i})
end

fclose(fid);





