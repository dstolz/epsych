function varargout = ep_EPhysController(varargin)
% h = ep_EPhysController
%
% Electrophysiology Control Panel.  Handles Matlab integration with TDT
% OpenProject using OpenDeveloper ActiveX controls.
% 
% See also, ProtocolDesign, CalibrationUtil
%
% DJS 2013


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ep_EPhysController_OpeningFcn, ...
                   'gui_OutputFcn',  @ep_EPhysController_OutputFcn, ...
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

% -- Executes just before ep_ephyscontroller is made visible.
function ep_EPhysController_OpeningFcn(hObj, ~, h, varargin)
global G_DA G_TT

% Choose default command line output for ep_ephyscontroller
h.output = hObj;

% Instantiate TDT ActiveX Controls
if ~isa(G_DA,'COM.TDevAcc_X'), G_DA = TDT_SetupDA; end
if ~isa(G_TT,'COM.TTank_X'),   G_TT = TDT_SetupTT; end

% h.activex2 = actxcontrol('TTankInterfaces.TankSelect', ...
%     'parent',h.ep_EPhysController,'position',[35 215 204 350]);

% Update h structure
guidata(hObj, h);

% elevate Matlab.exe process to a high priority in Windows
[~,~] = dos('wmic process where name="MATLAB.exe" CALL setpriority "high priority"');

% --- Outputs from this function are returned to the command line.
function varargout = ep_EPhysController_OutputFcn(hObj, ~, h)  %#ok<INUSL>
varargout{1} = h.output;

function EPhysController_CloseRequestFcn(hObj, ~, h) %#ok<INUSD,DEFNU>
global G_DA G_TT

if isa(G_DA,'COM.TDevAcc_X')
    G_DA.CloseConnection;
    delete(G_DA);
end

if isa(G_TT,'COM.TTank_X')
    G_TT.CloseTank;
    G_TT.ReleaseServer;
    delete(G_TT);
end

clear global G_DA G_TT

% find and close TDT background figures
fh = findobj('type','figure','-and','name','ODevFig','-or','name','TTankFig');
close(fh);

% clear some leftover global variables
clear global G_COMPILED G_FLAGS G_PAUSE

% Hint: delete(hObj) closes the figure
delete(hObj);














%% Tanks
function activex2_TankChanged(hObj, evnt, h) %#ok<INUSL,DEFNU>
set(h.EPhysController,'Pointer','watch'); 
fprintf('Collecting tank information, please wait ...')
drawnow

try
    blocks = TDT2mat(evnt.ActTank);
catch %#ok<CTCH>
    fprintf(' *** UNABLE TO READ TANK ***\n')
    blocks = [];
end

if isempty(blocks)
    blkstr = 'NO BLOCKS';
else
    blkstr = '';
    for i = 1:length(blocks)
        try
            td = TDT2mat(evnt.ActTank,blocks{i},'type',2,'silent',true);
        catch %#ok<CTCH>
            blkstr = sprintf('%s%s\t<- CAN''T READ BLOCK\n',blkstr,blocks{i});
            continue
        end
        
        if ~isempty(td.streams)
            fn = fieldnames(td.streams);
            nchans = length(td.streams.(fn{1}).chan);
        elseif ~isempty(td.snips)
            fn = fieldnames(td.snips);
            nchans = length(td.snips.(fn{1}).chan);
        else
            nchans = 0;
        end
        blkstr = sprintf(['%s%s\t%s\n\t%s\n', ...
            '\tDURATION: %s\n', ...
            '\t# CHANNELS: %d\n\n'], ...
            blkstr,blocks{i},td.info.date, ...
           td.info.begintime,td.info.duration,nchans);
    end
end
[d,t] = fileparts(evnt.ActTank);
blkstr = sprintf('TANK: %s\n%s\n%s\n%s',t,d,repmat('-',1,length(d)),blkstr);
set(h.block_info,'String',blkstr,'HorizontalAlignment','left', ...
    'Enable','inactive');
set(h.EPhysController,'Pointer','arrow');

h.ActTank= evnt.ActTank;
guidata(h.EPhysController,h);

