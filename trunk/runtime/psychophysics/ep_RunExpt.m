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
global PRGMSTATE

h.output = hObj;

h = ClearConfig(h);

PRGMSTATE = 'NOCONFIG';

guidata(hObj, h);


% --- Outputs from this function are returned to the command line.
function varargout = ep_RunExpt_OutputFcn(~, ~, h) 
varargout{1} = h.output;








%%
function ExptDispatch(hObj,h) %#ok<DEFNU>
global PRGMSTATE CONFIG G_RP G_DA

% Launch Box figure to display information during experiment
h.BoxFig = ep_BoxFig;

% elevate Matlab.exe process to a high priority in Windows
[~,~] = dos('wmic process where name="MATLAB.exe" CALL setpriority "high priority"');

if h.UseOpenEx
        
    [G_DA,CONFIG] = SetupDAexpt(h.C);
    if isempty(G_DA), return; end
    
else

    [G_RP,CONFIG] = SetupRPexpt(h.C);  
    if isempty(G_RP), return; end
    
end

T = CreateTimer;

start(T); % Begin Experiment

PRGMSTATE = 'RUNNING';

UpdateGUIstate(h);

% Timer Functions
function T = CreateTimer
% Create new timer for RPvds control of experiment
delete(timerfind('Name','PsychTimer'));

T = timer('BusyMode','drop', ...
    'ExecutionMode','fixedSpacing', ...
    'Name','PsychTimer', ...
    'Period',0.1, ...
    'StartFcn',{@PsychTimerStart}, ...
    'TimerFcn',{@PsychTimerRunTime}, ...
    'ErrorFcn',{@PsychTimerError}, ...
    'StopFcn', {@PsychTimerStop}, ...
    'TasksToExecute',inf);



function PsychTimerStart(hObj,~)
global CONFIG G_RP G_DA PRGMSTATE
try
    CONFIG = feval(CONFIG(1).TIMER.Start,CONFIG,G_RP,G_DA);
    PRGMSTATE = 'RUNNING';
    UpdateGUIstate(guidata(hObj));
    
catch ME
    PRGMSTATE = 'ERROR';
    UpdateGUIstate(guidata(hObj));
    rethrow(ME);
end

function PsychTimerRunTime(~,~)
global CONFIG G_RP G_DA
CONFIG = feval(CONFIG(1).TIMER.RunTime,CONFIG,G_RP,G_DA);

function PsychTimerError(hObj,~)
global CONFIG G_RP G_DA PRGMSTATE
PRGMSTATE = 'ERROR';

CONFIG(1).ERROR = lasterror; %#ok<LERR>

CONFIG = feval(CONFIG(1).TIMER.Error,CONFIG,G_RP,G_DA);

feval(CONFIG(1).SavingFcn,CONFIG);

UpdateGUIstate(guidata(hObj));

SaveDataCallback(h);

function PsychTimerStop(hObj,~)
global CONFIG G_RP G_DA PRGMSTATE
PRGMSTATE = 'STOP';

CONFIG = feval(CONFIG(1).TIMER.Stop,CONFIG,G_RP,G_DA);

feval(CONFIG(1).SavingFcn,CONFIG);

UpdateGUIstate(guidata(hObj));

SaveDataCallback(h);












function CreateBoxFig
% Find and close box figures which are not in use


% create and populate GUI based on CONFIG.  Maybe loop-call an external
% function to generate GUIs










function SaveDataCallback(h)
global CONFIG PRGMSTATE

oldstate = PRGMSTATE;

PRGMSTATE = ''; %#ok<NASGU> % turn GUI off while saving
UpdateGUIstate(h);

feval(CONFIG(1).SavingFcn,CONFIG);

PRGMSTATE = oldstate;
UpdateGUIstate(h);




function UpdateGUIstate(h)
global PRGMSTATE

if isempty(PRGMSTATE), PRGMSTATE = 'NOCONFIG'; end

hCtrl = findobj(h.figure1,'-regexp','tag','^ctrl')';
set([hCtrl,h.save_data],'Enable','off');

hSetup = findobj(h.figure1,'-regexp','tag','^setup')';

switch PRGMSTATE
    case 'NOCONFIG'
        
    case 'CONFIGLOADED'
        PRGMSTATE = 'READY';
        guidata(h.figure1,h);
        UpdateGUIstate(h);
        
    case 'READY'
        set([h.ctrl_run,h.ctrl_preview,hSetup],'Enable','on');
        
    case 'RUNNING'
        set([h.ctrl_pauseall,h.ctrl_halt],'Enable','on');
        set(hSetup,'Enable','off');
        
    case 'STOP'
        set([h.save_data,h.ctrl_run,h.ctrl_preview,hSetup],'Enable','on');
        
    case 'ERROR'
        set([h.save_data,h.ctrl_run,h.ctrl_preview,hSetup],'Enable','on');     
