function varargout = ep_RunExpt_SanesLab(varargin)
% ep_RunExpt_SanesLab
%
% Run Psychophysics experiment with/without electrophysiology using OpenEx
% 
% Daniel.Stolzberg@gmail.com 2014

% Edit the above text to modify the response to help ep_RunExpt_SanesLab

% Last Modified by GUIDE v2.5 16-Jun-2015 08:53:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ep_RunExpt_SanesLab_OpeningFcn, ...
                   'gui_OutputFcn',  @ep_RunExpt_SanesLab_OutputFcn, ...
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


% --- Executes just before ep_RunExpt_SanesLab is made visible.
function ep_RunExpt_SanesLab_OpeningFcn(hObj, ~, h, varargin)
global STATEID

STATEID = 0;

h.output = hObj;

h = ClearConfig(h);

guidata(hObj, h);


% --- Outputs from this function are returned to the command line.
function varargout = ep_RunExpt_SanesLab_OutputFcn(~, ~, h) 
varargout{1} = h.output;

function ep_RunExpt_CloseRequestFcn(hObj,~) %#ok<DEFNU>
global PRGMSTATE RUNTIME

if strcmp(PRGMSTATE,'RUNNING')
    b = questdlg('Experiment is currently running.  Closing program will stop the experiment.', ...
        'Experiment','Close Experiment','Cancel','Cancel');
    if strcmp(b,'Cancel'), return; end
    
    if isfield(RUNTIME,'TIMER') && timerfind('Name','PsychTimer')
        stop(RUNTIME.TIMER);
        delete(RUNTIME.TIMER);
    end    
end

clear global PRGMSTATE CONFIG RUNTIME AX STATEID

delete(hObj)





%%
function ExptDispatch(hObj,h) 
global PRGMSTATE CONFIG AX RUNTIME


COMMAND = get(hObj,'String');

