function varargout = ep_ExperimentDesign(varargin)
% h = ep_ExperimentDesign
%
% Design protocols for EPsych experiments
%
% Daniel.Stolzberg@gmail.com 2014

% Last Modified by GUIDE v2.5 02-Aug-2014 10:45:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @ep_ExperimentDesign_OpeningFcn, ...
    'gui_OutputFcn',  @ep_ExperimentDesign_OutputFcn, ...
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

function ep_ExperimentDesign_OpeningFcn(hObj, ~, h, varargin)
h.output = hObj;

if nargin > 3
    % Load schedule file pointed to by varargin{1}
    protocol = LoadProtocolFile(h,varargin{1});
    set(h.param_table,'Data',protocol.param_data);
    guidata(hObj, h);
else
    NewProtocolFile(h);
    set(h.param_table,'Data',dfltrow);
end

UpdateProtocolDur(h);





function varargout = ep_ExperimentDesign_OutputFcn(hObj, ~, h)  %#ok<INUSL>
varargout{1} = h.output;






















%% Protocol Setup
function SaveProtocolFile(h,fn)
% Save current protocol to file
if ~exist('fn','var') || isempty(fn)
    pn = getpref('PSYCH','ProtDir',cd);
    if ~ischar(pn), pn = cd; end
    [fn,pn] = uiputfile({'*.prot','Protocol File (*.prot)'}, ...
        'Save Protocol File',pn);
    setpref('PSYCH','ProtDir',pn);
    if ~fn, return; end
    fn = fullfile(pn,fn);
end


set(h.ProtocolDesign,'Name','Protocol Design | SAVING ...');
fprintf('Saving protocol ...')
GUISTATE(h.ProtocolDesign,'off');


protocol = h.protocol;
if isfield(protocol,'COMPILED')
    protocol = rmfield(protocol,'COMPILED');
end

% trim any undefined parameters
fldn = fieldnames(protocol.MODULES);
% fldn(ismember(fldn,{'INFO','OPTIONS','COMPILED'})) = [];
for i = 1:length(fldn)
    v = protocol.MODULES.(fldn{i}).data;
    v(~ismember(1:size(v,1),findincell(v(:,1))),:) = [];
    protocol.MODULES.(fldn{i}).data = v;
end

protocol = AffixOptions(h,protocol);
protocol = ep_CompileProtocol(protocol);

% replace buffers with file ids
for i = 1:length(fldn)
    d = protocol.MODULES.(fldn{i}).data;
    idx = find(cell2mat(d(:,6)));
    for j = 1:length(idx)
        v = ['File IDs: [' num2str(1:length(d{idx(j),4})) ']'];
        d{idx(j),4} = v;
        protocol.MODULES.(fldn{i}).data = d;
    end
end

if protocol.OPTIONS.compile_at_runtime
    protocol.COMPILED = rmfield(protocol.COMPILED,'trials');
end

save(fn,'protocol','-mat');

GUISTATE(h.ProtocolDesign,'on');
set(h.ProtocolDesign,'Name','Protocol Design');
fprintf(' done\nFile Location: ''%s''\n',fn);

function GUISTATE(fh,onoff)
% Disable/Enable GUI components and set pointer state
pdchildren = findobj(fh,'-property','Enable');
set(pdchildren,'Enable',onoff);
if strcmpi(onoff,'on')
    OpTcontrol(findobj(fh,'tag','opt_optcontrol'),guidata(fh));
    set(fh,'pointer','arrow'); 
else
    set(fh,'pointer','watch'); 
end
drawnow


function r = NewProtocolFile(h,promptOpenEx)
if nargin == 1, promptOpenEx = 1; end

r = [];
% Create new protocol file
if isfield(h,'protocol') && ~isempty(h.protocol)
    r = questdlg('Would you like to save the current protocol before creating a new one?', ...
        'Create New Protocol', ...
        'Yes','No','Cancel','Cancel');
    switch r
        case 'Cancel'
            return
        case 'Yes'
            SaveProtocolFile(h);
    end
end

set(h.param_table,'Data',dfltrow,'Enable','off');
set(h.module_select,'String','','Value',1);
set(findobj('-regexp','tag','^opt'),'Enable','on');

splash('on');

h.protocol = [];