ChkReady(h);

fprintf(' done\n')














%% Protocol List
function protocol_list_Callback(hObj, ~, h)
pinfo = get(hObj,'UserData'); % originally set by call to locate_protocol_dir_Calback
i = get(hObj,'value');
if isempty(i), return; end

load(fullfile(pinfo.dir,[pinfo.name{i} '.prot']),'-mat')

set(h.protocol_info,'String',protocol.INFO);

h.PROTOCOL = protocol;

guidata(h.EPhysController,h);

ChkReady(h);

function protocol_locate_dir_Callback(hObj, ~, h) %#ok<DEFNU,INUSL>
% locate directory containing protocols
dn = getpref('EPHYS2','ProtDir',cd);
if ~ischar(dn), dn = cd; end
dn = uigetdir(dn,'Locate Protocol Directory');

if ~dn, return; end

p = dir([dn,'\*.prot']);

if isempty(p)
    warndlg('No protocols were found in the selected directory.', ...
        'Locate Protocols');
    return
end

pn = cell(size(p));
for i = 1:length(p)
     [~,pn{i}] = fileparts(p(i).name);
end

pinfo.dir  = dn;
pinfo.name = pn;
pinfo.info = p;

set(h.protocol_list,'String',pn,'Value',1,'UserData',pinfo);

setpref('EPHYS2','ProtDir',dn);

function protocol_move_up_Callback(hObj, ~, h) %#ok<DEFNU,INUSL>
pinfo = get(h.protocol_list,'UserData');
if isempty(pinfo) || length(pinfo.name) == 1, return; end

ind = get(h.protocol_list,'Value');
if ind == 1, return; end

v = 1:length(pinfo.name);
v(ind-1) = ind;
v(ind)   = ind - 1;

pinfo.name = pinfo.name(v);
set(h.protocol_list,'String',pinfo.name,'Value',ind-1,'UserData',pinfo);
protocol_list_Callback(h.protocol_list, [], h);

function protocol_move_down_Callback(hObj, ~, h) %#ok<DEFNU,INUSL>
pinfo = get(h.protocol_list,'UserData');
if isempty(pinfo) || length(pinfo.name) == 1, return; end

ind = get(h.protocol_list,'Value');
if ind == length(pinfo.name), return; end

v = 1:length(pinfo.name);
v(ind+1) = ind;
v(ind) = ind + 1;

pinfo.name = pinfo.name(v);
set(h.protocol_list,'String',pinfo.name,'Value',ind+1,'UserData',pinfo);
protocol_list_Callback(h.protocol_list, [], h);

function EditProtocol(h) %#ok<DEFNU>
a = get_string(h.protocol_list);
if isempty(a)
    ep_ExperimentDesign;
else
    d = get(h.protocol_list,'UserData');
    ep_ExperimentDesign(fullfile(d.dir,[a '.prot']));
end

function ViewTrials(h) %#ok<DEFNU>
a = get_string(h.protocol_list);
if isempty(a), return; end
d = get(h.protocol_list,'UserData');
fn = fullfile(d.dir,[a '.prot']);
load(fn,'-mat');
[~,fail] = ep_CompiledProtocolTrials(protocol,'showgui',true);
if fail
    beep
    warndlg(sprintf('Unable to view trials for "%s".',fn),'View Trials','modal');
    return
end
































%% Session Control 
function control_record_Callback(hObj, ~, h) 
clear global G_DA G_TT G_COMPILED G_STARTTIME

global G_DA G_COMPILED G_PAUSE G_FLAGS G_STARTTIME

G_PAUSE = false;

% Select and load current protocol
ind = get(h.protocol_list,'Value');
pinfo = get(h.protocol_list,'UserData');
if isempty(pinfo)
    errordlg('No protocol selected.','Record','modal');
    return
end

% Update control panel GUI
set(hObj,'Enable','off');
set(h.control_pause,  'Enable','off');
set(h.control_preview,'Enable','off');
set(h.get_thresholds, 'Enable','off');
set(h.control_halt,   'Enable','on');
ph = findobj(h.EPhysController,'-regexp','tag','protocol\w');
set(ph,'Enable','off');
set(h.EPhysController,'Pointer','watch'); drawnow

