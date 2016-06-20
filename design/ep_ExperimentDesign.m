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
    [~,~,fext] = fileparts(varargin{1});
    if ~strcmp(fext,'.prot')
        gui_State.gui_Callback = str2func(varargin{1});
    end
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

function ep_ExperimentDesign_OpeningFcn(hObj, ~, h, varargin)
global PRGMSTATE

h.output = hObj;

h.CURRENT_BOX_IDX = [];
set(h.mnu_UpdateRunningExpt,'Enable','off');

if nargin > 3
    % Load schedule file passed into varargin{1}
    protocol = LoadProtocolFile(h,varargin{1});
    if ~isempty(protocol)
        h = guidata(hObj);
        set(h.param_table,'Data',protocol.MODULES.(getcurrentmod(h)).data);
        
        if length(varargin) > 1
            h.CURRENT_BOX_IDX = varargin{2};
        end
        guidata(hObj, h);

        if strcmp(PRGMSTATE,'RUNNING')
            set(h.mnu_UpdateRunningExpt,'Enable','on', ...
                'TooltipString',sprintf('Update Protocol for Experiment Running in Box %d',h.CURRENT_BOX_IDX));
        end
    end
else
    NewProtocolFile(h);
    set(h.param_table,'Data',dfltrow);
end

UpdateProtocolDur(h);





function varargout = ep_ExperimentDesign_OutputFcn(hObj, ~, h)  %#ok<INUSL>
varargout{1} = h.output;













%% Runtime functions
function UpdateRunningProtocol(h) %#ok<DEFNU>
% Update protocol values during the experiment.  
% This will not save over the protocol file.
% 
% DJS 3/2016

global CONFIG RUNTIME PRGMSTATE


if isempty(h.CURRENT_BOX_IDX) || ~strcmp(PRGMSTATE,'RUNNING')
    set(h.mnu_UpdateRunningExpt,'Enable','off');
    return
end

CIDX = h.CURRENT_BOX_IDX;

vprintf(0,'Attempting to update the protocol for currently running box %d ...',CIDX);

protocol = h.protocol;
if isfield(protocol,'COMPILED')
    protocol = rmfield(protocol,'COMPILED');
end

% trim any undefined parameters
fldn = fieldnames(protocol.MODULES);
for i = 1:length(fldn)
    v = protocol.MODULES.(fldn{i}).data;
    v(~ismember(1:size(v,1),findincell(v(:,1))),:) = [];
    protocol.MODULES.(fldn{i}).data = v;
end

protocol = AffixOptions(h,protocol);
[protocol,fail] = ep_CompileProtocol(protocol);

if fail
    vprintf(0,1,'Failed to recompile the protocol!  No parameters have been updated.');
    return
end

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

CONFIG(CIDX).PROTOCOL = protocol;

C = CONFIG(CIDX).PROTOCOL.COMPILED;
RUNTIME.TRIALS(CIDX).trials = C.trials;
RUNTIME.TRIALS(CIDX).readparams = C.readparams;
RUNTIME.TRIALS(CIDX).Mreadparams = cellfun(@ModifyParamTag, ...
    RUNTIME.TRIALS(CIDX).readparams,'UniformOutput',false);
RUNTIME.TRIALS(CIDX).writeparams = C.writeparams;
RUNTIME.TRIALS(CIDX).randparams = C.randparams;

RUNTIME.TRIALS(CIDX).TrialCount = zeros(size(C.trials,1),1); % reset trial count

vprintf(0,'Protocol update successful!')





%% Protocol Setup
function SaveProtocolFile(h,fn)
% Save current protocol to file
if ~exist('fn','var') || isempty(fn)
    pn = getpref('PSYCH','ProtDir',cd);
    if ~ischar(pn), pn = cd; end
    [fn,pn] = uiputfile({'*.prot','Protocol File (*.prot)'}, ...
        'Save Protocol File',pn);
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

