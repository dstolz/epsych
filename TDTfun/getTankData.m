function varargout = getTankData(cfg)
% varargout = getTankData(cfg)
%
% cfg fields (default):  server    ('Local')
%                           - enumerated server as char string
%                        tank      (no default)
%                           - if tank is registered then only the tank name
%                           is required, otherwise the full path must be
%                           specified.
%                        blocks    ('all')
%                           - scalar or vector with block numbers, or 'all'
%                           as a char string
%                        blockroot ('Block-')
%                           - specifies a root for the tank blocks
%                        channel   ('all')
%                           - scalar or vector with channel numbers, or
%                           'all' as a char string
%                        datatype  ('BlockInfo')
%                           - char string indicating one of the following
%                           to be returned as the first output:
%                               'BlockInfo' - protocol information about
%                               each block of the tank as well as some
%                               general information
%                               'Spikes'    - returns spike times and
%                               spike waveforms
%                               'Waves'     - returns continuously sampled
%                               wave data
%                       event    ('Snip' if datatype is 'Spikes' or 'Wave'
%                                   if datatype is 'Waves')
%                           - char string of the event name
%                       sortname    (no default)
%                           - char string naming the sortname if using
%                           TDT OpenSorter.
%                       protocol    ('PROT')
%                           - parameter name from RPvds with an ID of the
%                           protocol or experiment type.
%                       downfs  (no default)
%                           - for downsampling continuous data.  Set this
%                           value to a target sampling rate.  If the actual
%                           sampling rate is greater than this value, the
%                           data will be downsampled to approximately this
%                           value.  The final sampling rate will be
%                           returned with the output structure.
%                       usemym (true)
%                           - indicates whether or not to use mym to look
%                           for protocol info on the database
%                       silently (false)
%                           - if true then data wil be retrieved without
%                           printing information to the command window
%                       TT
%                           - can be used to pass a reference to an
%                           a TTank ActiveX control object which already
%                           has an establisehd connectionn to the TTank
%                           server.  If not specified, then a temporary
%                           connection to the TTank server will be
%                           established.
%
% OUTPUT:   [data] = getTankData(cfg);
%                           - retrieves data of the type specified in
%                           cfg.datatype field.
%                           - the data output will be organized into a
%                           structured array of N blocks with a fields
%                           corresponding to the desired output data type.
%           [data,cfg] = getTankData(cfg);
%                           - returns cfg structure as well as data.
%
%  DJS (c) 2009


%% Set Defaults
if ~isfield(cfg,'tank') || ~ischar(cfg.tank)
    error('Tank must be specified as a char string');
end
if ~isfield(cfg,'server'),      cfg.server    = 'Local';        end
if ~isfield(cfg,'blockroot'),   cfg.blockroot = 'Block-';       end
if ~isfield(cfg,'blocks'),      cfg.blocks    = 'all';          end
if ~isfield(cfg,'channel'),     cfg.channel   = 'all';          end
if ~isfield(cfg,'datatype'),    cfg.datatype  = 'BlockInfo';    end
if ~isfield(cfg,'sortname'),    cfg.sortname  = [];             end
if ~isfield(cfg,'silently'),    cfg.silently  = false;          end
if ~isfield(cfg,'usemym'),      cfg.usemym    = true;           end
if ~isfield(cfg,'protocol'),    cfg.protocol  = 'PROT';         end
if isfield(cfg,'block'),        cfg.blocks    = cfg.block;      end % because I can never remember it's blocks and not block
if ~isfield(cfg,'event')
    if strcmpi(cfg.datatype,'Waves')
        cfg.event = 'Wave';
    else
        cfg.event = 'Snip';
    end
end

