function varargout = ep_RunExpt(varargin)
% ep_RunExpt
%
% Run Psychophysics experiment with/without electrophysiology using OpenEx
% 
% Daniel.Stolzberg@gmail.com 2014

% Edit the above text to modify the response to help ep_RunExpt

% Last Modified by GUIDE v2.5 05-Aug-2014 15:11:53

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ep_RunExpt_OpeningFcn, ...
                   'gui_OutputFcn',  @ep_RunExpt_OutputFcn, ...
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


% --- Executes just before ep_RunExpt is made visible.
function ep_RunExpt_OpeningFcn(hObj, ~, h, varargin)
global STATEID

STATEID = 0;

h.output = hObj;

h = ClearConfig(h);

guidata(hObj, h);


% --- Outputs from this function are returned to the command line.
function varargout = ep_RunExpt_OutputFcn(~, ~, h) 
varargout{1} = h.output;

function ep_RunExpt_CloseRequestFcn(hObj,h)
clear global PRGMSTATE CONFIG AX FLAGS STATEID
delete(hObj)





%%
function ExptDispatch(hObj,h) %#ok<DEFNU>
global PRGMSTATE CONFIG AX FLAGS

COMMAND = get(hObj,'String');

switch COMMAND
    case {'Run','Preview'}
        
        CONFIG = h.CONFIG;
        
        % if one protocol is set to use OpenEx, then all must use OpenEx
        FLAGS.UseOpenEx = h.CONFIG(1).PROTOCOL.OPTIONS.UseOpenEx;
        
        % elevate Matlab.exe process to a high priority in Windows
        [~,~] = dos('wmic process where name="MATLAB.exe" CALL setpriority "high priority"');
        
        fprintf('\n%s\n',repmat('~',1,50))
        
        if FLAGS.UseOpenEx
            
            [AX,CONFIG(1).RUNTIME.TDT] = SetupDAexpt;
            if isempty(AX) || ~isa(AX,'COM.TDevAcc_X'), return; end
            
            fprintf('Experiment is using OpenEx\n')
            
            fprintf('Server:\t''%s''\nTank:\t''%s''\n', ...
                CONFIG(1).RUNTIME.TDT.server,CONFIG(1).RUNTIME.TDT.tank)
            
            CONFIG(1).RUNTIME.devinfo = TDT_GetDeviceInfo(AX,false);
            
            switch COMMAND
                case 'Preview', AX.SetSysMode(2);
                case 'Run',     AX.SetSysMode(3);
            end
            fprintf('System set to ''%s''\n',COMMAND)
            pause(1);
            
            
        else
                       
            [AX,CONFIG] = SetupRPexpt(h.CONFIG);
            if isempty(AX), return; end
            
            for i = 1:length(CONFIG)
                for j = 1:length(CONFIG(i).RPfiles)
                    [CONFIG(i).devinfo(j).tags,dt] = ReadRPvdsTags(CONFIG(i).RPfiles{j});
                end
            end
            
            
        end
        
        % look for trigger tags starting with '!'
        TAGS = {[]};
        for i = 1:length(CONFIG)
            for j = 1:length(CONFIG(1).RUNTIME.devinfo)
                t = CONFIG(1).RUNTIME.devinfo(j).tags;
                TAGS(end+1:end+length(t)) = t;
            end
        end
        TAGS(1) = [];
        ind = cellfun(@(x) (x(1)=='!'),TAGS);
        CONFIG(i).RUNTIME.triggers{j} = TAGS(ind);
        
        
        % Launch Box figure to display information during experiment
        h.BoxFig = ep_BoxFig;
        
        h.TIMER = CreateTimer(h.figure1);
        
        fprintf('Experiment is not using OpenEx\n')
        start(h.TIMER); % Begin Experiment
               
        
    case 'Pause'
        
    case 'Stop'
        stop(h.TIMER);
        
        fprintf('Experiment manually stopped at %s\n',datestr(now))
        
        PRGMSTATE = 'STOP';
        
end


UpdateGUIstate(h);