end
    
drawnow












% Setup------------------------------------------------------
function LoadConfig(h) %#ok<DEFNU>
global PRGMSETUP

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

% update display
for i = 1:length(config.SUBJECT)
    
end

% make config structure easier to address during runtime
if isfield(h,'C'), h = rmfield(h,'C'); end
tC.TIMER    = config.TIMER;
tC.COMPILED = [config.PROTOCOL.COMPILED];
tC.OPTIONS  = [config.PROTOCOL.OPTIONS];
tC.MODULES  = {config.PROTOCOL.MODULES};
tC.SUBJECT  = [config.SUBJECT];
for i = 1:length(config.SUBJECT)
    h.C(i) = structfun(@(x) (x(i)),tC,'UniformOutput',false);
end
h.C(1).BoxFig = config.BoxFig;

% if one protocol is set to use OpenEx, then all must use OpenEx
h.UseOpenEx = h.C(1).OPTIONS.UseOpenEx;

% set default trial selection function if non is specified
for i = 1:length(h.C)
    if isempty(h.C(i).OPTIONS.trialfunc) || strcmp(h.C(i).OPTIONS.trialfunc,'< default >')
        h.C(i).OPTIONS.trialfunc = @DefaultTrialSelectFcn;
    end
end

guidata(h.figure1,h);

PRGMSETUP = 'CONFIGLOADED';
UpdateGUIstate(h);

function h = ClearConfig(h)
h.CONFIG = [];

set(h.setup_add_subject,'Enable','on');
set(h.subject_list,'Data',[]);

guidata(h.figure1,h);

UpdateGUIstate(h);

function SaveConfig(h) %#ok<DEFNU>
pn = getpref('ep_RunExpt_Setup','CDir',cd);

[fn,pn] = uiputfile('*.config','Save Current Configuration',pn);
if ~fn
    fprintf('Configuration not saved.\n')
    return
end

if ~isfield(h.CONFIG,'TIMER') || isempty(h.CONFIG.TIMER)
    % set default timer functions
    h = DefineTimerFcns(h, 'default');
else
    % check that existing timer functions exist on current path
    h = DefineTimerFcns(h, struct2cell(h.CONFIG.TIMER));
end

if ~isfield(h.CONFIG,'SavingFcn') || isempty(h.CONFIG.SavingFcn)
    % set default saving function
    h = DefineSavingFcn(h,'default');
else
    % check that existing saving function exists on current path
    h = DefineSavingFcn(h,h.CONFIG.SavingFcn);
end

if ~isfield(h.CONFIG,'BoxFig') || isempty(h.CONFIG.BoxFig)
    % set default box figure
    h = DefineBoxFig(h,'default');
else
    % check that existing box figure exists on current path
    h = DefineBoxFig(h,h.CONFIG.BoxFig);
end
config = h.CONFIG; %#ok<NASGU>

save(fullfile(pn,fn),'config','-mat');

setpref('ep_RunExpt_Setup','CDir',pn);

fprintf('Configuration saved as: ''%s''\n',fullfile(pn,fn))

function h = LocateProtocol(h,pfn)
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

if isempty(h.CONFIG) || ~isfield(h.CONFIG,'PROTOCOL')
    h.CONFIG.PROTOCOL = protocol;
else
    h.CONFIG(end).PROTOCOL = protocol;
end

function boxids = ProtocolBoxIDs(P) %#ok<DEFNU>
wp = P.COMPILED.writeparams;
t = cellfun(@(a) (tokenize(a,'~')),wp,'uniformoutput',false);
id = cellfun(@(a) (str2double(a{end})),t);
boxids = unique(id);

function h = AddSubject(h,S)  %#ok<DEFNU>
boxids = 1:16;
Names = [];
if ~isempty(h.CONFIG)
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

if isempty(h.CONFIG) || ~isfield(h.CONFIG,'SUBJECT')
    h.CONFIG(1).SUBJECT = S;
else
    h.CONFIG(end+1).SUBJECT = S;
end

h = LocateProtocol(h);

UpdateSubjectList(h);

% SelectSubject(h.subject_list,h);

guidata(h.figure1,h);

UpdateGUIstate(h);

function RemoveSubject(h,idx) %#ok<DEFNU>
if nargin == 1
    idx = get(h.subject_list,'UserData');
end
if isempty(idx) || isempty(h.CONFIG), return; end
h.CONFIG(idx) = [];

guidata(h.figure1,h);

UpdateGUIstate(h);

UpdateSubjectList(h);

% SelectSubject(h.subject_list,h);

function UpdateSubjectList(h)
if isempty(h.CONFIG)
    set(h.subject_list,'data',[]);
    set(h.setup_edit_protocol,'Enable','off');
    return
end