if ~any(strcmpi(cfg.datatype,{'Spikes','BlockInfo','Waves'}))
    error('''%s'' is an invalid datatype.',cfg.datatype);
end

%% Connect Tank
if ~isfield(cfg,'TT') || isempty(cfg.TT)
    TDTwindow = figure('Visible','off');
    TT = actxcontrol('TTank.X',[0 0 1 1],TDTwindow);
    EXTTT = false;
else
    TT = cfg.TT;
    EXTTT = true;
end
cfg.tank = strtrim(cfg.tank);
TT.ConnectServer(cfg.server,'Me');
TT.OpenTank(cfg.tank, 'R');
if ~cfg.silently, fprintf('\nLoading %s from Tank: ''%s''',cfg.datatype,cfg.tank); end

%% Retrieve Block List
if strcmpi(cfg.blocks,'all')
    
    blocklist{1} = [];
    bidx = 2;
    TT.QueryBlockName(0);   %initialize block query
    while ~strcmp(blocklist{bidx-1},'')
        blocklist{bidx} = TT.QueryBlockName(bidx-1); %#ok<AGROW>
        bidx = bidx + 1;
    end
    
    blocklist([1 end])   = [];    % erase first and last empties
    
    
    [~,id] = strtok(blocklist,'-');
    [~,id] = sort(str2num(char(id)),'descend'); %#ok<ST2NM>
    blocklist = blocklist(id);
    %     blocklist = sort(blocklist);
    
    cfg.blocks = 1:length(blocklist);
else
    if iscellstr(cfg.blocks)
        blocklist = cfg.blocks;
    elseif ischar(cfg.blocks)
        blocklist = {cfg.blocks};
    else
        for i = 1:length(cfg.blocks)
            blocklist{i} = [cfg.blockroot num2str(cfg.blocks(i))]; %#ok<AGROW>
        end
    end
end


for i = 1:nargout
    varargout{i} = []; %#ok<AGROW>
end

if isempty(blocklist)
    fprintf('  NO BLOCKS FOUND **\n');
    return
end
cfg.blocklist = blocklist;


TT.ResetGlobals;
TT.SetGlobalV('MaxReturn',5*10^8);

try
    [dataout,cfg] = feval(sprintf('get_%s',lower(cfg.datatype)),TT,cfg,blocklist);
catch ME
    if strcmp(ME.message,'Unable to select block: asdf10')
        warning('\n%s\n* Trying to use tank name as a block root *\n',ME.message)
        % well that didn't work.  maybe we can try using the tank name as the
        % block root.
        blocklist = cell(size(cfg.blocks));
        for i = 1:length(cfg.blocks)
            blocklist{i} = [cfg.tank '-' num2str(cfg.blocks(i))];
        end
        [dataout,cfg] = feval(sprintf('get_%s',lower(cfg.datatype)),TT,cfg,blocklist);
    else
        rethrow(ME)
    end
end


legacy   = str2num(TT.GetTankItem(cfg.tank,'VERSION')) == 10; %#ok<ST2NM>;
tankpath = TT.GetTankItem(cfg.tank,'PT');

for i = 1:length(dataout)
    dataout(i).legacy   = legacy;
    dataout(i).tankpath = tankpath;
    
    % it's also usefull to send out all sampling rates from across data types
    fn = fieldnames(dataout);
    fsamples = [];
    for j = 1:length(fn)
        if isfield(dataout(i).(fn{j}),'fsample')
            fsamples(end+1) = dataout(i).(fn{j}).fsample; %#ok<AGROW>
        end
    end
    dataout(i).allfsamples = unique(fsamples);
end




%% Close Connection
TT.CloseTank;
if ~EXTTT && nargout < 3
    TT.ReleaseServer;
    close(TDTwindow);
end

%% Handle Outputs
if nargout >= 1, varargout{1} = dataout;    end
if nargout >= 2, varargout{2} = cfg;        end
if nargout == 3, varargout{3} = TT;         end