guidata(h.figure1,h)


% Timer Functions
function T = CreateTimer(f)
% Create new timer for control of experiment
T = timerfind('Name','PsychTimer');
if ~isempty(T)
    stop(T);
    delete(T);
end

T = timer('BusyMode','drop', ...
    'ExecutionMode','fixedSpacing', ...
    'Name','PsychTimer', ...
    'Period',0.1, ...
    'StartFcn',{@PsychTimerStart,f}, ...
    'TimerFcn',{@PsychTimerRunTime,f}, ...
    'ErrorFcn',{@PsychTimerError,f}, ...
    'StopFcn', {@PsychTimerStop,f}, ...
    'TasksToExecute',inf);



function PsychTimerStart(~,~,f)
global PRGMSTATE CONFIG AX FLAGS 

PRGMSTATE = 'RUNNING';
UpdateGUIstate(guidata(f));

CONFIG = feval(CONFIG(1).TIMER.Start,CONFIG,AX,FLAGS);

fprintf('Experiment started at %s\n',datestr(now))


function PsychTimerRunTime(~,~,f)
global CONFIG AX FLAGS
CONFIG = feval(CONFIG(1).TIMER.RunTime,CONFIG,AX,FLAGS);

function PsychTimerError(~,~,f)
global CONFIG AX PRGMSTATE FLAGS
PRGMSTATE = 'ERROR';

CONFIG(1).RUNTIME.ERROR = lasterror; %#ok<LERR>

CONFIG = feval(CONFIG(1).RUNTIME.Error,CONFIG,AX,FLAGS);

feval(CONFIG(1).SavingFcn,CONFIG);

UpdateGUIstate(guidata(f));

SaveDataCallback(h);

function PsychTimerStop(~,~,f)
global CONFIG AX PRGMSTATE FLAGS
PRGMSTATE = 'STOP';

if isempty(AX) || ~isa(AX,'COM.TDevAcc_X'), return; end

CONFIG = feval(CONFIG(1).TIMER.Stop,CONFIG,AX,FLAGS);

feval(CONFIG(1).SavingFcn,CONFIG);

h =guidata(f);

UpdateGUIstate(h);
SaveDataCallback(h);





















function SaveDataCallback(h)
global CONFIG PRGMSTATE STATEID
if STATEID > -1 && STATEID < 5, return; end

oldstate = PRGMSTATE;

PRGMSTATE = ''; %#ok<NASGU> % turn GUI off while saving
UpdateGUIstate(h);

feval(CONFIG(1).SavingFcn,CONFIG);

PRGMSTATE = oldstate;
UpdateGUIstate(h);

function isready = CheckReady(h)
% Check if Configuration is setup and ready for experiment to begin
global PRGMSTATE STATEID

if STATEID >= 4, return; end % already running

Subjects = ~isempty(h.CONFIG) && numel(h.CONFIG) > 0 && isfield(h.CONFIG,'SUBJECT')  && ~isempty(h.CONFIG(1).SUBJECT);
DispPref = ~isempty(h.CONFIG) && numel(h.CONFIG) > 0 && isfield(h.CONFIG,'DispPref') && ~isempty(h.CONFIG(1).DispPref);

if DispPref
    set(h.setup_locate_display_prefs,'String','*Loaded*');
else
    set(h.setup_locate_display_prefs,'String','+Display Prefs');
end

isready = Subjects && DispPref;
if isready
    PRGMSTATE = 'CONFIGLOADED';
else
    PRGMSTATE = 'NOCONFIG';
end

UpdateGUIstate(h);

function UpdateGUIstate(h)
global PRGMSTATE STATEID

if isempty(PRGMSTATE), PRGMSTATE = 'NOCONFIG'; end

hCtrl = findobj(h.figure1,'-regexp','tag','^ctrl')';
set([hCtrl,h.save_data],'Enable','off');

hSetup = findobj(h.figure1,'-regexp','tag','^setup')';