switch COMMAND
    case {'Run','Preview'}
        set(h.figure1,'pointer','watch'); drawnow
        
        % elevate Matlab.exe process to a high priority in Windows
        [~,~] = dos('wmic process where name="MATLAB.exe" CALL setpriority "high priority"');
        
        fprintf('\n%s\n',repmat('~',1,50))
        
        RUNTIME = []; % start fresh

        % Load protocols
        for i = 1:length(CONFIG)
            warning('off','MATLAB:dispatcher:UnresolvedFunctionHandle');
            load(CONFIG(i).protocol_fn,'protocol','-mat');
            warning('on','MATLAB:dispatcher:UnresolvedFunctionHandle');

            CONFIG(i).PROTOCOL = protocol;
            
            if isempty(CONFIG(i).PROTOCOL.OPTIONS.trialfunc) ...
                    || strcmp(CONFIG(i).PROTOCOL.OPTIONS.trialfunc,'< default >')
                CONFIG(i).PROTOCOL.OPTIONS.trialfunc = @DefaultTrialSelectFcn;
            end
        end
        
        if CONFIG(1).PROTOCOL.OPTIONS.UseOpenEx
             fprintf('Experiment is designed for OpenEx\n')
            [AX,TDT] = SetupDAexpt;
            if isempty(AX) || ~isa(AX,'COM.TDevAcc_X'), return; end
                        
            fprintf('Server:\t''%s''\nTank:\t''%s''\n', ...
                TDT.server,TDT.tank)
            
            
            RUNTIME.TDT = TDT_GetDeviceInfo(AX,false);
            RUNTIME.TDT.server = TDT.server;
            RUNTIME.TDT.tank   = TDT.tank;
            
            
            % Copy parameters to RUNTIME.TRIALS
            for i = 1:length(CONFIG)
                C = CONFIG(i).PROTOCOL.COMPILED;
                RUNTIME.TRIALS(i).readparams = C.readparams;
                RUNTIME.TRIALS(i).Mreadparams = cellfun(@ModifyParamTag, ...
                    RUNTIME.TRIALS(i).readparams,'UniformOutput',false);
                RUNTIME.TRIALS(i).writeparams = C.writeparams; 
                RUNTIME.TRIALS(i).randparams = C.randparams;
            end


        else
            fprintf('Experiment is not using OpenEx\n')
             
            [AX,RUNTIME] = SetupRPexpt(CONFIG);
            if isempty(AX), return; end
            
        end
        pause(1);
        
        
        RUNTIME.UseOpenEx = CONFIG(1).PROTOCOL.OPTIONS.UseOpenEx;
        if RUNTIME.UseOpenEx, RUNTIME.TYPE = 'DA'; else RUNTIME.TYPE = 'RP'; end

        
       % Do stuff with parameter tags
       RUNTIME.TDT.NumMods = length(RUNTIME.TDT.RPfile);
       RUNTIME.TDT.triggers = cell(1,RUNTIME.TDT.NumMods);
       for i = 1:RUNTIME.TDT.NumMods
           if ismember(RUNTIME.TDT.Module{i},{'PA5','UNKNOWN'}) % PA5 is marked 'UNKNOWN' when using OpenDeveloper
               RUNTIME.TDT.devinfo(i).tags = {'SetAtten'};
               RUNTIME.TDT.devinfo(i).datatype = {'S'};
               
           elseif ~isempty(RUNTIME.TDT.RPfile{i})
               [RUNTIME.TDT.devinfo(i).tags,RUNTIME.TDT.devinfo(i).datatype] = ReadRPvdsTags(RUNTIME.TDT.RPfile{i});
               t = RUNTIME.TDT.devinfo(i).tags;
               
               % look for trigger tags starting with '!'
               ind = cellfun(@(x) (x(1)=='!'),t);
               if any(ind)
                   if RUNTIME.UseOpenEx
                       RUNTIME.TDT.triggers{i} = cellfun(@(a) ([RUNTIME.TDT.name{i} '.' a]),t(ind),'UniformOutput',false);
                   else
                       RUNTIME.TDT.triggers{i} = t(ind);
                       RUNTIME.TDT.trigmods(i) = i;
                   end
               end
           end
           
       end
        
       
              



        if RUNTIME.UseOpenEx
            switch COMMAND
                case 'Preview', AX.SetSysMode(2);
                case 'Run',     AX.SetSysMode(3);
            end
            fprintf('System set to ''%s''\n',COMMAND)            
            pause(1);
        end





        if ~isfield(RUNTIME,'TIMERfcn') || isempty(RUNTIME.TIMERfcn)
            % set default timer functions
            DefineTimerFcns(h, 'default',false);
        else
            % check that existing timer functions exist on current path
            DefineTimerFcns(h, struct2cell(RUNTIME.TIMERfcn),false);
        end
        RUNTIME.TIMER = CreateTimer(h.figure1);
        
        
        if isempty(CONFIG(1).BoxFig), CONFIG(1).BoxFig = @ep_BoxFig; end
        if isempty(CONFIG(1).SavingFcn), CONFIG(1).SavingFcn = @ep_SaveDataFcn; end
        
        start(RUNTIME.TIMER); % Begin Experiment
               
        
        set(h.figure1,'pointer','arrow'); drawnow
        
        
    case 'Pause'
        
    case 'Stop'
        set(h.figure1,'pointer','watch'); drawnow
        t = timerfind('Name','PsychTimer');
        if ~isempty(t), stop(t); delete(t); end
        t = timerfind('Name','BoxTimer');
        if ~isempty(t), stop(t); delete(t); end
        fprintf('Experiment stopped at %s\n',datestr(now,'dd-mmm-yyyy HH:MM'))
        PRGMSTATE = 'STOP';
        set(h.figure1,'pointer','arrow'); drawnow
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
global PRGMSTATE CONFIG AX RUNTIME

PRGMSTATE = 'RUNNING';
UpdateGUIstate(guidata(f));