% load selected protocol file
fprintf('%s\nLoading Protocol file: %s\n',repmat('~',1,50),pinfo.name{ind})
load(fullfile(pinfo.dir,[pinfo.name{ind} '.prot']),'-mat')

% Check if protocol needs to be compiled before running
if protocol.OPTIONS.compile_at_runtime && ~isequal(protocol.OPTIONS.trialfunc,'< default >')%#ok<NODEF>
    protocol.COMPILED = feval(protocol.OPTIONS.trialfunc,G_DA,protocol,true);
elseif protocol.OPTIONS.compile_at_runtime
    % Initialize parameters
    try
        protocol = InitParams(protocol);
    catch ME
        set(h.get_thresholds,'Enable','on');
        set(h.control_halt,  'Enable','off');
        rethrow(ME)
    end
    [protocol,fail] = CompileProtocol(protocol);
    if fail
        errordlg(sprintf('Unable to compile protocol: %s',pinfo.name{ind}), ...
            'Can''t Compile Protocol','modal');
        return
    end
end

% Copy COMPILED protocol to global variable (G_COMPILED)
G_COMPILED = protocol.COMPILED;
G_COMPILED.HALTED = false;
G_COMPILED.FINISHED = false;

% Instantiate OpenDeveloper ActiveX control and select active tank
if ~isa(G_DA,'COM.TDevAcc_X'), G_DA = TDT_SetupDA; end
G_DA.SetTankName(h.ActTank);

% Prepare OpenWorkbench
G_DA.SetSysMode(0); pause(0.5); % Idle
G_DA.SetSysMode(1); pause(0.5); % Standby
G_DA.SetSysMode(2); pause(0.5); % Preview

% Load and set thresholds (and filters)
SetThresholds(G_DA);

% If custom trial selection function is not specified, set to empty and use
% default trial selection function
if ~isfield(G_COMPILED.OPTIONS,'trialfunc'),  G_COMPILED.OPTIONS.trialfunc = []; end

% Operational control of stimulus presentation
if ~isfield(G_COMPILED.OPTIONS,'optcontrol'), G_COMPILED.OPTIONS.optcontrol = false; end


% Get Device Names
devnames = '';
i = 0;
while 1
    devnames{i+1} = G_DA.GetDeviceName(i);
    if isempty(devnames{i+1})
        devnames(i+1) = [];
        break
    end
    if ~strcmp(devnames{i+1}(1:3),'PA5')
        rco = G_DA.GetDeviceRCO(devnames{i+1});
        SF  = G_DA.GetDeviceSF(devnames{i+1});
        fprintf('% 7s (%3.2fkHz):\t%s\n',devnames{i+1},SF/1000,rco)
    end
    i = i + 1;
end

% Find modules with required parameters
G_FLAGS = struct('trigstate',[],'update',{[]}, ...
    'ZBUSB_ON',[],'ZBUSB_OFF',[],'ZBUSB',[],'RCode',[]);
for i = 1:length(devnames)
    if strcmp(devnames{i}(1:3),'PA5'), continue; end
    if G_DA.GetTargetType(sprintf('%s.~TrigState',devnames{i}))
        G_FLAGS.trigstate = sprintf('%s.~TrigState',devnames{i});
    end
    % for compatability with ep_RunTime experiments
    if G_DA.GetTargetType(sprintf('%s.#TrigState',devnames{i}))
        G_FLAGS.trigstate = sprintf('%s.#TrigState',devnames{i});
    end
    if G_DA.GetTargetType(sprintf('%s.~Update',devnames{i}))
        G_FLAGS.update    = sprintf('%s.~Update',devnames{i});
    end
    if G_DA.GetTargetType(sprintf('%s.ZBUSB_ON',devnames{i}))
        G_FLAGS.ZBUSB_ON  = sprintf('%s.ZBUSB_ON',devnames{i});
    end
    if G_DA.GetTargetType(sprintf('%s.ZBUSB_OFF',devnames{i}))
        G_FLAGS.ZBUSB_OFF = sprintf('%s.ZBUSB_OFF',devnames{i});
    end
    if G_DA.GetTargetType(sprintf('%s.RCode',devnames{i}))
        G_FLAGS.RCode     = sprintf('%s.RCode',devnames{i});
    end