switch PRGMSTATE
    case 'NOCONFIG'
        STATEID = 0;
        set([h.setup_remove_subject,h.view_trials],'Enable','off');
        
    case 'CONFIGLOADED'
        PRGMSTATE = 'READY';
        STATEID = 1;
        set(h.view_trials,'Enable','on');
        UpdateGUIstate(h);
        
    case 'READY'
        STATEID = 3;
        set([h.ctrl_run,h.ctrl_preview,hSetup],'Enable','on');
        
    case 'RUNNING'
        STATEID = 4;
        set([h.ctrl_pauseall,h.ctrl_halt],'Enable','on');
        set(hSetup,'Enable','off');
        
    case 'POSTRUN'
        STATEID = 5;
        
    case 'STOP'
        STATEID = 2;
        set([h.save_data,h.ctrl_run,h.ctrl_preview,hSetup],'Enable','on');
        
    case 'ERROR'
        STATEID = -1;
        set([h.save_data,h.ctrl_run,h.ctrl_preview,hSetup],'Enable','on');     
end
    
drawnow












%% Setup
function LoadConfig(h) %#ok<DEFNU>
pn = getpref('ep_RunExpt_Setup','CDir',cd);
[fn,pn] = uigetfile('*.config','Open Configuration File',pn);
if ~fn, return; end
setpref('ep_RunExpt_Setup','CDir',pn);

cfn = fullfile(pn,fn);

if ~exist(cfn,'file')
    warndlg(sprintf('The file "%s" does not exist.',cfn),'RunExpt','modal')
    return
end

fprintf('Loading configuration file: ''%s''\n',cfn)

load(cfn,'-mat');

if ~exist('config','var')
    errordlg('Invalid Configuration file','PsychConfig','modal');
    return
end

h = ClearConfig(h);

h.CONFIG = config;

% set default trial selection function if none is specified
for i = 1:length(h.CONFIG)
    if isempty(h.CONFIG(i).PROTOCOL.OPTIONS.trialfunc) ...
            || strcmp(h.CONFIG(i).PROTOCOL.OPTIONS.trialfunc,'< default >')
        h.CONFIG(i).PROTOCOL.OPTIONS.trialfunc = @DefaultTrialSelectFcn;
    end
end

guidata(h.figure1,h);

UpdateSubjectList(h);

CheckReady(h);

function h = ClearConfig(h)
global STATEID PRGMSTATE

h.CONFIG = struct('SUBJECT',[],'PROTOCOL',[],'RUNTIME',[],'TIMER',[], ...
    'DispPref',[],'SavingFcn',[],'BoxFig',[]);

if STATEID >= 4, return; end

PRGMSTATE = 'NOCONFIG';

set(h.subject_list,'Data',[]);
set(h.setup_locate_display_prefs,'String','+Display Prefs');

guidata(h.figure1,h);

CheckReady(h);

function SaveConfig(h) %#ok<DEFNU>
global STATEID

if STATEID == 0, return; end

pn = getpref('ep_RunExpt_Setup','CDir',cd);

[fn,pn] = uiputfile('*.config','Save Current Configuration',pn);
if ~fn
    fprintf('Configuration not saved.\n')
    return
end

if isempty(h.CONFIG(1).TIMER)
    % set default timer functions
    h = DefineTimerFcns(h, 'default');
else
    % check that existing timer functions exist on current path
    h = DefineTimerFcns(h, struct2cell(h.CONFIG(1).TIMER));
end

if isempty(h.CONFIG(1).SavingFcn)
    % set default saving function
    h = DefineSavingFcn(h,'default');
else
    % check that existing saving function exists on current path
    h = DefineSavingFcn(h,h.CONFIG(1).SavingFcn);
end

if isempty(h.CONFIG(1).BoxFig)
    % set default box figure
    h = DefineBoxFig(h,'default');
else
    % check that existing box figure exists on current path
    h = DefineBoxFig(h,h.CONFIG(1).BoxFig);
end
config = h.CONFIG; %#ok<NASGU>

save(fullfile(pn,fn),'config','-mat');