RUNTIME = feval(RUNTIME.TIMERfcn.Start,CONFIG,RUNTIME,AX);
RUNTIME.StartTime = clock;
fprintf('Experiment started at %s\n',datestr(RUNTIME.StartTime ,'dd-mmm-yyyy HH:MM'))

% Launch Box figure to display information during experiment
try
    feval(CONFIG(1).BoxFig);
catch %#ok<CTCH>
    warning('Failed to launch behavior performance GUI: %s',func2str(CONFIG(1).BoxFig));
end


function PsychTimerRunTime(~,~,f) 
global AX RUNTIME

if RUNTIME.UseOpenEx
    sysmode = AX.GetSysMode;
    if sysmode < 2
        h = guidata(f);
        ExptDispatch(h.ctrl_halt,h);
        return
    end
end

RUNTIME = feval(RUNTIME.TIMERfcn.RunTime,RUNTIME,AX);

function PsychTimerError(~,~,f)
global AX PRGMSTATE RUNTIME
PRGMSTATE = 'ERROR';

RUNTIME.ERROR = lasterror; %#ok<LERR>

RUNTIME = feval(RUNTIME.TIMERfcn.Error,RUNTIME,AX);

feval(RUNTIME.SavingFcn,RUNTIME);

UpdateGUIstate(guidata(f));

SaveDataCallback(h);

function PsychTimerStop(~,~,f)
global AX PRGMSTATE RUNTIME
PRGMSTATE = 'STOP';

RUNTIME = feval(RUNTIME.TIMERfcn.Stop,RUNTIME,AX);

h = guidata(f);

UpdateGUIstate(h);
SaveDataCallback(h);





















function SaveDataCallback(h)
global CONFIG PRGMSTATE STATEID RUNTIME
% if STATEID > -1 && STATEID < 5, return; end

oldstate = PRGMSTATE;

PRGMSTATE = ''; %#ok<NASGU> % turn GUI off while saving
UpdateGUIstate(h);

feval(CONFIG(1).SavingFcn,RUNTIME);

PRGMSTATE = oldstate;
UpdateGUIstate(h);

function isready = CheckReady(h)
% Check if Configuration is setup and ready for experiment to begin
global PRGMSTATE STATEID CONFIG

if STATEID >= 4, return; end % already running

Subjects = ~isempty(CONFIG) && numel(CONFIG) > 0 && isfield(CONFIG,'SUBJECT')  && ~isempty(CONFIG(1).SUBJECT);
DispPref = ~isempty(CONFIG) && numel(CONFIG) > 0 && isfield(CONFIG,'DispPref') && ~isempty(CONFIG(1).DispPref);

if DispPref
    set(h.setup_locate_display_prefs,'String','*Loaded*');
else
    set(h.setup_locate_display_prefs,'String','+Display Prefs');
end

% isready = Subjects && DispPref;
isready = Subjects;
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
global CONFIG

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
warning('off','MATLAB:dispatcher:UnresolvedFunctionHandle');
load(cfn,'-mat');
warning('on','MATLAB:dispatcher:UnresolvedFunctionHandle');

if ~exist('config','var')
    errordlg('Invalid Configuration file','PsychConfig','modal');
    return
end

h = ClearConfig(h);

CONFIG = config;

guidata(h.figure1,h);

UpdateSubjectList(h);

CheckReady(h);

function h = ClearConfig(h)
global STATEID PRGMSTATE CONFIG

CONFIG = struct('SUBJECT',[],'PROTOCOL',[],'RUNTIME',[],'TIMER',[], ...
    'DispPref',[],'SavingFcn',[],'BoxFig',[]);

if STATEID >= 4, return; end

PRGMSTATE = 'NOCONFIG';

set(h.subject_list,'Data',[]);
set(h.setup_locate_display_prefs,'String','+Display Prefs');

guidata(h.figure1,h);

CheckReady(h);

function SaveConfig(h) %#ok<DEFNU>
global STATEID CONFIG