function [dataout,cfg] = get_blockinfo(TT,cfg,blocklist) %#ok<DEFNU>
if ~cfg.silently, fprintf('\n'); end
for bidx = 1:length(cfg.blocks)
    DO.id   = cfg.blocks(bidx);
    DO.name = blocklist{bidx};
    DO.tank = cfg.tank;
    
    DO.Wave = [];
    DO.AWav = [];
    DO.Snip = [];
    DO.Strm = [];
    DO.eNeu = [];
    
    if ~cfg.silently, fprintf('Retrieving Block info %d of %d ... ',bidx,length(cfg.blocks)); end
    
    if ~TT.SelectBlock(blocklist{bidx})
        error(['Unable to select block: ', blocklist{bidx}]);
    end
    
    TT.CreateEpocIndexing;
        
    lStores = TT.GetEventCodes(0);
    for i = 1:length(lStores)
        TT.GetCodeSpecs(lStores(i));
        type = TT.EvTypeToString(TT.EvType);
        
        if ~any(ismember(type,{'Snip','Stream'})), continue; end
        
        name = TT.CodeToString(lStores(i));
        n = TT.ReadEventsV(10000,name,0,0,0,0,'NODATA');
        DO.(name).fsample = TT.EvSampFreq;
        DO.(name).type    = type;
        
        % make sure there is actually data on the channel
        c = unique(TT.ParseEvInfoV(0,n,4));
        k = 1;
        TT.SetGlobalV('T1',0);  TT.SetGlobalV('T2',1);
        for j = 1:length(c)
            TT.SetGlobalV('Channel',c(j));
            w = TT.ReadWavesV(name);
            if any(w)
                DO.(name).channels(k) = c(j);
                k = k + 1;
            end
        end
        TT.SetGlobalV('T1',0);  TT.SetGlobalV('T2',0);
    end
    
    % get general block info
    t1 = TT.CurBlockStartTime;
    DO.date      = TT.FancyTime(t1,'Y-O-D');
    DO.begintime = TT.FancyTime(t1,'H:M:S');
    t2 = TT.CurBlockStopTime;
    DO.endtime   = TT.FancyTime(t2,   'H:M:S');
    DO.duration  = TT.FancyTime(t2-t1,'H:M:S');
    
    
    
    % retrieve protocol ID #
    protocol = -1;
    n = TT.ReadEventsV(1,cfg.protocol,0,0,0,0,'NODATA');
    if n, protocol = TT.ParseEvV(0,1); end
    DO.protocol = protocol;
    
    DO.protocolname = 'UNKNOWN';
    
    if cfg.usemym
        try %#ok<TRYNC> % not critical to function
            % look on db_util.protocol_types table
            if ~myisopen, DB_Connect; end
            DO.protocolname = char(myms(sprintf('SELECT alias FROM db_util.protocol_types WHERE pid = %d',protocol)));
            if isempty(DO.protocolname)
                while 1
                    pstr = inputdlg({sprintf([ ...
                        'Protocol ID %d was not found on the database (db_util.protocol_types).\n\n', ...
                        'Enter an alias for the protocol (between 3 and 5 characters; eg. eFRA; required):'], protocol), ...
                        'Enter a more descriptive name (up to 50 characters; optional):', ...
                        'Enter a longer description if desired (up to 200 characters; optional):'}, ...
                        sprintf('Tank: %s, %s',DO.tank,DO.name), ...
                        [1 50; 1 50; 3 50]);
                    
                    if ~isempty(pstr) && (length(pstr{1}) < 3 || length(pstr{1}) > 5)
                        uiwait(errordlg('Protocol alias must be between 3 and 5 characters.  Try again, bozo!','getTankData','modal'));
                        
                    elseif ~isempty(pstr) && length(pstr{1}) <= 5
                        mym(['INSERT db_util.protocol_types (pid,alias,name,description) ', ...
                            'VALUES ({Si},"{S}","{S}","{S}")'],protocol,pstr{1},pstr{2},pstr{3})
                        fprintf('Added Protocol ID %d %s to the database (db_util.protocol_types)\n',protocol,pstr{1})
                        DO.protocolname = char(pstr{1});
                        break
                        
                    elseif isempty(pstr)
                        break
                    end
                end
            end
        end
    end
    
    
    
    TT.ResetFilters;
    
    % get Event names
    i = 1;
    while true
        DO.events{i} = TT.GetEpocCode(i-1);
        if isempty(DO.events{i})
            DO.events(i) = [];
            break
        end
        i = i + 1;
    end
    
    DO.epochs = [];
    DO.paramspec = {[]};
    
    % To get a list of param types use:
    %     mym('SELECT * FROM db_util.param_types')
    
    % generalized for any protocol
    DO.paramspec = DO.events(~ismember(DO.events,{'Tick','Tock','Swep','PROT'}));
    if isempty(DO.paramspec)
        dataout(bidx) = DO; %#ok<AGROW>
        clear DO;
        fprintf('* NO PARAMETERS FOUND *\n')
        continue
    end
    for i = 1:length(DO.paramspec)
        t = TT.GetEpocsV(DO.paramspec{i},0,0,10^6)';
        if i > 1 && size(t,1) ~= size(DO.epochs,1)
            error('Unequal number of events')
        end
        DO.epochs(:,i) = t(:,1);
    end
    DO.paramspec{end+1} = 'onset';
    DO.epochs(:,end+1)  = t(:,2); % append onset times
    
    dataout(bidx) = DO; %#ok<AGROW>
    clear DO
    
    if ~cfg.silently, fprintf('done\n'); end