setpref('ep_RunExpt_Setup','CDir',pn);

fprintf('Configuration saved as: ''%s''\n',fullfile(pn,fn))

function h = LocateProtocol(h,pfn)
global STATEID
if STATEID >= 4, return; end

if nargin == 1
    pn = getpref('ep_RunExpt_Setup','PDir',cd);
    if ~exist(pn,'dir'), pn = cd; end
    drawnow
    [fn,pn] = uigetfile('*.prot','Locate Protocol',pn);
    if ~fn, return; end
    setpref('ep_RunExpt_Setup','PDir',pn);
    pfn = fullfile(pn,fn);
end

if ~exist(pfn,'file')
    warndlg(sprintf('The file "%s" does not exist.',pfn),'Psych Config','modal')
    return
end

load(pfn,'protocol','-mat');

protocol.prot = fn(1:end-5);
protocol.protfile = {pfn};

if isempty(h.CONFIG(1).PROTOCOL)
    h.CONFIG(1).PROTOCOL = protocol;
else
    h.CONFIG(end).PROTOCOL = protocol;
end

if isempty(h.CONFIG(end).PROTOCOL.OPTIONS.trialfunc) ...
        || strcmp(h.CONFIG(end).PROTOCOL.OPTIONS.trialfunc,'< default >')
    h.CONFIG(end).PROTOCOL.OPTIONS.trialfunc = @DefaultTrialSelectFcn;
end

function h = AddSubject(h,S)  %#ok<DEFNU>
global STATEID
if STATEID >= 4, return; end

boxids = 1:16;
Names = [];
if ~isempty(h.CONFIG.SUBJECT)
    boxids = setdiff(boxids,[h.CONFIG.SUBJECT.BoxID]);
    Names = {h.CONFIG.SUBJECT.Name};
end

ontop = AlwaysOnTop(h);
AlwaysOnTop(h,false);
if nargin == 1
    S = ep_AddSubject([],boxids);
else
    S = ep_AddSubject(S,boxids);
end
AlwaysOnTop(h,ontop);


if isempty(S) || isempty(S.Name), return; end

if ~isempty(Names) && ismember(S.Name,Names)
    warndlg(sprintf('The subject name "%s" is already in use.',S.Name), ...
        'Add Subject','modal');
    return
end

if isempty(h.CONFIG(1).SUBJECT)
    h.CONFIG(1).SUBJECT = S;
else
    h.CONFIG(end+1).SUBJECT = S;
end

h = LocateProtocol(h);

UpdateSubjectList(h);

guidata(h.figure1,h);

CheckReady(h);

function RemoveSubject(h,idx) %#ok<DEFNU>
global STATEID
if STATEID >= 4, return; end

if nargin == 1
    idx = get(h.subject_list,'UserData');
end
if isempty(idx) || isempty(h.CONFIG), return; end
h.CONFIG(idx) = [];

guidata(h.figure1,h);

UpdateSubjectList(h);

CheckReady(h);

function UpdateSubjectList(h)
global STATEID
if STATEID >= 4, return; end

if isempty(h.CONFIG)
    set(h.subject_list,'data',[]);
    set(h.setup_edit_protocol,'Enable','off');
    return
end

for i = 1:length(h.CONFIG)
    data(i,1) = {h.CONFIG(i).SUBJECT.BoxID}; %#ok<AGROW>
    data(i,2) = {h.CONFIG(i).SUBJECT.Name};  %#ok<AGROW>
    data(i,3) = {h.CONFIG(i).PROTOCOL.prot}; %#ok<AGROW>
end
set(h.subject_list,'Data',data);

function h = LocateDispPrefs(h, data) %#ok<DEFNU>
global STATEID
if STATEID >= 4, return; end

if nargin == 1 || isempty(data)
    pn = getpref('ep_DisplayPrefs','filepath',cd);
    [fn,pn] = uigetfile('*.epdp','Load Bit Pattern',pn);
    if ~fn, return; end
    dispfn = fullfile(pn,fn);
    load(dispfn,'data','-mat');