% Prompt if OpenEx will be used
if promptOpenEx
    b = questdlg('Will this experiment use OpenEx?','Experiment Design','Yes','No','No');
    if strcmp(b,'Yes')
        set(h.lbl_useOpenEx,'String','Using OpenEx','ForegroundColor','b');
        h.UseOpenEx = true;
    else
        set(h.lbl_useOpenEx,'String','Not using OpenEx','ForegroundColor','k');
        h.UseOpenEx = false;
    end
end

set(h.protocol_dur,'String','', ...
    'backgroundcolor',get(h.ProtocolDesign,'Color'));
guidata(h.ProtocolDesign,h);

function splash(onoff)
h = findobj('tag','pdsplash');
if isequal(onoff,'on')
    set(h,'visible','on');
else
    set(h,'visible','off');
end


function protocol = LoadProtocolFile(h,fn)
% Load previously saved protocol from file
protocol = [];

r = NewProtocolFile(h,0);
if strcmp(r,'Cancel'), return; end

if ~exist('fn','var') || isempty(fn) || ~exist(fn,'file')
    pn = getpref('PSYCH','ProtDir',cd);
    if isequal(pn,0), pn = cd; end
    [fn,pn] = uigetfile({'*.prot','Protocol File (*.prot)'},'Locate Protocol File',pn);
    if ~fn, return; end
end

set(h.ProtocolDesign,'Name','Protocol Design: Loading ...');
GUISTATE(h.ProtocolDesign,'off');

load(fullfile(pn,fn),'-mat');

if ~exist('protocol','var')
    error('ProtocolDesign:Unknown protocol file data');
end

% Populate module list
fldn = fieldnames(protocol.MODULES);
obj = findobj(h.ProtocolDesign,'tag','module_select');
set(obj,'String',fldn,'Value',1);

% Ensure all buddy variables are accounted for
n = {'< ADD >','< NONE >'};
for i = 1:length(fldn)
    n = union(n,protocol.MODULES.(fldn{i}).data(:,3));
end
cf = get(h.param_table,'ColumnFormat');
cf{3} = n;
set(h.param_table,'ColumnFormat',cf);

if isfield(protocol,'TABLEDATA')
    TD = protocol.TABLEDATA;
else
    TD = [];
end
set(h.param_table,'UserData',TD);

% Populate options
Op = protocol.OPTIONS;
set(h.opt_randomize,         'Value', Op.randomize);
set(h.opt_compile_at_runtime,'Value', Op.compile_at_runtime);
set(h.opt_iti,               'String',num2str(Op.ISI));
set(h.opt_num_reps,          'String',num2str(Op.num_reps));

if isfield(Op,'optcontrol')
    set(h.opt_optcontrol,'Value',Op.optcontrol);
end
OpTcontrol(h.opt_optcontrol,h);

if isfield(Op,'trialfunc')
    set(h.trial_selectfunc,'String',Op.trialfunc);
else
    set(h.trial_selectfunc,'String','< default >');
end
set(h.protocol_info,'String',protocol.INFO);

set(h.param_table,'Enable','on');
splash('off');
h.protocol = protocol;
guidata(h.ProtocolDesign,h);

setpref('PSYCH','ProtDir',pn);

SetParamTable(h,protocol);

UpdateProtocolDur(h);

set(h.ProtocolDesign,'Name','Protocol Design');
GUISTATE(h.ProtocolDesign,'on');



function p = AffixOptions(h,p)
% affix protocol options
p.OPTIONS.randomize          = get(h.opt_randomize,         'Value');
p.OPTIONS.compile_at_runtime = get(h.opt_compile_at_runtime,'Value');
p.OPTIONS.ISI                = str2num(get(h.opt_iti,       'String')); %#ok<ST2NM>
p.OPTIONS.num_reps           = str2num(get(h.opt_num_reps,  'String')); %#ok<ST2NM>
p.OPTIONS.trialfunc          = get(h.trial_selectfunc,      'String');
p.OPTIONS.optcontrol         = get(h.opt_optcontrol,        'Value');
p.INFO                       = get(h.protocol_info,         'String');





function OpTcontrol(hObj,h)
if get(hObj,'Value')
    set([h.opt_num_reps, h.opt_iti],'Enable','off'); 
else
    set([h.opt_num_reps, h.opt_iti],'Enable','on');
end























%% Table
function param_table_CellEditCallback(hObj, evnt, h) %#ok<DEFNU>
GUISTATE(h.ProtocolDesign,'off');

I = evnt.Indices;
row = I(1);
col = I(2);

curmod = get_string(h.module_select);

data = get(hObj,'data');

