function PLX2TDT(plxfilename,varargin)
% PLX2TDT(plxfilename)
% PLX2TDT(plxfilename,'Parameter','Value',...)
% 
% Convert plx file generated from sorting data with Plexon Offline Sorter
% and update appropriate TDT tank.
%
% Tank must be registered.
% 
%   parameter         default value
%   SERVER              'Local'                 TDT server
%   BLOCKROOT           'Block'                 TDT Block root name
%   SORTNAME            'Pooled'                TDT Sort name
%   SORTCONDITION       'PlexonOSv2'            TDT Sort condition
%   EVENT               (depends)               If not specified, then the
%                                               event will be automatically
%                                               chosen from tank.
%   CHANNELS            all channels
% 
% See also, TDT2PLX
%
% DJS 2013
%
% Daniel.Stolzberg at gmail dot com

% defaults are modifiable using varargin parameter, value pairs
SERVER        = 'Local';
BLOCKROOT     = 'Block';
SORTNAME      = 'Pooled';
SORTCONDITION = 'PlexonOSv2';
EVENT         = [];
CHANNELS      = [];

ParseVarargin({'SERVER','BLOCKROOT','SORTNAME','SORTCONDITION','EVENT','CHANNELS'},[],varargin);

% load and reconfigure plexon data
[tscounts, ~, ~, ~] = plx_info(plxfilename,1);

tscounts(:,1) = []; % remove empty channel

[npossunits,nchans] = size(tscounts);

if isempty(CHANNELS)
    CHANNELS = 1:nchans;
else
    nchans = length(CHANNELS);
end

n    = zeros(size(tscounts,1),nchans);
ts   = cell(1,nchans);
unit = cell(1,nchans);
for i = 1:nchans
    fprintf('\n\tChannel %d\n',CHANNELS(i))
    for j = 1:npossunits
        if ~tscounts(j,CHANNELS(i)), continue; end
%         [n(j,i),~,t,~] = plx_waves(plxfilename,CHANNELS(i),j-1);
        [n(j,i),t] = plx_ts(plxfilename,CHANNELS(i),j-1);
        fprintf('\t\tunit %d\t# spikes:% 8d\n',j-1,n(j,i))
        
        ts{i}   = [ts{i}; t];
        unit{i} = [unit{i}; ones(n(j,i),1) * (j-1)];       
    end
    
    [ts{i},sidx] = sort(ts{i});
    unit{i}      = unit{i}(sidx);
end



% parse plxfilename for tank and block info
[~,filename,~] = fileparts(plxfilename);
k = strfind(filename,'blocks');
tank = filename(1:k-2);
bstr = filename(k+6:end);
c = textscan(bstr,'_%d');
blocks = cell2mat(c)';




% establish connection tank
TTXfig = figure('Visible','off','HandleVisibility','off');
TTX = actxcontrol('TTank.X','Parent',TTXfig);

if ~TTX.ConnectServer(SERVER, 'Me')
    error(['Problem connecting to Tank server: ' SERVER])
end

if ~TTX.OpenTank(tank, 'W')
    CloseUp(TTX,TTXfig);
    error(['Problem opening tank: ' tank]);
end



% update Tank with new Plexon sort codes
for b = blocks
    blockname = [BLOCKROOT '-' num2str(b)];
    if ~TTX.SelectBlock(blockname)
        CloseUp(TTX,TTXfig)
        error('Unable to select block ''%s''',blockname)
    end

    d = TDT2mat(tank,blockname,'type',3,'silent',true);
    
    if isempty(EVENT)
        if isempty(d.snips)
            warning('No spiking events found in "%s"',blocks{i})
            continue
        end
        EVENT = fieldnames(d.snips);
        EVENT = EVENT{1};
    end

    d = d.snips.(EVENT);
    
    fprintf('Updating sort "%s" on %s of %s\n',SORTNAME,blockname,tank)
    
    for c = 1:length(CHANNELS)
        ind = d.chan == CHANNELS(c);
        k = sum(ind);
        
        fprintf('\tChannel %d,\t%d units with% 8d spikes ...', ...
            CHANNELS(c),length(unique(unit{c}(1:k))),k)
        
        if k == 0, fprintf(' NO SPIKES\n'); continue; end
        
        SCA = uint32([d.index(ind); unit{c}(1:k)']);
        SCA = SCA(:)';
        
        success = TTX.SaveSortCodes(SORTNAME,EVENT,CHANNELS(c),SORTCONDITION,SCA);
        
        if success
            fprintf(' SUCCESS\n')
        else
            fprintf(' FAILED\n')
        end
        
        d.index(ind) = [];
        d.chan(ind)  = [];
        unit{c}(1:k) = [];
        
    end
end

CloseUp(TTX,TTXfig)

clear mexPlex



function CloseUp(TTX,TTXfig)
TTX.CloseTank;
TTX.ReleaseServer;
close(TTXfig);






