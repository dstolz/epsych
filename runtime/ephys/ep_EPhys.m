function varargout = ep_EPhys(varargin)
% ep_EPhys
% 
% Daniel.Stolzberg@gmail.com 2014

% Last Modified by GUIDE v2.5 02-Sep-2014 14:11:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ep_EPhys_OpeningFcn, ...
                   'gui_OutputFcn',  @ep_EPhys_OutputFcn, ...
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

function ep_EPhys_OpeningFcn(hObj, ~, h, varargin)
global GVerbosity

GVerbosity = getpref('EPsych','GVerbosity',1);

h.output = hObj;

h.TDT = [];

guidata(hObj, h);


% elevate Matlab.exe process to a high priority in Windows
[~,~] = dos('wmic process where name="MATLAB.exe" CALL setpriority "high priority"');


setFirstTriggerDelay(getpref('ep_EPhys','FirstTriggerDelay',2000));

ProtocolList_Dir(h,true);

SelectTank(h,getpref('ep_EPhys','TDTinfo',[]));



function varargout = ep_EPhys_OutputFcn(~, ~, h) 
AlwaysOnTop(h,AlwaysOnTop);

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

















%% Tank Selection
function SelectTank(h,TDT)

if nargin == 2 && isempty(TDT)
    return;
    
elseif nargin == 2 && exist(TDT.tank,'dir')
    h.TDT = TDT;
    fprintf('Using Tank: %s\n',TDT.tank)
    
else
    ontop = AlwaysOnTop;
    AlwaysOnTop(h,false);
    
    h.TDT = TDT_TTankInterface(h.TDT);
    
    AlwaysOnTop(h,ontop);
    
end

if isempty(h.TDT.tank), return; end

[p,n] = fileparts(h.TDT.tank);
h.TDT.tankpath = p;
h.TDT.tankname = n;

tdtstr = sprintf('Server: %s\nTank: %s\n',h.TDT.server,n);
set(h.TDT_info,'String',tdtstr);

setpref('ep_EPhys','TDTinfo',h.TDT);

guidata(h.figure1,h);

ChkReady(h);


















%% Protocol List
function ProtocolList_Select(hObj, h)
pinfo = get(hObj,'UserData'); % originally set by call to locate_protocol_dir_Calback
i = get(hObj,'value');
if isempty(i), return; end

warning('off','MATLAB:dispatcher:UnresolvedFunctionHandle');
load(fullfile(pinfo.dir,[pinfo.name{i} '.prot']),'-mat')
warning('on','MATLAB:dispatcher:UnresolvedFunctionHandle');

set(h.protocol_info,'String',protocol.INFO);

h.PROTOCOL = protocol;

guidata(h.figure1,h);

ChkReady(h);

function ProtocolList_Dir(h,noprompt)
% locate directory containing protocols
dn = getpref('ep_EPhys','ProtDir',cd);
if ~ischar(dn), dn = cd; end

if nargin == 1 || ~noprompt
    dn = uigetdir(dn,'Locate Protocol Directory');
    if ~dn, return; end
end

p = dir([dn,'\*.prot']);

if isempty(p)
    warndlg('No protocols were found in the selected directory.', ...
        'Locate Protocols');
    return
end

fprintf('Using Protocol Directory: %s\n',dn)

pn = cell(size(p));
for i = 1:length(p)
     [~,pn{i}] = fileparts(p(i).name);
end

pinfo.dir  = dn;
pinfo.name = pn;
pinfo.info = p;

set(h.protocol_list,'String',pn,'Value',1,'UserData',pinfo);

setpref('ep_EPhys','ProtDir',dn);

ProtocolList_Select(h.protocol_list,h);

function ProtocolList_MoveUp(h) %#ok<DEFNU>
pinfo = get(h.protocol_list,'UserData');
if isempty(pinfo) || length(pinfo.name) == 1, return; end

ind = get(h.protocol_list,'Value');
if ind == 1, return; end

v = 1:length(pinfo.name);
v(ind-1) = ind;
v(ind)   = ind - 1;

pinfo.name = pinfo.name(v);
set(h.protocol_list,'String',pinfo.name,'Value',ind-1,'UserData',pinfo);
ProtocolList_Select(h.protocol_list,h);

function ProtocolList_MoveDown(h) %#ok<DEFNU>
pinfo = get(h.protocol_list,'UserData');
if isempty(pinfo) || length(pinfo.name) == 1, return; end