end

if ~exist('data','var')
    beep
    errordlg(sprintf('Invalid file: "%s"',fullfile(pn,fn)),'modal');
    return
end

fprintf('Using display file: "%s"\n',fullfile(pn,fn))

h.CONFIG(1).DispPref = data;

if nargout == 0, guidata(h.figure1,h); end

CheckReady(h);

function LaunchDesign(h) %#ok<DEFNU>
if isempty(h.CONFIG.protocolfile)
    ep_ExperimentDesign;
else
    idx = get(h.subject_list,'Value');
    ep_ExperimentDesign(h.CONFIG.protocolfile{idx});
end

function SortBoxes(h) %#ok<DEFNU>
global STATEID
if STATEID >= 4, return; end

if ~isfield(h.CONFIG,'SUBJECT'), return; end

for i = 1:length(h.CONFIG)
    id(i) = h.CONFIG(i).SUBJECT.BoxID; %#ok<AGROW>
end
for i = 1:length(id)
    C(i) = h.CONFIG(id(i)); %#ok<AGROW>
end
h.CONFIG = C;

UpdateSubjectList(h);

guidata(h.figure1,h);

function subject_list_CellSelectionCallback(hObj,evnt,~) %#ok<DEFNU>
idx = evnt.Indices;
if isempty(idx)
    set(hObj,'UserData',[]);
else
    set(hObj,'UserData',idx(1))
end





%% Function Definitions
function h = DefineTimerFcns(h,a)
global STATEID
if STATEID >= 4, return; end

if nargin == 1 || isempty(a)
    if isempty(h.CONFIG.TIMER)
        % hardcoded default functions
        h.CONFIG(1).TIMER.Start   = 'ep_TimerFcn_Start';
        h.CONFIG(1).TIMER.RunTime = 'ep_TimerFcn_RunTime';
        h.CONFIG(1).TIMER.Stop    = 'ep_TimerFcn_Stop';
        h.CONFIG(1).TIMER.Error   = 'ep_TimerFcn_Error';
    end
    
    ontop = AlwaysOnTop(h);
    AlwaysOnTop(h,false);
    a = inputdlg({'Start Timer Function:','RunTime Timer Function:', ...
        'Stop Timer Function:','Error Timer Function:'}, ...
        'Timer',1,struct2cell(h.CONFIG.TIMER));
    AlwaysOnTop(h,ontop);
    if isempty(a), return; end
    
elseif nargin == 2 && ischar(a) && strcmp(a,'default')
        % hardcoded default functions
        h.CONFIG(1).TIMER.Start   = 'ep_TimerFcn_Start';
        h.CONFIG(1).TIMER.RunTime = 'ep_TimerFcn_RunTime';
        h.CONFIG(1).TIMER.Stop    = 'ep_TimerFcn_Stop';
        h.CONFIG(1).TIMER.Error   = 'ep_TimerFcn_Error';
        guidata(h.figure1,h);
        return
end

b = cellfun(@which,a,'UniformOutput',false);
c = cellfun(@isempty,b);
d = find(c);

