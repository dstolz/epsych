function varargout = DB_UploadUtility(varargin)

% Last Modified by GUIDE v2.5 29-May-2013 09:40:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DB_UploadUtility_OpeningFcn, ...
                   'gui_OutputFcn',  @DB_UploadUtility_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before DB_UploadUtility is made visible.
function DB_UploadUtility_OpeningFcn(hObj, ~, h, varargin)
% Choose default command line output for DB_UploadUtility
h.output = hObj;

set(hObj,'Pointer','watch'); drawnow
PopulateDBs(h);
PopulateExperiments(h);
set(h.db_description,'String',db_descr);

preg = getpref('UploadUtility','datasetpath',[]);
if ~isempty(preg)
    set(h.ds_path,'String',preg);
    ds_locate_path_Callback(h.ds_locate_path,preg,h);
end

set(hObj,'Pointer','arrow');

% Update h structure
guidata(hObj, h);



% --- Outputs from this function are returned to the command line.
function varargout = DB_UploadUtility_OutputFcn(hObj, ~, h)  %#ok<INUSL>
varargout{1} = h.output;







%% Database
function db_newdb_Callback(hObj, ~, h) %#ok<INUSL>
newdb = inputdlg('Enter name of new Experiment.  Use ''_'' in place of spaces.','New Experiment');

if isempty(newdb),  return; end