end % bidx

function [DO,cfg] = get_spikes(TT,cfg,blocklist) %#ok<DEFNU>
TT.SetGlobalV('WavesMemLimit',10^8);

nblocks = length(blocklist);
for bidx = 1:nblocks
    TT.ResetFilters;
    if ~cfg.silently, fprintf('\nGrabbing %s from %s...', ...
            cfg.event,blocklist{bidx}); end
    
    if ~TT.SelectBlock(blocklist{bidx})
        error(['Unable to select block: ', blocklist{bidx}]);
    end
    
    TT.CreateEpocIndexing;
    
    if ~isfield(cfg,'channel') || isempty(cfg.channel) || strcmpi(cfg.channel,'all')
        n = TT.ReadEventsV(10^6,cfg.event,0,0,0,0,'NODATA');
        cfg.channel = unique(TT.ParseEvInfoV(0,n,4));
    end
        
    cfg.fsample(bidx) = TT.ParseEvInfoV(0,1,9);
    
    if ~isempty(cfg.sortname) && ~TT.SetUseSortName(cfg.sortname)
        error('The sortname ''%s'' was not found in block ''%s'' of tank ''%s''', ...
            cfg.sortname,cfg.tank,cfg.blocks{bidx});
    end
    
    k = 0;
    for cidx = cfg.channel
        k = k + 1;
        if ~cfg.silently, fprintf('\n\tChannel: %d\t(%d of %d) ',cidx,k,length(cfg.channel)); end
        
        % GRAB SPIKES FROM BLOCKS
        nSnips = TT.ReadEventsV(10^6,cfg.event,cidx,0,0,0,'ALL');
        if ~cfg.silently, fprintf('\t#spikes = %d',nSnips); end
        
        DO(cidx).totalspikes = 0; %#ok<AGROW>
        DO(cidx).blockspikes(bidx) = nSnips; %#ok<AGROW>
        DO(cidx).channel = cidx; %#ok<AGROW>

        if nSnips > 1
            DO(cidx).timestamps{bidx} = TT.ParseEvInfoV(0,nSnips,6)'; %#ok<AGROW>
            DO(cidx).waveforms{bidx}  = TT.ParseEvV(0,nSnips)'; %#ok<AGROW>
            DO(cidx).sortcode{bidx}   = TT.ParseEvInfoV(0,nSnips,5)'; %#ok<AGROW>
        else
            DO(cidx).timestamps{bidx} = []; %#ok<AGROW>
            DO(cidx).waveforms{bidx}  = []; %#ok<AGROW>
            DO(cidx).sortcode{bidx}   = []; %#ok<AGROW>
        end
        
        uids = unique(DO(cidx).sortcode{bidx});
        uids(uids==31) = -1; % outliers
        DO(cidx).sortcode{bidx}(DO(cidx).sortcode{bidx}==31) = -1; %#ok<AGROW> % outliers
        if isempty(uids), uids = 0; end
        DO(cidx).units(bidx).classid = uids; %#ok<AGROW>
        for u = 1:length(uids)
            cnt = sum(DO(cidx).sortcode{bidx} == uids(u));
            if isempty(cnt), cnt = 0; end
            DO(cidx).units(bidx).count(u) = cnt; %#ok<AGROW>
            fprintf('\t% 3.0f: %d;',uids(u),DO(cidx).units(bidx).count(u))
        end
        DO(cidx).totalspikes = sum([DO(cidx).units(bidx).count]); %#ok<AGROW>
        DO(cidx).fsample(bidx) = cfg.fsample(bidx); %#ok<AGROW> % I know these are all the same, but the strucuture is an array
    end % cidx
    