if STATEID == 0, return; end

pn = getpref('ep_RunExpt_Setup','CDir',cd);

[fn,pn] = uiputfile('*.config','Save Current Configuration',pn);
if ~fn
    fprintf('Configuration not saved.\n')
    return
end

if isempty(CONFIG(1).TIMER)
    % set default timer functions
    h = DefineTimerFcns(h, 'default');
else
    % check that existing timer functions exist on current path
    h = DefineTimerFcns(h, struct2cell(CONFIG(1).TIMER));
end

if isempty(CONFIG(1).SavingFcn)
    % set default saving function
    h = DefineSavingFcn(h,'default');
else
    % check that existing saving function exists on current path
    h = DefineSavingFcn(h,CONFIG(1).SavingFcn);
end

if isempty(CONFIG(1).BoxFig)
    % set default box figure
    DefineBoxFig(h,'default');
else
    % check that existing box figure exists on current path
    DefineBoxFig(h,CONFIG(1).BoxFig);
end
config = CONFIG; %#ok<NASGU>

save(fullfile(pn,fn),'config','-mat');

setpref('ep_RunExpt_Setup','CDir',pn);

fprintf('Configuration saved as: ''%s''\n',fullfile(pn,fn))

function ok = LocateProtocol(pfn)
global STATEID CONFIG

ok = false;

if STATEID >= 4, return; end

if nargin == 0
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

if isempty(CONFIG) || isempty(CONFIG(1).PROTOCOL)
    CONFIG(1).protocol_fn = pfn;
else
    CONFIG(end+1).protocol_fn = pfn;
end


ok = true;

function h = AddSubject(h,S)  %#ok<DEFNU>
global STATEID CONFIG
if STATEID >= 4, return; end

boxids = 1:16;
Names = [];
if ~isempty(CONFIG) && ~isempty(CONFIG(1).SUBJECT)
    boxids = setdiff(boxids,[CONFIG.SUBJECT.BoxID]);
    Names = {CONFIG.SUBJECT.Name};
end

ontop = AlwaysOnTop(h,false);
if nargin == 1
    S = ep_AddSubject_SanesLab([],boxids);
else
    S = ep_AddSubject_SanesLab(S,boxids);
end
AlwaysOnTop(h,ontop);


if isempty(S) || isempty(S.Name), return; end

if ~isempty(Names) && ismember(S.Name,Names)
    warndlg(sprintf('The subject name "%s" is already in use.',S.Name), ...
        'Add Subject','modal');
    return
end

ok = LocateProtocol;

if ok
    CONFIG(end).SUBJECT = S;

    UpdateSubjectList(h);
end
guidata(h.figure1,h);

CheckReady(h);

function RemoveSubject(h,idx) %#ok<DEFNU>
global STATEID CONFIG
if STATEID >= 4, return; end

if nargin == 1
    idx = get(h.subject_list,'UserData');
end
if isempty(idx) || isempty(CONFIG), return; end
CONFIG(idx) = [];

guidata(h.figure1,h);

UpdateSubjectList(h);

CheckReady(h);

function UpdateSubjectList(h)
global STATEID CONFIG
if STATEID >= 4, return; end

if isempty(CONFIG)
    set(h.subject_list,'data',[]);
    set([h.setup_remove_subject,h.setup_edit_protocol,h.view_trials],'Enable','off');
    return
end

for i = 1:length(CONFIG)
    data(i,1) = {CONFIG(i).SUBJECT.BoxID}; %#ok<AGROW>
    data(i,2) = {CONFIG(i).SUBJECT.Name};  %#ok<AGROW>
    [~,fn,~] = fileparts(CONFIG(i).protocol_fn);
    data(i,3) = {fn}; %#ok<AGROW>
end
set(h.subject_list,'Data',data);

if size(data,1) == 0
    set([h.setup_remove_subject,h.setup_edit_protocol,h.view_trials],'Enable','off');