save(fn,'protocol','-mat','-v7.3');

setpref('PSYCH','ProtDir',pn);

GUISTATE(h.ProtocolDesign,'on');
set(h.ProtocolDesign,'Name','Protocol Design');
fprintf(' done\nFile Location: ''%s''\n',fn);

function GUISTATE(fh,onoff)
% Disable/Enable GUI components and set pointer state
pdchildren = findobj(fh,'-property','Enable');
set(pdchildren,'Enable',onoff);

drawnow

function r = NewProtocolFile(h)
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
set(h.trial_selectfunc,'String','< default >');
set(h.protocol_dur,'String','','BackgroundColor',get(h.ProtocolDesign,'Color'));
set(h.protocol_info,'String','');

splash('on');

h.protocol = [];


guidata(h.ProtocolDesign,h);

function splash(onoff)
h = findobj('tag','pdsplash');
if isequal(onoff,'on')
    set(h,'visible','on');
else
    set(h,'visible','off');
end

function protocol = LoadProtocolFile(h,ffn)
% Load previously saved protocol from file
protocol = [];

r = NewProtocolFile(h);
if strcmp(r,'Cancel'), return; end

if ~exist('ffn','var') || isempty(ffn) || ~exist(ffn,'file')
    pn = getpref('PSYCH','ProtDir',cd);
    if isequal(pn,0), pn = cd; end
    [fn,pn] = uigetfile({'*.prot','Protocol File (*.prot)'},'Locate Protocol File',pn);
    if ~fn, return; end
    ffn = fullfile(pn,fn);
else
    [pn,~] = fileparts(ffn);
end


set(h.ProtocolDesign,'Name','Protocol Design: Loading ...');
GUISTATE(h.ProtocolDesign,'off');

warning('off','MATLAB:dispatcher:UnresolvedFunctionHandle');
load(ffn,'protocol','-mat'); % contains 'protocol' structure
warning('on','MATLAB:dispatcher:UnresolvedFunctionHandle');

if ~exist('protocol','var')
    error('ProtocolDesign:Unknown protocol file data');
end

set(h.lbl_fileinfo,'String',ffn)

P = protocol;

if ~isfield(P.OPTIONS,'UseOpenEx') % probably old protocol file
    P.OPTIONS.UseOpenEx = true;
end
h.UseOpenEx = P.OPTIONS.UseOpenEx;

if ~isfield(P.OPTIONS,'IncludeWAVBuffers')
    P.OPTIONS.IncludeWAVBuffers = 'on';
end
set(h.Include_WAV_Buffers,'Checked',P.OPTIONS.IncludeWAVBuffers);

guidata(h.ProtocolDesign,h);

if h.UseOpenEx
    set(h.lbl_useOpenEx,'String','Using OpenEx','ForegroundColor','b');
else
    set(h.lbl_useOpenEx,'String','Not using OpenEx','ForegroundColor','k');
end

if ~isfield(P.OPTIONS,'ConnectionType') % probably old protocol file
    P.OPTIONS.ConnectionType = 'GB';
end

if strcmp(P.OPTIONS.ConnectionType,'GB')
    set(h.mnu_gb,'checked','on');
    set(h.mnu_usb,'checked','off');
else
    set(h.mnu_gb,'checked','off');
    set(h.mnu_usb,'checked','on');
end

% Populate module list
mfldn = fieldnames(P.MODULES);
if h.UseOpenEx
    fldn = mfldn;
    i = 1;
else
    for i = 1:length(mfldn)
        fldn{i} = sprintf('%s (%s_%d)',mfldn{i}, ...
            P.MODULES.(mfldn{i}).ModType, ...
            P.MODULES.(mfldn{i}).ModIDX); %#ok<AGROW>
    end    
end
obj = findobj(h.ProtocolDesign,'tag','module_select');
set(obj,'String',fldn,'Value',i);
if strcmpi(mfldn{i}(1:3),'PA5')
    set(obj,'TooltipString','Programmable Attenuator (no RPvds file)');