ind = get(h.protocol_list,'Value');
if ind == length(pinfo.name), return; end

v = 1:length(pinfo.name);
v(ind+1) = ind;
v(ind) = ind + 1;

pinfo.name = pinfo.name(v);
set(h.protocol_list,'String',pinfo.name,'Value',ind+1,'UserData',pinfo);
ProtocolList_Select(h.protocol_list,h);

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





function setFirstTriggerDelay(delay)
% setFirstTriggerDelay(delay)
%
% Set a delay before the first trigger is sent to the modules.  The delay
% should be specified in milliseconds.
%
% DJS 11/2015

current_delay = getpref('ep_EPhys','FirstTriggerDelay',2000);

if nargin == 0 || isempty(delay)
    delay = inputdlg({'Enter first trigger delay (ms):'},'setFirstTriggerDelay|ep_EPhys', ...
        1,{num2str(current_delay)});
    delay = str2double(char(delay));
end

if ~isnumeric(delay) || ~isscalar(delay) || delay < 0
    errordlg('First Trigger Delay must be >= 0','setFirstTriggerDelay|ep_EPhys','modal');
    return
end

if nargin == 0 % only print if user is updating from gui
    fprintf('\nFirst Trigger Delay set to: %0.2f ms\n',delay)
end

h = findobj(gcf,'tag','mnuFirstTriggerDelay');
set(h,'Label',sprintf('First Trigger Delay (%0.2f ms)',delay))

setpref('ep_EPhys','FirstTriggerDelay',delay);














%% Session Control 
function control_record_Callback(hObj, h)   %#ok<DEFNU>
clear global G_DA G_TT G_COMPILED G_STARTTIME

global G_DA G_COMPILED G_PAUSE G_FLAGS G_STARTTIME

G_PAUSE = false;

% Select and load current protocol
ind = get(h.protocol_list,'Value');
pinfo = get(h.protocol_list,'UserData');
if isempty(pinfo)
    beep
    errordlg('No protocol selected.','Record','modal');
    return
end

% Update control panel GUI
% ctrlh = findobj(h.figure1,'-regexp','tag','^control');
ph = findobj(h.figure1,'-regexp','tag','^protocol');
% set([ctrlh; ph; h.select_tank],'Enable','off');

set(h.figure1,'Pointer','watch'); drawnow

% load selected protocol file
fprintf('%s\nLoading Protocol: %s (last modified: %s)\n',repmat('~',1,50), ...
    pinfo.name{ind},pinfo.info(ind).date)
warning('off','MATLAB:dispatcher:UnresolvedFunctionHandle');
load(fullfile(pinfo.dir,[pinfo.name{ind} '.prot']),'-mat')
warning('on','MATLAB:dispatcher:UnresolvedFunctionHandle');

% Check if protocol needs to be compiled before running

if protocol.OPTIONS.compile_at_runtime %#ok<NODEF>
    % Initialize parameters
    try
        [protocol,fail] = InitParams(protocol);
        if fail
            set([h.control_record; h.control_preview; h.select_tank; ph],'Enable','on');
            set(h.figure1,'Pointer','arrow'); drawnow
            return
        end
    catch ME
        set([h.control_record; h.control_preview; h.select_tank; ph],'Enable','on');
        set(h.figure1,'Pointer','arrow'); drawnow
        rethrow(ME)
    end
    [protocol,fail] = ep_CompileProtocol(protocol);
    if fail
        set([h.control_record; h.control_preview; h.select_tank; ph],'Enable','on');
        set(h.figure1,'Pointer','arrow'); drawnow

        beep
        errordlg(sprintf('Unable to compile protocol: %s',pinfo.name{ind}), ...
            'Can''t Compile Protocol','modal');
        return
    end
end

% Copy COMPILED protocol to global variable (G_COMPILED)
protocol.COMPILED.ntrials = size(protocol.COMPILED.trials,1);
G_COMPILED = protocol.COMPILED;
G_COMPILED.HALTED = false;
G_COMPILED.FINISHED = false;

% Instantiate OpenDeveloper ActiveX control and select active tank
if ~isa(G_DA,'COM.TDevAcc_X'), G_DA = TDT_SetupDA; end
G_DA.SetTankName(h.TDT.tank); pause(0.5);