else
    set([h.setup_remove_subject,h.setup_edit_protocol,h.view_trials],'Enable','on');
end

function h = LocateDispPrefs(h, data) %#ok<DEFNU>
global STATEID CONFIG
if STATEID >= 4, return; end

if nargin == 1 || isempty(data)
    pn = getpref('ep_DisplayPrefs','filepath',cd);
    [fn,pn] = uigetfile('*.epdp','Load Bit Pattern',pn);
    if ~fn, return; end
    dispfn = fullfile(pn,fn);
    load(dispfn,'data','-mat');
    setpref('ep_DisplayPrefs','filepath',pn)
end

if ~exist('data','var')
    beep
    errordlg(sprintf('Invalid file: "%s"',fullfile(pn,fn)),'modal');
    return
end

fprintf('Using display file: "%s"\n',fullfile(pn,fn))

CONFIG(1).DispPref = data;

if nargout == 0, guidata(h.figure1,h); end

CheckReady(h);

function LaunchDesign(h) %#ok<DEFNU>
global CONFIG

if isempty(CONFIG.protocolfile)
    ep_ExperimentDesign;
else
    idx = get(h.subject_list,'Value');
    ep_ExperimentDesign(CONFIG.protocolfile{idx});
end

function SortBoxes(h) %#ok<DEFNU>
global STATEID CONFIG
if STATEID >= 4, return; end

if ~isfield(CONFIG,'SUBJECT'), return; end

for i = 1:length(CONFIG)
    id(i) = CONFIG(i).SUBJECT.BoxID; %#ok<AGROW>
end
for i = 1:length(id)
    C(i) = CONFIG(id(i)); %#ok<AGROW>
end
CONFIG = C;

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
function h = DefineTimerFcns(h,a,echo)
global STATEID RUNTIME
if STATEID >= 4, return; end

if nargin < 3 || ~islogical(echo), echo = true; end

if nargin == 1 || isempty(a)
    if isempty(RUNTIME) || ~isfield(RUNTIME,'TIMERfcn') || isempty(RUNTIME.TIMERfcn)
        % hardcoded default functions
        RUNTIME.TIMERfcn.Start   = 'ep_TimerFcn_Start';
        RUNTIME.TIMERfcn.RunTime = 'ep_TimerFcn_RunTime';
        RUNTIME.TIMERfcn.Stop    = 'ep_TimerFcn_Stop';
        RUNTIME.TIMERfcn.Error   = 'ep_TimerFcn_Error';
    end
    
    ontop = AlwaysOnTop(h);
    AlwaysOnTop(h,false);
    a = inputdlg({'Start Timer Function:','RunTime Timer Function:', ...
        'Stop Timer Function:','Error Timer Function:'}, ...
        'Timer',1,struct2cell(RUNTIME.TIMERfcn));
    AlwaysOnTop(h,ontop);
    if isempty(a), return; end
    
elseif nargin >= 2 && ischar(a) && strcmp(a,'default')
        % hardcoded default functions
        RUNTIME.TIMERfcn.Start   = 'ep_TimerFcn_Start';
        RUNTIME.TIMERfcn.RunTime = 'ep_TimerFcn_RunTime';
        RUNTIME.TIMERfcn.Stop    = 'ep_TimerFcn_Stop';
        RUNTIME.TIMERfcn.Error   = 'ep_TimerFcn_Error';
        return
end

b = cellfun(@which,a,'UniformOutput',false);
c = cellfun(@isempty,b);
d = find(c);