for i = 1:length(h.CONFIG)
    data(i,1) = {h.CONFIG(i).SUBJECT.BoxID};
    data(i,2) = {h.CONFIG(i).SUBJECT.Name};
    data(i,3) = {h.CONFIG(i).PROTOCOL.prot};
end
set(h.subject_list,'Data',data);

function ViewTrials(h) %#ok<DEFNU>
idx = get(h.subject_list,'UserData');
if isempty(idx), return; end

ep_CompiledProtocolTrials(h.CONFIG(idx).PROTOCOL,'trunc',2000);

function SelectSubject(hObj,h)
idx = get(hObj,'Value');

if idx > numel(h.CONFIG.PROTOCOL)
    set(h.prot_description,'String','');
    set(h.expt_protocol,'String','','tooltipstring','');
    return
end

protocol = h.CONFIG.PROTOCOL(idx);

set(h.prot_description,'String',protocol.INFO);

[pn,fn,~] = fileparts(h.CONFIG.protocolfile{idx});

set(h.expt_protocol,'String',fn,'tooltipstring',pn);

function h = LocateDispPrefs(h, data) %#ok<DEFNU>
if nargin == 1 || isempty(data)
    pn = getpref('ep_BitMasker','filepath',cd);
    [fn,pn] = uigetfile('*.bitmask','Load Bit Pattern',pn);
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

h.CONFIG.DispPref = data;

if nargout == 0
    guidata(h.figure1,h);
end

function LaunchDesign(h) %#ok<DEFNU>
if isempty(h.CONFIG.protocolfile)
    ep_ExperimentDesign;
else
    idx = get(h.subject_list,'Value');
    ep_ExperimentDesign(h.CONFIG.protocolfile{idx});
end

function SortBoxes(h) %#ok<DEFNU>
if ~isfield(h.CONFIG,'SUBJECT'), return; end

for i = 1:length(h.CONFIG)
    id(i) = h.CONFIG(i).SUBJECT.BoxID;
end
[~,idx] = sort(id);
for i = 1:length(idx)
    C(i) = h.CONFIG(idx(i));
end
h.CONFIG = C;

UpdateSubjectList(h);

guidata(h.figure1,h);

function h = DefineTimerFcns(h,a)
if nargin == 1 || isempty(a)
    if isempty(h.CONFIG.TIMER)
        % hardcoded default functions
        h.CONFIG.TIMER.Start   = 'ep_TimerFcn_Start';
        h.CONFIG.TIMER.RunTime = 'ep_TimerFcn_RunTime';
        h.CONFIG.TIMER.Stop    = 'ep_TimerFcn_Stop';
        h.CONFIG.TIMER.Error   = 'ep_TimerFcn_Error';
    end
    
    ontop = AlwaysOnTop(h);
    AlwaysOnTop(h,false);
    a = inputdlg({'Start Timer Function:','RunTime Timer Function:', ...
        'Stop Timer Function:','Error Timer Function:'}, ...
        'Timer',1,struct2cell(h.CONFIG.TIMER));
    AlwaysOnTop(h,ontop);
    
elseif nargin == 2 && ischar(a) && strcmp(a,'default')
        % hardcoded default functions
        h.CONFIG.TIMER.Start   = 'ep_TimerFcn_Start';
        h.CONFIG.TIMER.RunTime = 'ep_TimerFcn_RunTime';
        h.CONFIG.TIMER.Stop    = 'ep_TimerFcn_Stop';
        h.CONFIG.TIMER.Error   = 'ep_TimerFcn_Error';
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
    
    h.CONFIG.TIMER = cell2struct(a,{'Start';'RunTime';'Stop';'Error'});
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

function h = DefineSavingFcn(h,a)
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

h.CONFIG.SavingFcn = a;
guidata(h.figure1,h);

function h = DefineBoxFig(h,a)
if nargin == 2 && ~isempty(a) && ischar(a) && strcmp(a,'default')
    a = 'ep_BoxFig';
    
elseif ~isfield(h.CONFIG,'BoxFig') || isempty(h.CONFIG.BoxFig)
    % hardcoded default function
    h.CONFIG.BoxFig = 'ep_BoxFig';
    
    ontop = AlwaysOnTop(h);
    AlwaysOnTop(h,false);
    a = inputdlg('Box Figure','Specify Custom Box Figure:',1, ...
        {h.CONFIG.BoxFig});
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

h.CONFIG.BoxFig = a;
guidata(h.figure1,h);

function EditProtocol(h) %#ok<DEFNU>
idx = get(h.subject_list,'UserData');
if isempty(idx), return; end

AlwaysOnTop(h,false);
ep_ExperimentDesign(char(h.CONFIG(idx).PROTOCOL.protfile));

function subject_list_CellSelectionCallback(hObj,evnt,~) %#ok<DEFNU>
idx = evnt.Indices;
if isempty(idx)
    set(hObj,'UserData',[]);
else
    set(hObj,'UserData',idx(1))
end












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