% Prepare OpenWorkbench
vprintf(2,'Setting System Mode to ''Idle'' (0)')
G_DA.SetSysMode(0); 
timeout(10);
to = false;
while G_DA.GetSysMode~=0
    pause(0.1);
    to = timeout;
    if to, break; end
end % Idle
if to, vprintf(0,1,'Unable to Set System Mode to ''Idle'' (0)'); end

vprintf(2,'Setting System Mode to ''Standby'' (1)')
G_DA.SetSysMode(1);
timeout(10);
while G_DA.GetSysMode~=1
    pause(0.1);
    to = timeout;
    if to, break; end
end % Standby
if to, vprintf(0,1,'Unable to Set System Mode to ''Standby'' (1)'); end

% Check tank name
t = G_DA.GetTankName;
vprintf(2,'Current tank name: %s',t);
if ~strcmp(t,h.TDT.tank)
    vprintf(0,1,'Incorrect tank!  %s ~= %s',t,h.TDT.tank)
    error('Incorrect tank!  %s ~= %s',t,h.TDT.tank)
end

% If custom trial selection function is not specified, set to empty and use
% default trial selection function
if ~isfield(G_COMPILED.OPTIONS,'trialfunc'),  G_COMPILED.OPTIONS.trialfunc = []; end

% Operational control of stimulus presentation
if ~isfield(G_COMPILED.OPTIONS,'optcontrol'), G_COMPILED.OPTIONS.optcontrol = false; end

% Find modules with required parameters
dinfo = TDT_GetDeviceInfo(G_DA);
if isempty(dinfo)
    vprintf(0,1,'ep_EPhys|dinfo is empty. Cannot read device info. You may need to restart Matlab and TDT software & hardware.')
    G_DA.SetSysMode(0); pause(0.5); % Idle
    error('ep_EPhys|dinfo is empty. Cannot read device info. You may need to restart Matlab and TDT software & hardware.')
end    
G_FLAGS = struct('TrigState',[],'OpTrigState',[],'ResetOpTrig',[],'ZBUSB_ON',[],'ZBUSB_OFF',[],'useHAT',true);
F = fieldnames(G_FLAGS)';

for i = 1:length(dinfo.name)
    vprintf(3,'Module info:\n\tAlias:\t%s\n\tType:\t%s\n\tStatus:\t%d\n\tRPvds:\t%s\n\tFs:\t%0.3f Hz', ...
        dinfo.name{i},dinfo.Module{i},dinfo.status(i),dinfo.RPfile{i},dinfo.Fs(i))
    
    if strcmp(dinfo.Module{i},'UNKNOWN'), continue; end
    
    [tags,~] = ReadRPvdsTags(dinfo.RPfile{i}); % looks inside macros and scripts
    
    tags = cellfun(@(a) (a(2:end)),tags,'uniformoutput',false); % because all tags will begin with '#'
    
    for f = F
        fidx = strcmp(tags,char(f));
        if ~any(fidx), continue; end
        vprintf(2,'Found Flag: ''%s'' on module ''%s''',char(f),dinfo.name{i})
        G_FLAGS.(char(f)) = [dinfo.name{i} '.#' tags{fidx}];
    end
end
% idx = find(structfun(@isempty,G_FLAGS));
% for i = 1:length(idx)
%     fprintf(2,'WARNING: ''%s'' was not discovered on any module\n',F{idx(i)}) %#ok<PRTCAL>
% end




% Set monitor channel
monitor_channel_Callback(h.monitor_channel);

% Set first trial parameters
G_COMPILED.tidx = 1;
G_COMPILED.FINISHED = false;




% first timer period
try
    t = hat;
    G_FLAGS.useHAT = true;
catch me
    if isequal(me.identifier,'MATLAB:unassignedOutputs')
        vprintf(0,1,['High Accuracy Timer (hat) is not working properly. \n' ...
            'Please consult directions in ..\\epsych\\runtime\\ephys\\hat_setup.txt ' ...
            'or just continue if you''re ok with this.'])
        t = cputime;
        G_FLAGS.useHAT = false;
    else
        rethrow(me)
    end
end

per = t + ITI(G_COMPILED.OPTIONS);