end % bidx
cfg.tankcreation = TT.FancyTime(TT.CurBlockStartTime,'Y-O-D');

if ~cfg.silently, fprintf('\n'); end

function [dataout,cfg] = get_waves(TT,cfg,blocklist) %#ok<DEFNU>
TT.SetGlobalV('WavesMemLimit',10^9);

for bidx = 1:length(blocklist)
    TT.ResetFilters;
    if ~cfg.silently, fprintf('\nGrabbing %s from %s...',cfg.event,blocklist{bidx}); end
    
    if ~TT.SelectBlock(blocklist{bidx})
        error(['Unable to select block: ', blocklist{bidx}]);
    end
    
    TT.CreateEpocIndexing;
    
    if strcmpi(cfg.channel,'all') || all(isnan(cfg.channel))
        n = TT.ReadEventsV(256,cfg.event,0,0,0,0,'NODATA');
        cfg.channel = unique(TT.ParseEvInfoV(0,n,4));
    end
    
    for cidx = 1:length(cfg.channel)
        if ~cfg.silently, fprintf('\n\tChannel: %d\t(%d of %d) ',cfg.channel(cidx),cidx,length(cfg.channel)); end
        
        TT.SetGlobals(sprintf('Channel=%d',cfg.channel(cidx)));
        w = TT.ReadWavesV(cfg.event);
        
        cfg.fsample(bidx) = TT.ParseEvInfoV(0,1,9);
        DO.fsample        = cfg.fsample(bidx);

        if (any(isnan(w)) || all(w == 0)) && ~cfg.silently
            fprintf(' ... no data')
        end
        
        if cidx > 1
            w = w(1:size(DO.waves,1));
        end
        DO.waves(:,cidx) = w;
    end % cidx
    clear w
    
    if isfield(cfg,'downfs') && cfg.downfs < DO.fsample
        sstep = round(DO.fsample/cfg.downfs);
        if sstep > 1
            % convert sampling rate
            DO.fsample = DO.fsample/sstep;
            fprintf('\nDownsampling from %0.2f Hz to %0.2f Hz ...', ...
                cfg.fsample(bidx),DO.fsample)
            cfg.fsample(bidx) = DO.fsample;
            
            % run anti-aliasing filter before downsampling
            nyquist = DO.fsample/2;
            lppb    = nyquist * 0.90;
            [z,p,k] = butter(6,lppb/nyquist,'low');
            [sos,~] = zp2sos(z,p,k);   
            DO.waves = single(sosfilt(sos,double(DO.waves)));
            
            % downsample
            DO.waves = DO.waves(1:sstep:end,:);
            fprintf(' done\n')
        end
    end
    ind = logical(all(DO.waves==0));
    DO.channels = cfg.channel(~ind);
    DO.waves(:,ind) = [];
    
    if any(ind) && ~cfg.silently
        fprintf('\n%d channels had no activity, so there were really %d channels',sum(ind),length(DO.channels));
    end
    
    
    dataout(bidx) = DO; %#ok<AGROW>
    clear DO
end % bidx

cfg.tankcreation = TT.FancyTime(TT.CurBlockStartTime,'Y-O-D');

if ~cfg.silently, fprintf('\n'); end