if isempty(d)
    e = cellfun(@nargin,a);
    f = cellfun(@nargout,a);
    if ~all(e==3) || ~all(f==1)
        beep;
        ontop = AlwaysOnTop(h);
        AlwaysOnTop(h,false);
        errordlg('All Timer functions must have 3 inputs and 1 output.', ...
            'Timer Functions','modal');
        AlwaysOnTop(h,ontop);
        return
    end
    
    h.CONFIG(1).TIMER = cell2struct(a,{'Start';'RunTime';'Stop';'Error'});
    guidata(h.figure1,h);
    
    fprintf('''Start''   timer function:\t%s\t(%s)\n',a{1},b{1})
    fprintf('''RunTime'' timer function:\t%s\t(%s)\n',a{2},b{2})
    fprintf('''Stop''    timer function:\t%s\t(%s)\n',a{3},b{3})
    fprintf('''Error''   timer function:\t%s\t(%s)\n',a{4},b{4})
    
else
    estr = '';
    for i = 1:length(d)
        estr = sprintf('%sThe function ''%s'' was not found on the current path.\n',estr,a{i});
    end
    estr = sprintf('%s\nNone of the timer functions have been updated.',estr);
    beep;
    ontop = AlwaysOnTop(h);
    AlwaysOnTop(h,false);
    errordlg(estr,'Timer Functions','modal');
    AlwaysOnTop(h,ontop);
end
CheckReady(h);

function h = DefineSavingFcn(h,a)
global STATEID
if STATEID >= 4, return; end

if nargin == 2 && ~isempty(a) && ischar(a) && strcmp(a,'default')
    a = 'ep_SaveDataFcn';
    
elseif~isfield(h.CONFIG,'SavingFcn') || isempty(h.CONFIG.SavingFcn)
    % hardcoded default function
    h.CONFIG.SavingFcn = 'ep_SaveDataFcn';
    ontop = AlwaysOnTop(h);
    AlwaysOnTop(h,false);
    a = inputdlg('Data Saving Function','Saving Function',1, ...
        {h.CONFIG.SavingFcn});
    AlwaysOnTop(h,ontop);
    a = char(a);
    if isempty(a), return; end
end

b = which(a);

if isempty(b)
    beep;
    ontop = AlwaysOnTop(h);
    AlwaysOnTop(h,false);
    errordlg(sprintf('The function ''%s'' was not found on the current path.',a),'Saving Function','modal');
    AlwaysOnTop(h,ontop);
    return
end

if nargin(a) ~= 1 || nargout(a) ~= 0
    beep;
    ontop = AlwaysOnTop(h);
    AlwaysOnTop(h,false);
    errordlg('The Saving Data function must have 1 input and 0 outputs.','Saving Function','modal');
    AlwaysOnTop(h,ontop);
    return
end

fprintf('Saving Data function:\t%s\t(%s)\n',a,b)

h.CONFIG(1).SavingFcn = a;
guidata(h.figure1,h);
CheckReady(h);

function h = DefineBoxFig(h,a)
global STATEID
if STATEID >= 4, return; end

if nargin == 2 && ~isempty(a) && ischar(a) && strcmp(a,'default')
    a = 'ep_BoxFig';
    
elseif ~isfield(h.CONFIG(1),'BoxFig') || isempty(h.CONFIG(1).BoxFig)
    % hardcoded default function
    h.CONFIG.BoxFig = 'ep_BoxFig';
    
    ontop = AlwaysOnTop(h);
    AlwaysOnTop(h,false);
    a = inputdlg('Box Figure','Specify Custom Box Figure:',1, ...
        {h.CONFIG(1).BoxFig});
    AlwaysOnTop(h,ontop);

    a = char(a);
    if isempty(a), return; end
end

b = which(a);


if isempty(b)
    beep;
    ontop = AlwaysOnTop(h);
    AlwaysOnTop(h,false);
    errordlg(sprintf('The figure ''%s'' was not found on the current path.',a),'Saving Function','modal');
    AlwaysOnTop(h,ontop);
    return
end

fprintf('Box Figure:\t%s\t(%s)\n',a,b)

h.CONFIG(1).BoxFig = a;
guidata(h.figure1,h);
CheckReady(h);



%%
function ViewTrials(h) %#ok<DEFNU>

idx = get(h.subject_list,'UserData');
if isempty(idx), return; end

ep_CompiledProtocolTrials(h.CONFIG(idx).PROTOCOL,'trunc',2000);

function EditProtocol(h) %#ok<DEFNU>
idx = get(h.subject_list,'UserData');
if isempty(idx), return; end

AlwaysOnTop(h,false);
ep_ExperimentDesign(char(h.CONFIG(idx).PROTOCOL.protfile));

function state = AlwaysOnTop(h,ontop)

if nargout == 1
    state = getpref('ep_RunExpt','AlwaysOnTop',false);
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

setpref('ep_RunExpt','AlwaysOnTop',ontop);