if isempty(d)
    e = cellfun(@nargin,a);
    f = cellfun(@nargout,a);
    if e(1) ~= 3 || f(1) ~= 1
        beep;
        ontop = AlwaysOnTop(h);
        AlwaysOnTop(h,false);
        errordlg('The "Start" timer function must have 3 inputs and 1 output.', ...
            'Timer Functions','modal');
        AlwaysOnTop(h,ontop);
        return
    end
    
    if ~all(e(2:end)==2) || ~all(f(2:end)==1)
        beep;
        ontop = AlwaysOnTop(h);
        AlwaysOnTop(h,false);
        errordlg('Timer functions for "RunTime", "Stop", and "Error" must ', ...
            'have 2 inputs and 1 output.','Timer Functions','modal');
        AlwaysOnTop(h,ontop);
        return
    end
    
    RUNTIME.TIMERfcn = cell2struct(a,{'Start';'RunTime';'Stop';'Error'});
    guidata(h.figure1,h);
    
    if echo
        fprintf('''Start''   timer function:\t%s\t(%s)\n',a{1},b{1})
        fprintf('''RunTime'' timer function:\t%s\t(%s)\n',a{2},b{2})
        fprintf('''Stop''    timer function:\t%s\t(%s)\n',a{3},b{3})
        fprintf('''Error''   timer function:\t%s\t(%s)\n',a{4},b{4})
    end
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
global STATEID CONFIG
if STATEID >= 4, return; end

if nargin == 2 && ~isempty(a) && ischar(a) && strcmp(a,'default')
    a = 'ep_SaveDataFcn';
    
elseif nargin == 1 || isempty(a) || ~isfield(CONFIG,'SavingFcn')
    if isempty(CONFIG.SavingFcn)
        % hardcoded default function
        CONFIG.SavingFcn = 'ep_SaveDataFcn';
    end
    ontop = AlwaysOnTop(h);
    AlwaysOnTop(h,false);
    a = inputdlg('Data Saving Function','Saving Function',1, ...
        {CONFIG.SavingFcn});
    AlwaysOnTop(h,ontop);
    a = char(a);
    if isempty(a), return; end
end

if isa(a,'function_handle'), a = func2str(a); end
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
    errordlg('The Saving Data function must have 2 inputs and 0 outputs.','Saving Function','modal');
    AlwaysOnTop(h,ontop);
    return
end

fprintf('Saving Data function:\t%s\t(%s)\n',a,b)

CONFIG(1).SavingFcn = a;
guidata(h.figure1,h);
CheckReady(h);

function h = DefineBoxFig(h,a)
global STATEID CONFIG
if STATEID >= 4, return; end

if nargin == 2 && ~isempty(a) && ischar(a) && strcmp(a,'default')
    a = 'ep_BoxFig';    

elseif nargin == 1 || isempty(a) || ~isfield(CONFIG(1),'BoxFig')
    if isempty(CONFIG(1).BoxFig)
        % hardcoded default function
        CONFIG.BoxFig = 'ep_BoxFig';
    end

    
    ontop = AlwaysOnTop(h);
    AlwaysOnTop(h,false);
    if isa(CONFIG(1).BoxFig,'function_handle'), CONFIG(1).BoxFig = func2str(CONFIG(1).BoxFig); end
    a = inputdlg('Box Figure','Specify Custom Box Figure:',1, ...
        {CONFIG(1).BoxFig});
    AlwaysOnTop(h,ontop);

    a = char(a);
    if isempty(a), return; end
end

if isa(a,'function_handle'), a = func2str(a); end
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

CONFIG(1).BoxFig = a;
guidata(h.figure1,h);
CheckReady(h);



%%
function ViewTrials(h) %#ok<DEFNU>
global CONFIG

idx = get(h.subject_list,'UserData');
if isempty(idx), return; end

warning('off','MATLAB:dispatcher:UnresolvedFunctionHandle');
load(CONFIG(idx).protocol_fn,'protocol','-mat');
warning('on','MATLAB:dispatcher:UnresolvedFunctionHandle');


ep_CompiledProtocolTrials(protocol,'trunc',2000);

function EditProtocol(h) %#ok<DEFNU>
global CONFIG

idx = get(h.subject_list,'UserData');
if isempty(idx), return; end

AlwaysOnTop(h,false);
ep_ExperimentDesign(char(CONFIG(idx).protocol_fn));

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