else
    set(obj,'TooltipString',P.MODULES.(mfldn{i}).RPfile);
end

% Ensure all buddy variables are accounted for
n = {'< ADD >','< NONE >'};
for i = 1:length(fldn)
    if h.UseOpenEx  
        n = union(n,P.MODULES.(fldn{i}).data(:,3));
    else
        n = union(n,P.MODULES.(fldn{i}(1:find(fldn{i}==' ',1)-1)).data(:,3));
    end
end
cf = get(h.param_table,'ColumnFormat');
cf{3} = n(:)';
set(h.param_table,'ColumnFormat',cf);

if isfield(P,'TABLEDATA')
    TD = P.TABLEDATA;
else
    TD = [];
end
set(h.param_table,'UserData',TD);

% Populate options
Op = P.OPTIONS;
set(h.opt_randomize,         'Value',   Op.randomize);
if Op.compile_at_runtime
    set(h.opt_compile_at_runtime,'Checked','on');
else
    set(h.opt_compile_at_runtime,'Checked','off');
end
set(h.opt_iti,               'String',  num2str(Op.ISI));
set(h.opt_num_reps,          'String',  num2str(Op.num_reps));

if isfield(Op,'optcontrol')
    set(h.opt_optcontrol,'Value',Op.optcontrol);
end
h.protocol = P;
% OpTcontrol(h.opt_optcontrol,h);

if isfield(Op,'trialfunc')
    set(h.trial_selectfunc,'String',Op.trialfunc);
else
    set(h.trial_selectfunc,'String','< default >');
end
set(h.protocol_info,'String',P.INFO);

set(h.param_table,'Enable','on');
splash('off');
h.protocol = P;
guidata(h.ProtocolDesign,h);

setpref('PSYCH','ProtDir',pn);

module_select_Callback(h.module_select, h);

UpdateProtocolDur(h);

set(h.ProtocolDesign,'Name','Protocol Design');
GUISTATE(h.ProtocolDesign,'on');

h.CURRENT_BOX_IDX = [];
set(h.mnu_UpdateRunningExpt,'Enable','off');


function p = AffixOptions(h,p)
% affix protocol options
p.OPTIONS.randomize          = get(h.opt_randomize,         'Value');
p.OPTIONS.compile_at_runtime = strcmp(get(h.opt_compile_at_runtime,'Checked'),'on');
p.OPTIONS.ISI                = str2num(get(h.opt_iti,       'String')); %#ok<ST2NM>
p.OPTIONS.num_reps           = str2num(get(h.opt_num_reps,  'String')); %#ok<ST2NM>
p.OPTIONS.trialfunc          = get(h.trial_selectfunc,      'String');
p.OPTIONS.optcontrol         = get(h.opt_optcontrol,        'Value');
p.OPTIONS.UseOpenEx          = h.UseOpenEx;
p.OPTIONS.ConnectionType     = getconntype(h);
p.OPTIONS.IncludeWAVBuffers  = get(h.Include_WAV_Buffers,   'Checked');
p.INFO                       = get(h.protocol_info,         'String');


% function OpTcontrol(hObj,h)
% if get(hObj,'Value')
%     set([h.opt_num_reps, h.opt_iti],'Enable','off'); 
%     set(h.opt_num_reps,'String',inf);
% else
%     set([h.opt_num_reps, h.opt_iti],'Enable','on');
% end
% UpdateProtocolDur(h);
















%% Table
function param_table_CellEditCallback(hObj, evnt, h) %#ok<DEFNU>
GUISTATE(h.ProtocolDesign,'off');

I = evnt.Indices;
row = I(1);
col = I(2);

curmod = getcurrentmod(h);

data = get(hObj,'data');

if col == 1 && isempty(evnt.NewData)
    warndlg('Variable must have a name!','ep_ExperimentDesign','modal');
    data{row,col} = evnt.PreviousData;
    set(hObj,'data',data);
    GUISTATE(h.ProtocolDesign,'on');
    return