if isdbase(newdb)
    disp(['The database ''' newdb ''' already exists on this server'])
    return
end

DB_CreateDatabase(char(newdb));

if isdbase(newdb)
    msgbox(sprintf('Database has been added: %s',char(newdb)), ...
        'New Database','modal');
    db_add_descr;
end

dbs = get(h.db_list,'String');
if isempty(dbs)
    dbs = newdb;
else
    dbs{end+1} = char(newdb);
end

set(h.db_list,'String',dbs,'Value',length(dbs));

mym('use',char(newdb));

set(h.expt_subject_list,'Value',1,'String',' ');

PopulateDBs(h);
PopulateExperiments(h);

function db_list_Callback(hObj, ~, h) %#ok<DEFNU>
% Database list, update Experiment Info
db = get(hObj,'String');
if isempty(db), db_newdb_Callback(h.db_newdb,[],h); end

db = cellstr(get(h.db_list,'String'));
db = db{get(h.db_list,'Value')};

if ~myisopen
    set(h.figure1,'pointer','watch'); drawnow
    DB_Connect; 
    set(h.figure1,'pointer','arrow'); drawnow
end

mym('use',db);

setpref('UploadUtility','database',db);

set(h.db_description,'String',db_descr);

PopulateExperiments(h);

function modify_descr_Callback(hObj, ~, h) %#ok<INUSL,DEFNU>
db_add_descr;
set(h.db_description,'String',db_descr);

function db_add_descr
s = [];
try %#ok<TRYNC>
    s = myms(['SELECT CAST(infostr as CHAR) FROM dbinfo ', ...
        'WHERE infotype = "description"']);
end

if isempty(s), s = {' '}; end

s = inputdlg('Enter database description:','Database Description',10,s);
if ~isempty(s)
    mym(['REPLACE INTO dbinfo ', ...
        '(infotype,infostr) VALUES ', ...
        '("description","{S}")'], ...
        char(s));
end

function s = db_descr
s = [];
try %#ok<TRYNC>
    s = myms(['SELECT CAST(infostr as CHAR) FROM dbinfo ', ...
        'WHERE infotype = "description"']);
end

if isempty(s)
    s = ['** No description has been entered for this database.  ', ...
         'Click "Modify Description" button below to add one. **'];
else
    s = sprintf('DESCRIPTION:\n\n%s',char(s));
end

function PopulateDBs(h)
set(h.db_list, 'Enable','off');
set(h.db_newdb,'Enable','off');

% Connect to server and retrieve databases
if ~myisopen, dbs = DB_Connect; else dbs = dblist; end

set(h.db_list,'Value',1,'String',dbs);
rdb = getpref('UploadUtility','database',[]);
if ~isempty(rdb) && ismember(rdb,dbs)
    val = find(ismember(dbs,rdb));
else
    val = 1;
end
set(h.db_list,'Value',val);

if isempty(dbs)
    uiwait(msgbox(['We''re connected to the server, but no appropriate databases were found.', ...
        '\n\nClick OK to create your first database'],'No databases found','help','modal'));
    db_newdb_Callback(h.db_newdb, [], h);
end
    
mym('use', dbs{val});

% get electrode types
e = myms(['SELECT CONCAT(manufacturer,'' - '',product_id) AS electrodes ', ...
    'FROM db_util.electrode_types']);
set(h.ds_electrode,'String',e,'Value',1);

set(h.ds_electrode,'Value',1);

set(h.db_list, 'Enable','on');
set(h.db_newdb,'Enable','on');























%% Experiment/Subject
function expt_subject_list_Callback(hObj, ~, h) %#ok<DEFNU>
e = cellstr(get(h.expt_list,'String'));
e = e{get(h.expt_list,'Value')};
s = cellstr(get(hObj,'String'));
s = s{get(hObj,'Value')};

r = questdlg(sprintf(['This will change the subject for experiment ''%s'' to ''%s''.  ', ...
    'Are you sure you would like to continue?'],e,s),'Change Subject', ...
    'Change Subject','Cancel','Cancel');

if strcmp('Cancel',r)
    PopulateExperimentInfo(h);
    return
end

mym(['UPDATE experiments SET subject_id = ', ...
     '(SELECT id FROM subjects WHERE name = "{S}") ', ...
     'WHERE name = "{S}"'],s,e);

function expt_list_Callback(hObj, ~, h) %#ok<INUSL,DEFNU>
PopulateExperimentInfo(h);

function expt_researchers_Callback(hObj, ~, h) %#ok<DEFNU>
e = cellstr(get(h.expt_list,'String'));
e = e{get(h.expt_list,'Value')};

s = cellstr(get(hObj,'String'));
s = s(get(hObj,'Value'));

% update experiments table with researcher ids
s = cellstr(deblank(strtok(s,'-')));
cats = 'SELECT id FROM db_util.researchers WHERE initials IN (';
for i = 1:length(s)
    cats = sprintf('%s"%s",',cats,s{i});
end
cats(end) = [];  cats(end+1) = ')';
id = myms(cats);
id = num2str(id(:)','%d,'); id(end) = [];
mym(['UPDATE experiments SET researcher = "{S}" ', ...
     'WHERE name = "{S}"'],id,e);

function expt_new_expt_Callback(hObj, ~, h) 
db = get(h.db_list,'String');
if isempty(db)
    disp('You must first add or select a database before adding an experiment')
    return
end

ename = get(h.expt_list,'String');
if hObj == h.expt_new_expt
    ename = deblank(inputdlg('Enter experiment name:','New Experiment'));
    if isempty(ename), return; end 
else
    ename = ename{get(h.expt_list,'Value')};
end

exptexists = myms(sprintf('SELECT id FROM experiments WHERE name="%s"',char(ename)));
if isempty(exptexists), exptexists = 0; end

ename = char(ename);
subject_id      = get(h.expt_subject_list,'Value');
researcher      = get(h.expt_researchers,'Value');
researcher      = num2str(researcher,'%d,');
researcher(end) = [];

if exptexists
    mym(['UPDATE experiments ', ...
        'SET subject_id = {Si}, ', ...
        'researcher     = "{S}" ', ...
        'WHERE name = "{S}"'], ...
        subject_id,researcher,ename );

    fprintf('\nExperiment updated\n')
else
    mym(['INSERT INTO experiments ', ...
        'SET name   = "{S}", ', ...
        'subject_id = {Si}, ', ...
        'researcher = (SELECT GROUP_CONCAT(r.initials SEPARATOR '', '') ', ...
        'FROM db_util.researchers r WHERE r.id IN ({S}))'], ...
        ename,subject_id,researcher);
    fprintf('\nExperiment added\n')
end

PopulateExperiments(h);

function expt_new_subject_Callback(hObj, ~, h) %#ok<INUSL>
db = cellstr(get(h.db_list,'String'));
db = db{get(h.db_list,'Value')};
uiwait(DB_NewSubjPrompt(db));
subj = myms('SELECT name FROM subjects');
if isempty(subj), return; end
set(h.expt_subject_list,'String',subj);
set(h.expt_subject_list,'Value',length(subj));

function PopulateExperiments(h)
set(h.modify_descr,'Enable','on');

expts = myms('SELECT name FROM experiments');

if isempty(expts)
    expt_new_expt_Callback(h.expt_new_expt,[],h);
    PopulateExperiments(h);
end

set(h.expt_list,'Value',1);

if isempty(expts)
    set(h.expt_list,'String',' ');
    return
end

set(h.expt_list,'String',expts);

PopulateExperimentInfo(h)

function PopulateExperimentInfo(h)
expt_name = cellstr(get(h.expt_list,'String'));
expt_name = expt_name{get(h.expt_list,'Value')};

[id,subject_id,researcher] = myms(sprintf( ...
    ['SELECT id,subject_id,researcher ', ...
     'FROM experiments WHERE name="%s"'],expt_name));

if isempty(id),
    expt_new_subject_Callback(h.expt_new_subject, [], h)
    return
end

subjects = myms('SELECT name FROM subjects');
if ~isempty(subject_id)
    set(h.expt_subject_list,'String',subjects);
    set(h.expt_subject_list,'Value',subject_id);
end

% get researchers
rout = myms(['SELECT CONCAT(initials, '' - '', name) AS name ', ...
     'FROM db_util.researchers']);
set(h.expt_researchers,'String',rout,'Value',1);
rid = str2num(char(researcher)); %#ok<ST2NM>
if ~isempty(rid)
    set(h.expt_researchers, 'Value', rid);
end













%% Dataset
function ds_list_Callback(hObj, ~, h) %#ok<DEFNU>
% Dataset was selected, update block list
s = get_string(hObj);
if isempty(s), return; end

set(h.figure1,'pointer','watch'); 
set(h.ds_add_to_queue,'Enable','off'); drawnow

tank = get_string(h.ds_list);
[tank,~] = strtok(tank,' [');

pn = get(h.ds_path,'String');
ptank = fullfile(pn,tank);
blocks = TDT2mat(ptank);

sortnames = {'TankSort'};
bstr  = cell(size(blocks));
bidx  = [];
deadblocks = [];
for i = 1:length(blocks)
    try
        d = TDT2mat(ptank,blocks{i},'silent',true,'Type',2);
    catch ME
        if strcmp(ME.message(1:37),'Block found, but problem selecting it')
            deadblocks(end+1) = i; %#ok<AGROW>
            bstr{i} = sprintf('%s - ERROR',blocks{i});
            continue
        else
            rethrow(ME);
        end
    end
    c = struct2cell(d);
    f = fieldnames(d);
    ind = strcmp('epocs',f);
    if any(ind) && isfield(c{ind},'PROT')
        pname = DB_GetProtocolName(c{ind}.PROT.data(1));
    else
        pname = 'Unknown';
    end
    f{end+1} = 'pname'; %#ok<AGROW>
    c{end+1} = pname; %#ok<AGROW>
    data(i) = cell2struct(c,f); %#ok<AGROW>
    bstr{i} = sprintf('%s - %s [%s]', ...
        blocks{i},data(i).pname,datestr(data(i).info.duration,'MM:SS'));
    if str2num(datestr(data(i).info.duration,'MM')) > 0, bidx(end+1) = i; end %#ok<ST2NM,AGROW>
    if isempty(data(i).snips)
        subfield = [];
    else
        subfield = char(fieldnames(data(i).snips));
    end
    if ~isempty(subfield)
        sortnames = union(sortnames,data(i).snips.(subfield).sorts);
    end
end


set(h.ds_blocks,'String',bstr,'Value',bidx,'UserData',data); % update listbox

sval = 1;
if length(sortnames) > 1
    sval = ismember(sortnames,'TankSort');
    sval = find(~sval,1);
end
set(h.ds_sortname,'String',sortnames,'Value',sval);

ds_blocks_Callback(h.ds_blocks, [], h);
set(h.figure1,'pointer','arrow');



function ds_add_to_queue_Callback(hObj, ~, h) %#ok<INUSL,DEFNU>
Queue = getappdata(h.figure1,'UPLOAD_QUEUE');

% Gather all info for uploading
Q.data  = getappdata(h.figure1,'QBlockInfo');

if isempty(Q.data), return; end

Q.experiment = get_string(h.expt_list);
Q.events     = cellstr(get_string(h.ds_events));
for i = 1:length(Q.events)
    [Q.events{i},r] = strtok(Q.events{i});
    Q.eventtype{i}  = r(3:end-1);
end
Q.sortname   = get_string(h.ds_sortname);
Q.condition  = get(h.ds_condition,'String');
Q.tanknotes  = get(h.ds_notes,'String'); 
Q.electrode  = get_string(h.ds_electrode);
Q.elecdepth  = str2num(get(h.ds_depth,'String')); %#ok<ST2NM>
Q.electarget = get(h.ds_target,'String');

if isempty(Q.condition),  Q.condition = ' ';  end
if isempty(Q.tanknotes),  Q.tanknotes = ' ';  end
if isempty(Q.electarget), Q.electarget = ' '; end

tank = get_string(h.ds_list);

[Q.tank,ac] = strtok(tank,' [');
Q.hasACpools = ~isempty(ac);

if isempty(Queue)
    Queue = Q;
else
    Queue(end+1) = Q;
end

setappdata(h.figure1,'UPLOAD_QUEUE',Queue);

% Update Queue
qstr = get(h.upload_queue,'String');
estr = sprintf(' %s,',Q.events{:}); estr(end) = [];
qstr{end+1} = sprintf('TANK: %s with %d blocks, %s',Q.tank,length(Q.data),estr);
set(h.upload_queue,'String',qstr);



function ds_path_Callback(hObj, ~, h) %#ok<DEFNU,INUSL>
% Manually locate parent directory
ds_locate_path_Callback(h.ds_locate_path, [], h)

function ds_locate_path_Callback(hObj, pn, h) %#ok<INUSL>
% optionally pass in a path string for pn

if isempty(pn)
    % Manually locate parent directory
    pn = uigetdir([],'Locate Tank Parent Directory');
    if ~pn, return; end
end

setpref('UploadUtility','datasetpath',pn);

if pn(end) ~= '\', pn(end+1) = '\'; end
set(h.ds_path,'String',pn);

Tanks = CheckForTanks(pn);

% Find valid pooled datasets
ACpath = 'C:\AutoClass_Files\AC2_RESULTS\';
ACsubdirs = dir(ACpath);
ACsubdirs = ACsubdirs([ACsubdirs.isdir]);
ACsubdirs(ismember({ACsubdirs.name},{'.','..'})) = [];
pooledChs = cell(size(ACsubdirs)); hasPools = false(size(ACsubdirs));
for i = 1:length(ACsubdirs)
    pooledChs{i} = dir(fullfile(ACpath,ACsubdirs(i).name,'*POOLS.mat'));
    hasPools(i)  = ~isempty(pooledChs{i});
end
ACtanks = {ACsubdirs.name};
if ~isempty(Tanks)
    idx = find(ismember(Tanks,ACtanks));
    for i = idx
        tidx = ismember(ACtanks,Tanks{i});
        Tanks{i} = sprintf('%s [%d POOLS]',Tanks{i},length(pooledChs{tidx}));
    end
end
set(h.ds_list,'Value',length(Tanks),'String',Tanks);

function ds_blocks_Callback(hObj, ~, h)
v = get(hObj,'Value');
if isempty(v) % no blocks are selected
    set(h.ds_add_to_queue,'Enable','off');
    return
end

data = get(hObj,'UserData');

dfltvals = [];

str = {[]};
fn = fieldnames(data(1).snips);
if ~isempty(fn)
    dfltvals = 1;
    for i = 1:length(fn)
        str{i} = sprintf('%s (snips)',fn{i});
    end
end

fn = fieldnames(data(1).streams);
if ~isempty(fn)
    n = length(str);
    dfltvals(end+1) = n+1;
    for i = 1:length(fn)
        str{n+i} = sprintf('%s (streams)',fn{i});
    end
end

if isempty(str{1})
    errordlg('No events were found for this block.','DB_UploadUtility','modal')
    set(h.ds_events,'String','','Value',1);
	set(h.ds_add_to_queue,'Enable','off');
    return
else
    set(h.ds_add_to_queue,'Enable','on');
end

vals = getpref('DB_UploadUtility','datatypes',dfltvals);
if vals == 0, vals = dfltvals; end

set(h.ds_events,'String',str,'Value',vals);

setappdata(h.figure1,'QBlockInfo',data(v));


function ds_events_Callback(hObj, ~, ~  ) %#ok<DEFNU>
vals = get(hObj,'Value');
setpref('DB_UploadUtility','datatypes',vals);




































%% Upload
function upload_data_Callback(hObj, ~, h) %#ok<INUSL,DEFNU>
Queue = getappdata(h.figure1,'UPLOAD_QUEUE');
if isempty(Queue), return; end

curdb = get_string(h.db_list);

if ~myisopen, DB_Connect; end
if ~strcmp(dbcurr,curdb), dbopen(curdb); end

set(findobj(h.figure1,'Enable','on'),'Enable','off');
drawnow

try
    for i = 1:length(Queue)
        Q = Queue(i);
        
        B = Q.data;
        
        exptid = myms(sprintf('SELECT id FROM experiments WHERE name = "%s"',Q.experiment));
        
        % Delete any existing data for this tank
        oldtid = myms(sprintf('SELECT id FROM tanks WHERE name = "%s"',Q.tank));
        if ~isempty(oldtid)
            oldbid = myms(sprintf('SELECT id FROM blocks WHERE tank_id = %d',oldtid));
            for b = 1:length(oldbid)
                oldcid = myms(sprintf('SELECT id FROM channels WHERE block_id = %d',oldbid(b)));
                mym('DELETE IGNORE FROM channels WHERE block_id = {Si}',oldbid(b));
                mym('DELETE FROM protocols WHERE block_id = {Si}',oldbid(b));
                if ~isempty(oldcid)
                    s = sprintf('%d,',oldcid); s(end) = [];
                    mym('DELETE IGNORE FROM wave_data WHERE channel_id IN ({S})',s);
                    olduid = myms(sprintf('SELECT id FROM units WHERE channel_id IN (%s)',s));
                    if ~isempty(olduid)
                        s = sprintf('%d,',olduid); s(end) = [];
                        mym('DELETE IGNORE FROM spike_data WHERE unit_id IN ({S})',s);
                        mym('DELETE IGNORE FROM units WHERE id IN ({S})',s);
                    end
                end
                
            end
            mym('DELETE IGNORE FROM tanks WHERE id = {Si}',oldtid);
            mym('DELETE IGNORE FROM blocks WHERE tank_id = {Si}',oldtid);
        end
        
        
        % update tanks
        snipsFs   = 1;
        streamsFs = 1;
        
        for j = 1:length(Q.eventtype)
            eval(sprintf('%sFs = B(1).%s.%s.fs;',Q.eventtype{j},Q.eventtype{j},Q.events{j}));
        end
        
        snipEvent   = [];
        streamEvent = [];
        
        ei = strcmp('snips',Q.eventtype);
        if any(ei), snipEvent   = Q.events{ei}; end
        
        ei = strcmp('streams',Q.eventtype);
        if any(ei), streamEvent = Q.events{ei}; end
        TN = shiftdim(Q.tanknotes,1);
        TN = TN(:)';
        mym(['INSERT tanks (exp_id,tank_condition,tank_date,tank_time,name,spike_fs,wave_fs,tank_notes) ', ...
            'VALUES ({Si},"{S}","{S}","{S}","{S}",{S},{S},"{S}")'], ...
            exptid,Q.condition,datestr(B(1).info.date,'yyyy-mm-dd'),datestr(B(1).info.begintime,'HH:MM:SS'), ...
            Q.tank,num2str(snipsFs,'%0.5f'),num2str(streamsFs,'%0.5f'),TN);
        tid = myms(sprintf('SELECT DISTINCT id FROM tanks WHERE name = "%s"',Q.tank));
                
        % update electrode
        e = Q.electrode(find(Q.electrode=='-',1,'first')+2:end);
        mym(['INSERT electrodes (tank_id,type,depth,target) VALUES ', ...
            '({Si},(SELECT id FROM db_util.electrode_types WHERE NOT STRCMP(product_id,"{S}")),' ...
            '{S},"{S}")'],tid,e,Q.elecdepth,Q.electarget);
        
        for j = 1:length(B)
            fprintf('\nUploading tank ''%s'', block ''%s'' (%d of %d)\n', ...
                Q.tank,B(j).info.blockname,j,length(B))
            % update blocks
            if strcmp(B(j).pname,'Unknown'), B(j).pname = '?'; end
            pid = myms(sprintf('SELECT DISTINCT pid FROM db_util.protocol_types WHERE alias = "%s"',...
                B(j).pname));
            
            
            assert(isscalar(pid),'DB_UploadUtility:upload_data_Callback: Redundant protocol types (pid) on protocol_types table in db_util database.')
            
            
            blockidx = str2num(B(j).info.blockname(find(B(j).info.blockname=='-',1,'last')+1:end)); %#ok<ST2NM>
            mym(['REPLACE blocks (tank_id,block,protocol,block_date,block_time) VALUES ', ...
                '({Si},{Si},{Si},"{S}","{S}")'], ...
                tid,blockidx,pid, ...
                datestr(datevec(B(j).info.date,'yyyy-mmm-dd'),'yyyy-mm-dd'), ...
                B(j).info.begintime);
            
            % update protocols
            blockid = myms(sprintf('SELECT id FROM blocks WHERE tank_id = %d AND block = %d',tid,blockidx));
            
            fprintf('\tUploading protocol data ...')
            
            % get parameter codes from db_util.param_types; insert new codes if does not exist
            if ~isempty(B(j).epocs)
                paramspec = fieldnames(B(j).epocs);
                paramspec(ismember(paramspec,{'PROT','Tick','Tock','Mark'})) = [];
                if isempty(paramspec)
                    B(j).epocs.onset.data = B(j).epocs.PROT.onset;
                else
                    B(j).epocs.onset.data = B(j).epocs.(paramspec{1}).onset;
                end
                paramspec{end+1} = 'onset'; %#ok<AGROW>
                parcode = nan(size(paramspec));
                epocs = nan(length(B(j).epocs.(paramspec{1}).data),length(paramspec));
                for k = 1:length(paramspec)
                    checkpar = myms(sprintf('SELECT id FROM db_util.param_types WHERE param = "%s"',paramspec{k}));
                    if isempty(checkpar)
                        mym('INSERT db_util.param_types (param) VALUE ("{S}")',paramspec{k});
                        parcode(k) = myms(sprintf('SELECT id FROM db_util.param_types WHERE param = "%s"',paramspec{k}));
                    else
                        parcode(k) = checkpar;
                    end
                    epocs(:,k) = B(j).epocs.(paramspec{k}).data;
                end
                % create matrix for protocol
                param_id      = repmat(1:size(epocs,1),size(epocs,2),1);
                param_type    = repmat(parcode(:),1,size(epocs,1));
                param_value   = epocs';
                nepochs       = numel(epocs);
                protdata(:,1) = repmat(blockid,nepochs,1);
                protdata(:,2) = param_id(:);
                protdata(:,3) = param_type(:);
                protdata(:,4) = param_value(:);
                
                % upload each row of the protocol
                for k = 1:size(protdata,1)
                    mym(['INSERT protocols (block_id,param_id,param_type,param_value) VALUES ', ...
                        '({Si},{Si},{Si},{S})'], ...
                        protdata(k,1),protdata(k,2),protdata(k,3),num2str(protdata(k,4),'%0.6f'));
                end
                clear protdata
                fprintf(' done\n')
            else
                fprintf(' no protocol data found\n')
            end
            
            % get snips from tank block
            data = TDT2mat(Q.tank,B(j).info.blockname,'silent',true,'type',[2 3], ...
                'SortName',Q.sortname);
            
            % update channels
            if ~isempty(data.streams) && ~isempty(streamEvent)
                channels = data.streams.(streamEvent).chan;
            else
                channels = unique(data.snips.(snipEvent).chan);
            end
            
            fprintf('\tAdding %d channels ... ',length(channels))
            for k = channels
                mym(['INSERT channels (block_id,channel,target) VALUES ', ...
                    '({Si},{Si},"{S}")'],blockid,k,Q.electarget);
            end
            fprintf('done\n')
            
            % update units
            if ismember('snips',Q.eventtype)
                snips = data.snips.(snipEvent);
                schans = unique(snips.chan);
                for k = 1:length(schans)
                    fprintf('\tUploading spikes on channel% 3.0f (%d of %d)', ...
                        schans(k),k,length(schans))
                    channel_id = myms(sprintf('SELECT id FROM channels WHERE channel = %d AND block_id = %d', ...
                        schans(k),blockid));
                    
                    units = unique(snips.sort(snips.chan==schans(k)));
                    
                    for u = units
                        uind = snips.sort == u & snips.chan == schans(k);
                        pwaveform = mean(snips.data(uind,:),1);
                        pstddev   = std(snips.data(uind,:),0,1);
                        
                        fprintf('\n\t\tPool % 4d: % 6.0f spikes ...',u,sum(uind))
                        
                        mym(['INSERT units (channel_id,pool,unit_count,pool_waveform,pool_stddev) VALUES ', ...
                            '({Si},{Si},{Si},"{S}","{S}")'], ...
                            channel_id,u,sum(uind),num2str(pwaveform),num2str(pstddev));
                        
                        uid = myms(sprintf(['SELECT id FROM units ', ...
                            'WHERE channel_id = %d AND pool = %d'], ...
                            channel_id,u));
                        
                        % update spike_data
                        ts = num2str(snips.ts(uind)','%0.6f');
                        for kk = 1:size(ts,1)
                            mym('INSERT spike_data (unit_id,spike_time) VALUES ({Si},{S})', ...
                                uid,ts(kk,:));
                        end
                        
                        fprintf(' done')
                    end
                    fprintf('\n')
                end
                
            end
            
%             if ~isempty(data.streams) && ~isempty(streamEvent)
            if ismember('streams',Q.eventtype)
                % update wave_data
                DB_UploadWaveData(Q.tank,B(j).info.blockname,streamEvent);
                
            end
        end
    end
    fprintf('\nCompleted upload at %s\n\n',datestr(now,'dd-mmm-yyyy HH:MM:SS'))
catch ME
   set(findobj(h.figure1,'Enable','on'),'Enable','on');
   rethrow(ME)
end
set(findobj(h.figure1,'Enable','on'),'Enable','on');
















function upload_remove_Callback(hObj, ~, h) %#ok<INUSL,DEFNU>
Queue = getappdata(h.figure1,'UPLOAD_QUEUE');
if isempty(Queue), return; end

v = get(h.upload_queue,'Value');
Queue(v) = [];
setappdata(h.figure1,'UPLOAD_QUEUE',Queue);

qstr = get(h.upload_queue,'String');
qstr(v) = [];
if isempty(qstr), v = 1; elseif v > length(qstr),v = length(qstr); end
set(h.upload_queue,'Value',v,'String',qstr);