end

w = [];
if isempty(G_FLAGS.ZBUSB_ON),  w{end+1} = 'ZBUSB_ON';   end
if ~isempty(G_FLAGS.ZBUSB_ON) && isempty(G_FLAGS.ZBUSB_OFF), w{end+1} = 'ZBUSB_OFF';  end
if isempty(G_FLAGS.trigstate), w{end+1} = 'TrigState'; end
for i = 1:length(w)
    fprintf(2,'WARNING: ''%s'' was not discovered on any module\n',w{i}) %#ok<PRTCAL>
end

if G_COMPILED.OPTIONS.optcontrol
    if isempty(G_FLAGS.RCode)
        errordlg('''RCode'' tag was not found on any module.  The ''RCode'' tag is required when using operational trigger control.', ...
            '''RCode'' not found','modal');
        DAHalt(h,G_DA);
        return
    end
%     if isempty(G_FLAGS.update)
%         errordlg('''~Update'' tag must be on a module when using operational trigger control.', ...
%             '''~Update'' not found','modal');
%         DAHalt(h,G_DA);
%         return
%     end
end


% Set monitor channel
monitor_channel_Callback(h.monitor_channel, [], h);

% Set first trial parameters
G_COMPILED.tidx = 1;
G_COMPILED.FINISHED = false;


if G_COMPILED.OPTIONS.optcontrol
    % ZBus Trigger on modules
    t   = DAZBUSBtrig(G_DA,G_FLAGS);
    per = -1;
else
    % figure out first timer period
    t   = hat;
    per = t + ITI(G_COMPILED.OPTIONS);
end

% Call user-defined trial select function
if strcmpi(G_COMPILED.OPTIONS.trialfunc,'< default >'), G_COMPILED.OPTIONS.trialfunc = []; end
if isfield(G_COMPILED.OPTIONS,'trialfunc') && ~isempty(G_COMPILED.OPTIONS.trialfunc)
    G_COMPILED.EXPT.NextTriggerTime = per;
    try %#ok<TRYNC>
        % The global variable G_DA can be accessed from the trialfunc
        G_COMPILED = feval(G_COMPILED.OPTIONS.trialfunc,G_COMPILED);
    end
end
DAUpdateParams(G_DA,G_COMPILED);

G_COMPILED.tidx = G_COMPILED.tidx + 1;


% Create new timer to control experiment
T = timerfind('Name','EPhysTimer');
if ~isempty(T), stop(T); delete(T); end
T = timer(                                   ...
    'BusyMode',     'queue',                 ...
    'ExecutionMode','fixedRate',             ...
    'TasksToExecute',inf,                    ...
    'Period',        0.01,                   ...
    'Name',         'EPhysTimer',            ...
    'TimerFcn',     {@RunTime},  ...
    'StartDelay',   1,                       ...
    'UserData',     {h.EPhysController t per});
% 'ErrorFcn',{@StartTrialError,G_DA}, ...


if strcmp(get(hObj,'String'),'Record')
    % Begin recording
    G_DA.SetSysMode(3); % Record
    fprintf('Recording session started at %s\n',datestr(now,'HH:MM:SS'))
    pause(1);
    ht = G_DA.GetTankName;
    [TT,~,TDTfig] = TDT_SetupTT;
    TT.OpenTank(ht,'R');
    hb = TT.GetHotBlock;
    TT.CloseTank;
    TT.ReleaseServer;
    delete(TT);
    close(TDTfig);
    fprintf('\tTank:\t%s\n\tBlock:\t%s\n',ht,hb)
else
    G_DA.SetSysMode(2); % Preview
    fprintf('* Previewing data ... data is not being recorded to tank *\n')
end

G_STARTTIME = clock;
% update progress bar
trem = mean(protocol.COMPILED.OPTIONS.ISI)/1000 * size(protocol.COMPILED.trials,1);
UpdateProgress(h,0,trem);

% Start timer
start(T);

set(h.control_pause,  'Enable','on');
set(h.EPhysController,'Pointer','arrow'); drawnow

function control_pause_Callback(hObj, ~, h) %#ok<INUSD,DEFNU>
global G_PAUSE

if isempty(G_PAUSE) || ~G_PAUSE, G_PAUSE = true; end

if G_PAUSE
    h = msgbox('PAUSED  Click ''OK'' to resume.','Paused','warn','modal');
    uiwait(h);
    G_PAUSE = false;
end

function control_halt_Callback(hObj, ~, h) %#ok<INUSL,DEFNU>
global G_DA

r = questdlg('Are you sure you would like to end this recording session early?', ...
    'HALT','Halt','Cancel','Cancel');
if strcmp(r,'Cancel'), return; end
DAHalt(h,G_DA);

function monitor_channel_Callback(hObj, ~, h) %#ok<INUSD>
global G_DA
if ~isa(G_DA,'COM.TDevAcc_X'), G_DA = TDT_SetupDA; end

state = G_DA.GetSysMode;
if state < 2, return; end

ch = str2num(get(hObj,'String')); %#ok<ST2NM>
G_DA.SetTargetVal('Acq.monitor_ch',ch);

function get_thresholds_Callback(hObj, ~, h) %#ok<DEFNU>
global G_DA
if ~isa(G_DA,'COM.TDevAcc_X'), G_DA = TDT_SetupDA; end

set(hObj,'String','Wait...','Enable','off'); drawnow

% Attempt to retrieve voltage thresholds for online spike detection
if GetThresholds(G_DA)
    %hoops saved successfully
    set(hObj,'BackgroundColor','green');
else
    %error
    set(hObj,'BackgroundColor','red');
    errordlg('Unable to retrieve threshold data from OpenEx!');
end

set(hObj,'String','Get Thresholds','Enable','on')

ChkReady(h);

function ChkReady(h)
% Check if protocol is set and tank is selected
if isfield(h,'PROTOCOL') && isfield(h,'ActTank')
    set(h.control_record, 'Enable','on');
    set(h.control_preview,'Enable','on');
else
    set(h.control_record, 'Enable','off');
    set(h.control_preview,'Enable','off');
end
    























%% DA Open Developer Functions
function DAHalt(h,DA)
global G_COMPILED

% Stop recording and update GUI
set(h.get_thresholds, 'Enable','on');
set(h.control_record, 'Enable','on');
set(h.control_preview,'Enable','on');
set(h.control_pause,  'Enable','off');
set(h.control_halt,   'Enable','off');
ph = findobj(h.EPhysController,'-regexp','tag','protocol\w');
set(ph,'Enable','on');

if ~isa(DA,'COM.TDevAcc_X'), DA = TDT_SetupDA; end

DA.SetSysMode(0); % Halt system

% Call user-defined trial select function in case it wants to close up
G_COMPILED.HALTED = true;
if isfield(G_COMPILED.OPTIONS,'trialfunc') && ~isempty(G_COMPILED.OPTIONS.trialfunc)
    try %#ok<TRYNC>
        % The global variable G_DA can be accessed from the trialfunc
        G_COMPILED = feval(G_COMPILED.OPTIONS.trialfunc,G_COMPILED);
    end
end

% Stop the timer
T = timerfind('Name','EPhysTimer');
if ~isempty(T)
    stop(T);
    try delete(T); end %#ok<TRYNC>
end

function DATrigger(DA,trig_str)
% Trigger a trial during OpenEx session by setting a parameter tag called
% SoftTrg high for a brief period and then off.  The trig_str parameter
% should be linked to a constant logic (ConsL) component which should run
% through an rising edge detect (EdgeDetect) component.  There is no way to
% trigger using DevAcc.X control like with RPco.X SoftTrg component.

trig_str = cellstr(trig_str);
for i = 1:length(trig_str)
    DA.SetTargetVal(trig_str{i},1);
    DA.SetTargetVal(trig_str{i},0);
end

function t = DAZBUSBtrig(DA,flags)
% This will trigger zBusB synchronously across modules
%   Note: Two ScriptTag components must be included in one of the RPvds
%   circuits.  
%       The ZBUS_ON ScriptTag should have the following code:
%           Sub main
%               TDT.ZTrgOn(Asc("B"))
%           End Sub
% 
%       The ZBUS_OFF ScriptTag should have the following code:
%           Sub main
%               TDT.ZTrgOff(Asc("B"))
%           End Sub

if isempty(flags.ZBUSB_ON), t = hat; return; end
DA.SetTargetVal(flags.ZBUSB_ON,1);
t = hat; % start timer for next trial
DA.SetTargetVal(flags.ZBUSB_OFF,1);

function protocol = InitParams(protocol)
% look for parameters starting with the $ flag.  These will be used at
% startup to launch an input dialog (inputdlg)
%
% Modify protocol values based on user-defined input

mods = protocol.MODULES;
fldn = fieldnames(mods);

prompt = []; dftval = [];
for i = 1:length(fldn)
    dt = mods.(fldn{i}).data;
    mtmp.(fldn{i}) = find(cell2mat(cellfun(@(x) x(1)=='$', dt(:,1), 'UniformOutput',false)));
    for j = 1:length(mtmp.(fldn{i}))
        prompt{end+1} = sprintf('%s.%s',fldn{i},dt{mtmp.(fldn{i})(j),1}); %#ok<AGROW>
        dftval{end+1} = dt{mtmp.(fldn{i})(j),4}; %#ok<AGROW>
    end
end
if isempty(prompt), return; end

options.Resize = 'on';
options.WindowStyle = 'modal';
options.Interpreter = 'none';

resp = inputdlg(prompt,'Enter Values',1,dftval,options);
if isempty(resp)
    error('Must specify value!')
end

for i = 1:length(resp)
    tk = tokenize(prompt{i},'.');
    ind = strcmp(tk{2},mods.(tk{1}).data(:,1));
    mods.(tk{1}).data(ind,4) = resp(i);
end
protocol.MODULES = mods;











%% Timer
function RunTime(hObj,evnt)  %#ok<INUSD>
global G_COMPILED G_DA G_FLAGS G_PAUSE

if G_PAUSE, return; end

ud = get(hObj,'UserData');

%--------------------------------------------------------------------------
if G_COMPILED.OPTIONS.optcontrol
    % using operational control of trigger
    
    % RCode must ~= zero in order to trigger next trial
    RCode = G_DA.GetTargetVal(G_FLAGS.RCode);
    if RCode == 0, return; end
    
    trem = inf;
    
else
    % ud{1} = figure handle; ud{2} = last trigger ; ud{3} = next trigger
    if hat < ud{3} - 0.025, return; end
    
    % hold computer hostage for a short period until the next trigger time
    while hat < ud{3}; end
    
    % ZBus Trigger on modules
    ud{2} = DAZBUSBtrig(G_DA,G_FLAGS);
    % fprintf('Trig Time Discrepancy = %0.5f\n',ud{2}-ud{3})
    
    % retrieve up-to-date GUI object handles
    h = guidata(ud{1});
    
    set(h.trigger_indicator,'BackgroundColor',[0 1 0]); drawnow expose
    
    % make sure trigger is finished before updating parameters for next trial
    if ~isempty(G_FLAGS.trigstate)
        while G_DA.GetTargetVal(G_FLAGS.trigstate), pause(0.001); end
    end
    
    pause(0.01);
    
    set(h.trigger_indicator,'BackgroundColor',[0.95 0.95 0.95]); drawnow expose
    
    
    if ~G_COMPILED.OPTIONS.optcontrol
        % Figure out time of next trigger
        ud{3} = ud{2} + ITI(G_COMPILED.OPTIONS);
        G_COMPILED.EXPT.NextTriggerTime = ud{3};
    end
    
    
    % Time remaining for progress bar
    trem = mean(G_COMPILED.OPTIONS.ISI)/1000 * (size(G_COMPILED.trials,1)-G_COMPILED.tidx);

    set(hObj,'UserData',ud);
end

%--------------------------------------------------------------------------
% Check if session has been completed (or user has manually halted session in OpenWorkbench)
G_COMPILED.FINISHED = G_COMPILED.tidx > size(G_COMPILED.trials,1) ...
                      || G_DA.GetSysMode < 2;
if G_COMPILED.FINISHED
    % give some time before actually halting the recording
    set(h.progress_status,'ForegroundColor',[1 0 0]);
    for i = 3:-1:1
        set(h.progress_status,'String',sprintf('Finishing recording in %d',i));
        pause(1)
    end
    set(h.progress_status,'ForegroundColor',[0 0 0],'String','');
        
    DAHalt(h,G_DA);
    
    fprintf(' done\n')
    fprintf('Presented %d trials.\nTime is now %s.\n\n',G_COMPILED.tidx-1, ...
        datestr(now,'HH:MM:SS PM'))
    
    idx = get(h.protocol_list,'Value');
    v   = get(h.protocol_list,'String');
    
    % the 'Fall Through' feature semi-automates the recording protocol
    if get(h.fall_through_record,'Value') && idx < length(v)
        r = questdlg('Continue when ready','Next Protocol','Continue','Cancel','Continue');
        if strcmp(r,'Continue')
            set(h.protocol_list,'Value',idx+1);
            control_record_Callback(h.control_record, [], h)
        end
    end
    return
end


%--------------------------------------------------------------------------
% Call user-defined trial select function
if isfield(G_COMPILED.OPTIONS,'trialfunc') && ~isempty(G_COMPILED.OPTIONS.trialfunc)
    % The global variable G_DA can be accessed from the trialfunc
    G_COMPILED = feval(G_COMPILED.OPTIONS.trialfunc,G_COMPILED);
end

% Update parameters
DAUpdateParams(G_DA,G_COMPILED);

% Optional: Trigger '~Update' tag on module following DAUpdateParams
%     > confirms to module that parameters have been updated
if ~isempty(G_FLAGS.update)
    DATrigger(G_DA,G_FLAGS.update);
    set(h.trigger_indicator,'BackgroundColor',[0 1 0]); drawnow expose
    pause(0.2)
    set(h.trigger_indicator,'BackgroundColor',[0 0 0]); drawnow expose
end
    

% Update Progress Bar
UpdateProgress(h,G_COMPILED.tidx/size(G_COMPILED.trials,1),trem);

% Increment trial index
G_COMPILED.tidx = G_COMPILED.tidx + 1;

function i = ITI(Opts)
% Genereate next inter-trigger-interval
% Set delay to next trigger (approximate)
if Opts.ISI == -1
    % ISI is specified by custom function (or not at all)
    if ~isfield(Opts,'cISI') || isempty(Opts.cISI), return; end
    i = Opts.cISI;
    
elseif length(Opts.ISI) == 1
    % static ISI
    i = Opts.ISI;
    
else
    % ISI is determined from a flat distribution between a and b
    a = min(Opts.ISI);  b = max(Opts.ISI);
    i = (a + (b - a) * rand);
end
i = fix(i) / 1000; % round to nearest millisecond




















%% GUI Functions
function UpdateProgress(h,v,trem)
global G_STARTTIME

et = etime(clock,G_STARTTIME);


% Update progress bar
set(h.progress_status,'String', ...
    sprintf('Progress: %0.1f%% | Time Elapsed: %0.1f min | Remaining: %0.1f min',v*100,et/60,trem/60));

if ~isfield(h,'progbar') || ~ishandle(h.progbar)
    % set handle to progress bar line object
    h.progbar = plot(h.progress_bar,[0 v],[0 0],'-r','linewidth',15);
    set(h.progress_bar,'xlim',[0 1],'ylim',[-0.9 1],'xtick',[],'ytick',[]);
    guidata(h.EPhysController,h);
end

set(h.progbar,'xdata',[0 v]);