% Call user-defined trial select function
if strcmpi(G_COMPILED.OPTIONS.trialfunc,'< default >'), G_COMPILED.OPTIONS.trialfunc = []; end
if isfield(G_COMPILED.OPTIONS,'trialfunc') && ~isempty(G_COMPILED.OPTIONS.trialfunc)
    G_COMPILED.EXPT.NextTriggerTime = per;
    try
        % The global variable G_DA can be accessed from the trialfunc
        G_COMPILED = feval(G_COMPILED.OPTIONS.trialfunc,G_COMPILED);
    catch me
        vprintf(0,1,'\n%s\nThere was an error in custom trial select function "%s"\n%s\n', ...
            repmat('*',1,50),G_COMPILED.OPTIONS.trialfunc,repmat('*',1,50))
        vprintf(-1,me);
        rethrow(me)
    end
end
DAUpdateParams(G_DA,G_COMPILED);

G_COMPILED.tidx = G_COMPILED.tidx + 1;


% Pause before continuing to the first zbus trigger
firstTriggerDelay = getpref('ep_EPhys','FirstTriggerDelay',2000)/1000; % ms -> sec

% Create new timer to control experiment
T = timerfind('Name','EPhysTimer');
if ~isempty(T), stop(T); delete(T); end
T = timer(                                   ...
    'BusyMode',     'queue',                  ...
    'ExecutionMode','fixedRate',             ...
    'TasksToExecute',inf,                    ...
    'Period',        0.01,                  ...
    'Name',         'EPhysTimer',            ...
    'TimerFcn',     {@RunTime},              ...
    'StartDelay',   firstTriggerDelay,       ...
    'UserData',     {h.figure1 t per});
vprintf(3,'Timer name: ''%s'',\tPeriod: %0.3f sec',T.Name,T.Period);

if strcmp(get(hObj,'String'),'Record')
    % Begin recording
    G_DA.SetSysMode(3); % Record
    vprintf(1,'Recording session started at %s',datestr(now,'HH:MM:SS'))
    pause(1);
    ht = G_DA.GetTankName;
    [TT,~,TDTfig] = TDT_SetupTT;
    TT.OpenTank(ht,'R');
    hb = TT.GetHotBlock;
    TT.CloseTank;
    TT.ReleaseServer;
    delete(TT);
    close(TDTfig);
    vprintf(1,'\tTank:\t%s\n\tBlock:\t%s',ht,hb)
else
    G_DA.SetSysMode(2); % Preview
    vprintf(1,'* Previewing data *')
end

% approximate start time of the recording
G_STARTTIME = clock;

% update progress bar
trem = mean(G_COMPILED.OPTIONS.ISI)/1000 * G_COMPILED.ntrials;
UpdateProgress(h,0,trem,0,G_COMPILED.ntrials);


% update GUI controls
set([h.control_pause,h.control_halt], 'Enable','on');
set([h.control_preview,h.control_record], 'Enable','off');


% Start timer
start(T);

set(h.figure1,'Pointer','arrow'); drawnow

function control_pause_Callback %#ok<DEFNU>
global G_PAUSE

if isempty(G_PAUSE) || ~G_PAUSE, G_PAUSE = true; end

if G_PAUSE
    h = msgbox('PAUSED  Click ''OK'' to resume.','Paused','warn','modal');
    uiwait(h);
    G_PAUSE = false;
end

function control_halt_Callback(h)  %#ok<DEFNU>
global G_DA

ontop = AlwaysOnTop;
AlwaysOnTop(h,false);

r = questdlg('Are you sure you would like to end this recording session early?', ...
    'HALT','Halt','Cancel','Cancel');
if ~strcmp(r,'Cancel')
    DAHalt(h,G_DA);
end
AlwaysOnTop(h,ontop)

function monitor_channel_Callback(hObj) 
global G_DA
if ~isa(G_DA,'COM.TDevAcc_X'), return; end

state = G_DA.GetSysMode;
if state < 2, return; end

ch = fix(str2num(get(hObj,'String'))); %#ok<ST2NM>
G_DA.SetTargetVal('Acq.Monitor_Channel',ch);

function ChkReady(h)
% Check if protocol is set and tank is selected
if isfield(h,'PROTOCOL') && isfield(h.TDT,'tank') && ~isempty(h.TDT.tank)
    set(h.control_record, 'Enable','on');
    set(h.control_preview,'Enable','on');
else
    set(h.control_record, 'Enable','off');
    set(h.control_preview,'Enable','off');
end
    




















%% DA Open Developer Functions
function DAHalt(h,DA)
global G_COMPILED

fprintf('Halting.....\n') 