if col == 1 && evnt.NewData(1) == '$'
    set(h.opt_compile_at_runtime,'Value',1);
    
elseif col == 3 && strcmp(evnt.NewData,'< ADD >')
    % Add new Buddy variable
    nd = inputdlg('Enter new Buddy:','Buddy Variable');
    if isempty(nd)
        data{row,col} = '< NONE >';
        set(hObj,'data',data);
        GUISTATE(h.ProtocolDesign,'on');
        return
    end
    cf = get(hObj,'ColumnFormat');
    od = cf{3};
    
    if ~ismember(nd,od)
        od = sort({char(nd) od{:}}); %#ok<CCAT,FLPST>
        cf{3} = fliplr(od);
        set(hObj,'ColumnFormat',cf);
        data{row,3} = char(nd);
    end
    
elseif col == 4
    if length(str2num(data{row,4})) ~= 2 %#ok<ST2NM>
        data{row,5} = false;
    end
%     data{row,6} = false;
%     if isfield(h.protocol.MODULES.(get_string(h.module_select)),'buffers') ...
%         && row <= length(h.protocol.MODULES.(get_string(h.module_select)).buffers)
%         h.protocol.MODULES.(get_string(h.module_select)).buffers(row) = [];
%     end
    
elseif col == 5
    if ~isempty(evnt.Error), data{row,col} = evnt.EditData; end
    if length(str2num(data{row,4})) ~= 2 %#ok<ST2NM>
        data{row,5} = false;
        helpdlg(['Random option only available when a range is specified in ''Values'' field.  ', ...
            'Range is defined by two values such as: ''2 6'''], ...
            'Parameter Table');
    end
    
elseif col == 6 % wav files
    if data{row,6}
        %         S = get(h.param_table,'UserData');
        uiwait(SchedWAVgui(h.ProtocolDesign,[]))
        S = getappdata(h.ProtocolDesign,'SchedWAVgui_DATA');
        h.protocol.MODULES.(curmod).buffers{row} = S;
        if isempty(S)
            data{row,4} = '';
            data{row,5} = false;
            data{row,6} = false;
        else
            data{row,2} = 'Write';
            data{row,4} = ['FILE IDs: ' mat2str(1:length(S))];
            data{row,5} = false;
            data{row,6} = true;
        end
    else
        data{row,4} = '';
    end
    
    
    
elseif col == 7 && ~strcmp(evnt.NewData,'< NONE >')
    % Select calibration file from Calibration directory
    dd = getpref('ProtocolDesign','CALDIR',cd);
    if ~ischar(dd), dd = cd; end % this may happen
    
    [fn,dd] = uigetfile({'*.cal','Calibration (*.cal)'}, ...
        'Select a Calibration',dd);
    
    if ~fn
        data{row,7} = '< NONE >';
        h.protocol.MODULES.(curmod).calibrations{row} = [];
    else
        % update data cell matrix with filename
        data{row,7} = fn;
        calfn = fullfile(dd,fn);
        h.protocol.MODULES.(curmod).calibrations{row} = load(calfn,'-mat');
        h.protocol.MODULES.(curmod).calibrations{row}.filename = calfn;
        setpref('ProtocolData','CALDIR',dd);
    end
end
set(hObj,'Data',data);

% store protocol data
v = cellstr(get(h.module_select,'String'));
v = v{get(h.module_select,'Value')};
h.protocol.MODULES.(v).data = get(hObj,'Data');
UpdateProtocolDur(h);
guidata(h.ProtocolDesign,h);
GUISTATE(h.ProtocolDesign,'on');


function param_table_CellSelectionCallback(hObj, evnt, h) %#ok<DEFNU>
h.CURRENTCELL = evnt.Indices;
guidata(h.ProtocolDesign,h);

% make sure we always have an extra row for new parameter
data = get(hObj,'data');

if ~isempty(h.CURRENTCELL) && h.CURRENTCELL(2) == 4 ...
        && data{h.CURRENTCELL(1),6} % check if WAV files
    uiwait(helpdlg('This field should not be edited when using WAV files'));
end

k = find(~ismember(1:size(data,1),findincell(data(:,1)))); %#ok<EFIND>

if ~isfield(h,'PA5flag'), h.PA5flag = 0; end
if isempty(k) && ~h.PA5flag
    data(end+1,:) = dfltrow;
    set(hObj,'data',data);
end