end

if col == 1 && evnt.NewData(1) == '$'
    set(h.opt_compile_at_runtime,'Checked','on');
    
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
        uiwait(ep_SchedWAVgui(h.ProtocolDesign,[]))
        S = getappdata(h.ProtocolDesign,'ep_SchedWAVgui_DATA');
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
        warning('off','MATLAB:dispatcher:UnresolvedFunctionHandle');
        h.protocol.MODULES.(curmod).calibrations{row} = load(calfn,'-mat');
        warning('on','MATLAB:dispatcher:UnresolvedFunctionHandle');
        h.protocol.MODULES.(curmod).calibrations{row}.filename = calfn;
        setpref('ProtocolData','CALDIR',dd);
    end
end
set(hObj,'Data',data);

% store protocol data
h.protocol.MODULES.(curmod).data = get(hObj,'Data');
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
    
elseif nargin(cfunc) ~= 1 || nargout(cfunc) ~= 1
    errordlg(['The trial selection function must accept one input (TRIALS structure) ', ...
        'return one output (a scalar value with the next trial index, or the entire TRIALS structure)']);
    set(hObj,'String','< default >');
    
end

function SetParamTable(h,protocol)
% Updates parameter table with protocol data
v = getcurrentmod(h);

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

function v = getcurrentmod(h)
v = get(h.module_select,'String');
if isempty(v), return; end
v = v{get(h.module_select,'Value')};
if ~h.UseOpenEx
    v = v(1:find(v==' ',1)-1);
end

function d = dfltrow
% default row definition
d = {'' 'Write/Read' '< NONE >' '' false false '< NONE >'};

function view_compiled_Callback(h) %#ok<DEFNU>
if ~isfield(h,'protocol') || isempty(h.protocol), return; end
GUISTATE(h.ProtocolDesign,'off');
h.protocol = AffixOptions(h,h.protocol);
ep_CompiledProtocolTrials(h.protocol,'trunc',1000);
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
    str = 'Invalid Value Combinations';
    clr = 'r';
else
    ntr = size(p.trials,1);
%     if ntr>0 && get(h.opt_optcontrol,'Value')
%         str = sprintf('%d unique trials',ntr);
%         clr = 'g';
%     elseif ntr>0 && ~get(h.opt_optcontrol,'Value')
%         pdur = mean(ntr*iti/1000/60);
%         str  = sprintf('Protocol Duration: %0.1f min',pdur);
%         clr = 'g';
    if ntr>0
        pdur = mean(ntr*iti/1000/60);
        str  = sprintf('Protocol Duration: %0.1f min',pdur);
        clr = 'g';
    else
        str = 'Incomplete Trial Definitions';
        clr = 'y';
    end
end
set(h.protocol_dur,'String',str,'backgroundcolor',clr, ...
    'HorizontalAlignment','center');

function remove_parameter_Callback(h) %#ok<DEFNU>
% Remove currently selected parameter from table
if ~isfield(h,'CURRENTCELL') || isempty(h.CURRENTCELL), return; end
row = h.CURRENTCELL(:,1);

data = get(h.param_table,'data');
data(row,:) = [];
set(h.param_table,'data',data);

v = getcurrentmod(h);
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

v = get_string(hObj);
if isempty(v)
    add_module_Callback(h)
    return
end

h.PA5flag = ~isempty(strfind(v,'PA5')); % keep this as STRFIND

mfn = fieldnames(h.protocol.MODULES);
for i = 1:length(mfn)
    if ~isempty(strfind(v,char(mfn{i}))), break; end
end

if h.PA5flag
    set(hObj,'TooltipString','PA5 Module (no RPvds)')
    set(h.lblCurrentRPvdsFile,'String','PA5 Module (no RPvds)', ...
        'TooltipString','PA5 Module (no RPvds)');