% Stop recording and update GUI
% set(h.get_thresholds, 'Enable','on');
set(h.control_record, 'Enable','on');
set(h.control_preview,'Enable','on');
set(h.control_pause,  'Enable','off');
set(h.control_halt,   'Enable','off');
set(h.select_tank,    'Enable','on');
ph = findobj(h.figure1,'-regexp','tag','protocol\w');
set(ph,'Enable','on');

if ~isa(DA,'COM.TDevAcc_X'), DA = TDT_SetupDA; end

DA.SetSysMode(0); % Halt system

% Call user-defined trial select function in case it wants to close up
G_COMPILED.HALTED = true;
if isfield(G_COMPILED.OPTIONS,'trialfunc') && ~isempty(G_COMPILED.OPTIONS.trialfunc)
    try 
        % The global variable G_DA can be accessed from the trialfunc
        G_COMPILED = feval(G_COMPILED.OPTIONS.trialfunc,G_COMPILED);
    catch me
        fprintf(2,'\n%s\nThere was an error in custom trial select function "%s"\n%s\n', ...
            repmat('*',1,50),G_COMPILED.OPTIONS.trialfunc,repmat('*',1,50)) %#ok<PRTCAL>
        rethrow(me);
    end
end

% Stop the timer
T = timerfind('Name','EPhysTimer');
if ~isempty(T)
    stop(T);
    try delete(T); end %#ok<TRYNC>
end

function t = DAZBUSBtrig(DA,flags)
% This will trigger zBusB synchronously across modules
% For use with the "TrialTrigger" macro supplied with the EPsych toolbox

if isempty(flags.ZBUSB_ON) 
    % not using ZBUSB trigger
    if flags.useHAT
        t = hat;
    else
        t = cputime;
    end
    return
end

DA.SetTargetVal(flags.ZBUSB_ON,1);
if flags.useHAT, t = hat; else t = cputime; end % start timer for next trial

DA.SetTargetVal(flags.ZBUSB_OFF,1);

function [protocol,fail] = InitParams(protocol)
% look for parameters starting with the $ flag.  These will be used at
% startup to launch an input dialog (inputdlg)
%
% Modify protocol values based on user-defined input
fail = false;

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

ontop = AlwaysOnTop;
AlwaysOnTop(guidata(gcf),false);

% prompt user for values
resp = inputdlg(prompt,'Enter Values',1,dftval,options);

if isempty(resp)
    AlwaysOnTop(guidata(gcf),false);
    fail = true;
    fprintf(2,'Must specify a value!\n') %#ok<PRTCAL>
    return
end

% confirm valuse before continuing
hmsg = 'Confirm Values:'; msg = '';
for i = 1:length(resp)
    msg = sprintf('%s\n% -20s ... % 20s',msg,prompt{i},mat2str(resp{i}));
end
a = questdlg(sprintf('%s\n\n%s',hmsg,msg),'ep_EPhys','Confirm','Change','Cancel','Confirm');
switch a
    case 'Confirm'
        fprintf('\nSpecified Values:\n%s\n',msg)

    case 'Change'
        [protocol,fail] = InitParams(protocol);
        return
        
    case 'Cancel'
        fail = true;
        return
end

for i = 1:length(resp)
    tk = tokenize(prompt{i},'.');
    ind = strcmp(tk{2},mods.(tk{1}).data(:,1));
    mods.(tk{1}).data{ind,1} = mods.(tk{1}).data{ind,1}(2:end); % remove '$'
    mods.(tk{1}).data(ind,4) = resp(i);
end
protocol.MODULES = mods;

AlwaysOnTop(guidata(gcf),ontop);

fail = false;




















%% Timer
function RunTime(hObj,evnt)  %#ok<INUSD>
global G_COMPILED G_DA G_FLAGS G_PAUSE

if G_PAUSE, return; end

ud = get(hObj,'UserData');

%--------------------------------------------------------------------------
% ud{1} = figure handle; ud{2} = previous trigger ; ud{3} = next trigger
if G_FLAGS.useHAT && hat < ud{3} - 0.03, return; end
if ~G_FLAGS.useHAT && cputime < ud{3} - 0.03, return; end
 




%--------------------------------------------------------------------------
% hold computer hostage for a short period until the next trigger time
% . subtract 1 ms since there is a lag between when this code runs and
% when the trigger is actually sent to the hardware
if G_FLAGS.useHAT, while hat < ud{3}-0.001; end
else while cputime < ud{3}-0.001; end; end