function trial_selectfunc_Callback(hObj, evnt, h) %#ok<INUSD,DEFNU>
cfunc = get(hObj,'String');
if ~exist(cfunc,'file')
    errordlg(sprintf('The function ''%s'' was not found on MATLAB''s search path.',cfunc), ...
        'Custom Trial Selection');
    set(hObj,'String','< default >');
end

function SetParamTable(h,protocol)
% Updates parameter table with protocol data

v = get(h.module_select,'String');
v = v{get(h.module_select,'Value')};
if isempty(protocol) || ~isfield(protocol.MODULES,v)
    d = dfltrow;
else
    d = protocol.MODULES.(v).data;
end

if ~isfield(h,'PA5flag'),   h.PA5flag = 0;  end

if h.PA5flag, d{1} = 'SetAtten'; end
ce = true(size(dfltrow));

ce([1 end-1 end]) = ~h.PA5flag;

set(h.param_table,'ColumnEditable',ce,'Data',d);



function d = dfltrow
% default row definition
d = {'' 'Write/Read' '< NONE >' '' false false '< NONE >'};

function view_compiled_Callback(h) %#ok<DEFNU>
if ~isfield(h,'protocol'), return; end
% GUISTATE(h.ProtocolDesign,'off');
h.protocol = AffixOptions(h,h.protocol);
ep_CompiledProtocolTrials(h.protocol,'trunc',2000);
GUISTATE(h.ProtocolDesign,'on');



























%% GUI Callbacks
function opt_num_reps_Callback(hObj, h) %#ok<DEFNU>
% Check number of repetitions
d = get(hObj,'String');
d = str2num(d); %#ok<ST2NM>
if length(d) ~= 1
    warndlg('Number of repetitions must be a scalar value','Bad Value');
    if isempty(d), d = 5; end
    set(hObj,'String',num2str(d(1)));
end
UpdateProtocolDur(h)

function opt_iti_Callback(hObj, h) %#ok<DEFNU>
% Check inter-stimulus interval (ISI)
d = get(hObj,'String');
d = str2num(d); %#ok<ST2NM>
if length(d) < 1 || length(d) > 2
    warndlg('Number of repetitions must be a scalar value for constant ISI or two values for random interval','Bad Value');
    if isempty(d), d = 300; end
    set(hObj,'String',num2str(d(1)));
end
UpdateProtocolDur(h)

function UpdateProtocolDur(h)
if ~isfield(h,'protocol')
    set(h.protocol_dur,'String','Protocol Duration:');
    return
end

iti = str2num(get(h.opt_iti,'String')); %#ok<ST2NM>

h.protocol = AffixOptions(h,h.protocol);
[p,fail] = ep_CompiledProtocolTrials(h.protocol,'showgui',false);
if fail
    set(h.protocol_dur,'String','Invalid Value Combinations', ...
        'backgroundcolor','r');
else
    pdur = mean(size(p.trials,1)*iti/1000/60);
    set(h.protocol_dur,'String',sprintf('Protocol Duration: %0.1f min',pdur), ...
        'backgroundcolor','g');
end




function remove_parameter_Callback(h) %#ok<DEFNU>
% Remove currently selected parameter from table
if ~isfield(h,'CURRENTCELL') || isempty(h.CURRENTCELL), return; end
row = h.CURRENTCELL(1);

data = get(h.param_table,'data');
data(row,:) = [];
set(h.param_table,'data',data);

v = get_string(h.module_select);
h.protocol.MODULES.(v).data = data;

if isfield(h.protocol.MODULES.(v),'buffers') && row <= length(h.protocol.MODULES.(v).buffers)
    h.protocol.MODULES.(v).buffers(row) = [];
end

if isfield(h.protocol.MODULES.(v),'calibrations') && row <= length(h.protocol.MODULES.(v).calibrations)
    h.protocol.MODULES.(v).calibrations(row) = [];
end

h.CURRENTCELL = [];
guidata(h.ProtocolDesign,h);

function module_select_Callback(hObj, h)
% handles module selection
if ~isfield(h,'protocol'), h.protocol = []; end

v = cellstr(get(hObj,'String'));
if isempty(v) || isempty(v{1})
    add_module_Callback(h)
    return
end

v = v{get(hObj,'Value')};
if strfind(v,'PA5')
    h.PA5flag = true;
else
    h.PA5flag = false;
end
guidata(h.ProtocolDesign,h);

SetParamTable(h,h.protocol);