else
    
    if ~isfield(h.protocol.MODULES.(mfn{i}),'RPfile') || isempty(h.protocol.MODULES.(mfn{i}).RPfile)
        set(hObj,'TooltipString','[No RPvds File was Chosen]')
        set(h.lblCurrentRPvdsFile,'String','[No RPvds File was Chosen]', ...
            'TooltipString','[No RPvds File was Chosen]');
    else
        set(hObj,'TooltipString',h.protocol.MODULES.(mfn{i}).RPfile)
        [~,fn,fext] = fileparts(h.protocol.MODULES.(mfn{i}).RPfile);
        set(h.lblCurrentRPvdsFile,'String',[fn fext], ...
            'TooltipString',h.protocol.MODULES.(mfn{i}).RPfile);
    end
end
    
guidata(h.ProtocolDesign,h);

SetParamTable(h,h.protocol);




function UpdateModuleInfo(~, h, s) %#ok<DEFNU>

i = get(h.module_select,'Value');
if isempty(i) || ~isfield(h,'protocol'), return; end

ov = get_string(h.module_select);
if ~h.UseOpenEx
    idx = find(ov==' ',1);
    ov = ov(1:idx-1);
end

switch s
    case 'alias'
        % Module Alias
        options.Resize = 'off';
        options.WindowStyle = 'modal';
        nv = inputdlg('Enter an alias for the hardware module (case sensitive):', ...
            'Hardware Alias',1,{ov},options);
        if isempty(nv), return; end
        nv = char(nv);
        h.protocol.MODULES.(nv) = h.protocol.MODULES.(ov);
        h.protocol.MODULES = rmfield(h.protocol.MODULES,ov);
        
    case 'type'
        % Module Type
        if h.UseOpenEx
            msgbox(['This protocol is currently designed to work in conjunction with OpenEx. ', ...
                'The module type can be changed in the OpenEx Workbench.'], ...
                'Change Module Type','help','modal');
            return
        end
        
        modlist = {'RM1','RM2','RP2','RX5','RX6','RX7','RX8','RZ2','RZ5','RZ6'};
        [sel,ok] = listdlg('ListString',modlist,'SelectionMode','single', ...
            'Name','EPsych','PromptString','Select TDT Module');
        if ~ok, return; end
        ModType = modlist{sel};
        [ModIDX,ok] = listdlg('ListString',cellstr(num2str((1:10)')),'SelectionMode','single', ...
            'Name','EPsych','PromptString','Select module index');
        if ~ok, return; end
        h.protocol.MODULES.(ov).ModType = ModType;
        h.protocol.MODULES.(ov).ModIDX  = ModIDX;
        nv = ov;
        
        
    case 'rpvds'
        % RPvds file
        if h.UseOpenEx
            msgbox(['This protocol is currently designed to work in conjunction with OpenEx. ', ...
                'The RPvds file can be changed in the OpenEx Workbench.'], ...
                'Change Module Type','help','modal');
            return
        end
        [rpfn,rppn] = uigetfile('*.rcx','Associate RPvds File');
        if ~rpfn, return; end
        RPfile = fullfile(rppn,rpfn);
        h.protocol.MODULES.(ov).RPfile  = RPfile;
        nv = ov;
        
end



v = get(h.module_select,'String');
if h.UseOpenEx
    v{i} = nv;
else
    v{i} = sprintf('%s (%s_%d)',nv,h.protocol.MODULES.(nv).ModType,h.protocol.MODULES.(nv).ModIDX);
end
set(h.module_select,'String',v,'Value',i);

guidata(h.ProtocolDesign,h);

module_select_Callback(h.module_select,h);




function add_module_Callback(h)

% add new module to protocol
ov = cellstr(get(h.module_select,'String'));

% Prompt if OpenEx will be used
if ~isempty(ov) && isempty(ov{1})
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

options.Resize = 'off';
options.WindowStyle = 'modal';
nv = inputdlg('Enter an alias for the hardware module (case sensitive):', ...
    'Hardware Alias',1,{'Stim'},options);
if isempty(nv), return; end
nv = char(nv);

ov(~ismember(1:length(ov),findincell(ov))) = [];

set(h.param_table,'Enable','on');

% Associate RPvds File with module if not using OpenEx
if h.UseOpenEx
    h.PA5flag = strfind(nv,'PA5'); % PA5 attenuation module
    if isempty(h.PA5flag), h.PA5flag = false; end
    if h.PA5flag
        data = dfltrow;
        data{1} = 'SetAtten';
        set(h.param_table,'Data',data);
    end

else   
    modlist = {'RM1','RM2','RP2','RX5','RX6','RX7','RX8','RZ2','RZ5','RZ6','PA5'};
    [sel,ok] = listdlg('ListString',modlist,'SelectionMode','single', ...
        'Name','EPsych','PromptString','Select TDT Module');
    if ~ok, return; end
    ModType = modlist{sel};
    
    [ModIDX,ok] = listdlg('ListString',cellstr(num2str((1:10)')),'SelectionMode','single', ...
        'Name','EPsych','PromptString','Select module index');
    if ~ok, return; end
    
    h.PA5flag = strcmp(ModType,'PA5');
    
    if h.PA5flag
        RPfile = '';
    else
        [rpfn,rppn] = uigetfile('*.rcx','Associate RPvds File');
        if ~rpfn, return; end
        RPfile = fullfile(rppn,rpfn);
    end
    
    nv = sprintf('%s (%s_%d)',nv,ModType,ModIDX);

end

if ~ismember(nv,ov), ov{end+1} = nv; end
set(h.module_select,'String',ov,'Value',find(ismember(ov,nv)));

if ~h.UseOpenEx
    v = getcurrentmod(h);
    if h.PA5flag
        h.protocol.MODULES.(v).data = dfltrow;
    else
        h = rpvds_tags(h,RPfile);
    end
    h.protocol.MODULES.(v).ModType = ModType;
    h.protocol.MODULES.(v).ModIDX  = ModIDX;
    
elseif ~h.PA5flag
    b = questdlg('Read parameter tags from existing RPvds file?','EPsych','Yes','No','Yes');
    if strcmp(b,'Yes')
        [rpfn,rppn] = uigetfile('*.rcx','Associate RPvds File');
        if ~rpfn, return; end
        RPfile = fullfile(rppn,rpfn);
        h = rpvds_tags(h,RPfile);
    else
        RPfile = [];
    end
end

splash('off');

set(h.remove_module,'Enable','on');
set(h.param_table,'Enable','on');

guidata(h.ProtocolDesign,h);

module_select_Callback(h.module_select, h);

function remove_module_Callback(h) %#ok<DEFNU>
% remove selected module from protocol
ov  = cellstr(get(h.module_select,'String'));
idx = get(h.module_select,'Value');

v = getcurrentmod(h);

if isempty(v), return; end

r = questdlg( ...
    sprintf('Are you certain you would like to remove the ''%s'' module?',v), ...
    'Remove Module','Yes','No','No');

if strcmp(r,'No'), return; end

if ~isempty(h.protocol) && isfield(h.protocol.MODULES,v)
    h.protocol.MODULES = rmfield(h.protocol.MODULES,v);
end


ov(idx) = [];
set(h.module_select,'String',ov,'Value',1);

if isempty(ov)
    set(h.param_table,'Data',dfltrow);
    set(h.remove_module,'Enable','off');
    set(h.param_table,'Enable','off');
end

guidata(h.ProtocolDesign,h);

module_select_Callback(h.module_select, h);

function h = rpvds_tags(h,RPfile)
if strcmp(get(h.param_table,'Enable'),'off'), return; end

GUISTATE(h.ProtocolDesign,'off');

if nargin == 1
    [fn,pn] = uigetfile({'*.rcx', 'RPvds File (*.rcx)'},'Select RPvds File');
    if ~fn, GUISTATE(h.ProtocolDesign,'on'); return; end
    RPfile = fullfile(pn,fn);
end

fprintf('Reading parameter tags from RPvds file:\n\t%s\n',RPfile)

% Grab parameter tags from an existing RPvds file
fh = findobj('Type','figure','-and','Name','RPfig');
if isempty(fh), fh = figure('Visible','off','Name','RPfig'); end

RP = actxcontrol('RPco.x','parent',fh);
RP.ReadCOF(RPfile);

data = dfltrow;
k = 1;
n = RP.GetNumOf('ParTag');
for i = 1:n
    x = RP.GetNameOf('ParTag', i);
    % remove any error messages and OpenEx proprietary tags (starting with 'z')
    if ~(any(any(x(1) == 'zZ~%#!') || any(ismember(x,'/\|')) ...
            || any(ismember(x,{'InitScript','TrigState','ResetTrigState','rPvDsHElpEr'}))))
        data(k,:) = dfltrow;
        data{k,1} = x;
        k = k + 1;
    end
end

data = sortrows(data,1);

delete(RP);
close(fh);

set(h.param_table,'data',data)

v = getcurrentmod(h);
h.protocol.MODULES.(v).data = data;
h.protocol.MODULES.(v).RPfile = RPfile;
guidata(h.ProtocolDesign,h);
GUISTATE(h.ProtocolDesign,'on');

fprintf('done\n')

function mnu_conntype_Callback(h,ctype) %#ok<DEFNU>
if strcmp(ctype,'usb');
    set(h.mnu_usb,'Checked','on');
    set(h.mnu_gb,'Checked','off');
    
else
    set(h.mnu_usb,'Checked','off');
    set(h.mnu_gb,'Checked','on');
end

fprintf('Connection type: \t%s\n',upper(ctype))
    
    

function ct = getconntype(h)
if strcmpi(get(h.mnu_gb,'checked'),'on')
    ct = 'GB';
else
    ct = 'USB';
end

function MenuCheck(hObj,h) %#ok<INUSD,DEFNU>
item = get(hObj,'tag');
c = get(hObj,'Checked');
if strcmp(c,'on')
    set(hObj,'Checked','off');
    switch item
        case 'Include_WAV_Buffers'
            fprintf('Include WAV Buffers option: ''off''\n')
            fprintf(2,'* NOTE: Experiment will look to original WAV file locations for buffers.\n') %#ok<PRTCAL>
    end
else
    set(hObj,'Checked','on');
    switch item
        case 'Include_WAV_Buffers'    
            fprintf('Include WAV Buffers option: ''on''\n')
    end
end

    




    
function FindAndReplace(h) %#ok<DEFNU>
data = get(h.param_table,'Data');
if isempty(data{1}), return; end

options.WindowStyle = 'modal';
options.Interpreter = 'none';
a = inputdlg({'Enter string to find:','Enter replacement string:'},'Find&Replace', ...
    1,{'',''},options);
if isempty(a) || isempty(a{1}), return; end

n = size(data,1);

i = cellfun(@strfind,data(:,1),repmat(a(1),n,1),'UniformOutput',false);
i = numel(findincell(i));

if i == 0
    msgbox(sprintf('No instances of ''%s'' were found on this module.',a{1}), ...
        'Find&Replace','help','modal');
    return
end

data(:,1) = cellfun(@strrep,data(:,1),repmat(a(1),n,1),repmat(a(2),n,1),'UniformOutput',false);

set(h.param_table,'Data',data);
curmod = getcurrentmod(h);
h.protocol.MODULES.(curmod).data = data;
UpdateProtocolDur(h);
guidata(h.ProtocolDesign,h);

msgbox(sprintf('%d instances of ''%s'' were changed to ''%s''',i,a{1},a{2}), ...
    'Find&Replace','help','modal');