%--------------------------------------------------------------------------
% Check if session has been completed (or user has manually halted session in OpenWorkbench)
G_COMPILED.FINISHED = G_COMPILED.tidx > size(G_COMPILED.trials,1) | G_DA.GetSysMode < 2;




% retrieve up-to-date GUI object handles
h = guidata(ud{1});


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
    
    return
end





%--------------------------------------------------------------------------
% TRIGGERING
if G_COMPILED.OPTIONS.optcontrol
    % using operational control of trigger
    
    % Checks for external trigger in OperationalTrigger macro
    while ~G_DA.GetTargetVal(G_FLAGS.OpTrigState)
        if G_COMPILED.HALTED, break; end
        pause(0.001);
    end
    
else
    % ZBus Trigger on modules
    ud{2} = DAZBUSBtrig(G_DA,G_FLAGS);
    % fprintf('Trig Time Discrepancy = %0.5f\n',ud{2}-ud{3})
end



set(h.trigger_indicator,'BackgroundColor',[0 1 0]); drawnow expose


if G_COMPILED.OPTIONS.optcontrol
    % resets OperationalTrigger macro
    G_DA.SetTargetVal(G_FLAGS.ResetOpTrig,1);
    pause(0.001);
    G_DA.SetTargetVal(G_FLAGS.ResetOpTrig,0);

else
    
    % make sure trigger is finished before updating parameters for next trial
    if ~isempty(G_FLAGS.TrigState)
        while G_DA.GetTargetVal(G_FLAGS.TrigState), pause(0.001); end
    end
    
end

set(h.trigger_indicator,'BackgroundColor',[0.95 0.95 0.95]); drawnow expose



ud{3} = ud{2} + ITI(G_COMPILED.OPTIONS);

G_COMPILED.EXPT.NextTriggerTime = ud{3};

set(hObj,'UserData',ud);

% Time remaining for progress bar
trem = mean(G_COMPILED.OPTIONS.ISI)/1000 * (size(G_COMPILED.trials,1)-G_COMPILED.tidx);










%--------------------------------------------------------------------------
% Call user-defined trial select function
if isfield(G_COMPILED.OPTIONS,'trialfunc') && ~isempty(G_COMPILED.OPTIONS.trialfunc)
    % The global variable G_DA can be accessed from the trialfunc
    G_COMPILED = feval(G_COMPILED.OPTIONS.trialfunc,G_COMPILED);
end

% Update parameters
DAUpdateParams(G_DA,G_COMPILED);
    


% Update Progress Bar
UpdateProgress(h,G_COMPILED.tidx/G_COMPILED.ntrials,trem,G_COMPILED.tidx,G_COMPILED.ntrials);

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
function UpdateProgress(h,v,trem,ntrials,ntotal)
global G_STARTTIME

et = etime(clock,G_STARTTIME);


% Update progress bar
set(h.progress_status,'String', ...
    sprintf('# Trials: % 4d of % 4d\nProgress: % 7.1f%%\nElapsed: % 9.1f min\nRemaining: % 5.1f min', ...
    ntrials,ntotal,v*100,et/60,trem/60));

if ~isfield(h,'progbar') || ~ishandle(h.progbar)
    % set handle to progress bar line object
    h.progbar = plot(h.progress_bar,[0 0],[0 v],'-g','linewidth',10);
    set(h.progress_bar,'xlim',[-0.9 1],'ylim',[0 1],'xtick',[],'ytick',[0.25 0.5 0.75],'yticklabel',[]);
    guidata(h.figure1,h);
end

set(h.progbar,'ydata',[0 v]);

function state = AlwaysOnTop(h,ontop)

if nargout == 1
    state = getpref('ep_EPhys','AlwaysOnTop',false);
    if nargin == 0, return; end
end

if nargin == 1 || isempty(ontop)
    s = get(h.always_on_top,'Checked');
    ontop = strcmp(s,'off');
end

if ontop
    set(h.always_on_top,'Checked','on');
else
    set(h.always_on_top,'Checked','off');
end

set(h.figure1,'WindowStyle','normal');

FigOnTop(h.figure1,ontop);

setpref('ep_EPhys','AlwaysOnTop',ontop);













function t = crappyTime(n)
t = sum(n(4:end) .* [24*60 60 1]); 