function add_module_Callback(h)
% add new module to protocol
ov = cellstr(get(h.module_select,'String'));

options.Resize = 'off';
options.WindowStyle = 'modal';
nv = inputdlg('Enter an alias for the hardware module (case sensitive):', ...
    'Hardware Alias',1,{'Stim'},options);
if isempty(nv), return; end

ov(~ismember(1:length(ov),findincell(ov))) = [];

if ~ismember(nv,ov)
    ov{end+1} = char(nv);
    %     ov = sort(ov);
end

h.PA5flag = strfind(char(nv),'PA5'); % PA5 attenuation module
if isempty(h.PA5flag), h.PA5flag = false; end
if h.PA5flag
    data = dfltrow;
    data{1} = 'SetAtten';
    set(h.param_table,'Data',data);
end
guidata(h.ProtocolDesign,h);

set(h.module_select,'String',ov,'Value',find(ismember(ov,nv)));
set(h.param_table,'Enable','on');


% Associate RPvds File with module if not using OpenEx
if ~h.UseOpenEx && ~h.PA5flag
    [rpfn,rppn] = uigetfile('*.rcx','Associate RPvds File');
    if ~rpfn, return; end
    RPfile = fullfile(rppn,rpfn);
    h = rpvds_tags(h,RPfile);
end

% TO DO: PROMPT TO ASSOCIATE HARDWARE MODULE, MODULE ID, SAMPLING RATE

if isempty(ov)
    splash('on');
else
    splash('off');
end

module_select_Callback(h.module_select, h);


function remove_module_Callback(h) %#ok<DEFNU>
% remove selected module from protocol
ov  = cellstr(get(h.module_select,'String'));
idx = get(h.module_select,'Value');
v = ov{idx};

r = questdlg( ...
    sprintf('Are you certain you would like to remove the ''%s'' module?',v), ...
    'Remove Module','Yes','No','No');

if strcmp(r,'No'), return; end

if isempty(h.protocol) 
    guidata(h.ProtocolDesign,h);
elseif isfield(h.protocol.MODULES,v)
    h.protocol.MODULES = rmfield(h.protocol.MODULES,v);
    guidata(h.ProtocolDesign,h);
end

ov(idx) = [];
set(h.module_select,'String',ov,'Value',1);

if isempty(ov), set(h.param_table,'Enable','off'); end

module_select_Callback(h.module_select, h);

function h = rpvds_tags(h,RPfile)
if strcmp(get(h.param_table,'Enable'),'off'), return; end

GUISTATE(h.ProtocolDesign,'off');

% Grab parameter tags from an existing RPvds file
fh = findobj('Type','figure','-and','Name','RPfig');
if isempty(fh), fh = figure('Visible','off','Name','RPfig'); end

if nargin == 1
    [fn,pn] = uigetfile({'*.rcx', 'RPvds File (*.rcx)'},'Select RPvds File');
    if ~fn, GUISTATE(h.ProtocolDesign,'on'); return; end
    RPfile = fullfile(pn,fn);
end

RP = actxcontrol('RPco.x','parent',fh);
RP.ReadCOF(RPfile);

data = dfltrow;
k = 1;
n = RP.GetNumOf('ParTag');
for i = 1:n
    x = RP.GetNameOf('ParTag', i);
    % remove any error messages and OpenEx proprietary tags (starting with 'z')
    if ~(any(ismember(x,'/\|')) || ~isempty(strfind(x,'rPvDsHElpEr')) ...
            || any(x(1) == 'zZ') || any(x(1) == '~#'))
        data(k,:) = dfltrow;
        data{k,1} = x;
        k = k + 1;
    end
end

data = sortrows(data,1);

delete(RP);
close(fh);

set(h.param_table,'data',data)

v = cellstr(get(h.module_select,'String'));
v = v{get(h.module_select,'Value')};
h.protocol.MODULES.(v).data = data;
h.protocol.MODULES.(v).RPfile = RPfile;
guidata(h.ProtocolDesign,h);
GUISTATE(h.ProtocolDesign,'on');




function mnu_conntype_Callback(h,ctype) %#ok<DEFNU>
if strcmp(ctype,'usb');
    set(h.mnu_usb,'Checked','on');
    set(h.mnu_gb,'Checked','off');
    
else
    set(h.mnu_usb,'Checked','off');
    set(h.mnu_gb,'Checked','on');
end

fprintf('Connection type: \t%s\n',upper(ctype))
    
    
    




    
