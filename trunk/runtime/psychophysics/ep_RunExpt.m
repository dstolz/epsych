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

h.C = [];

PRGMSTATE = 'NOCONFIG';

guidata(hObj, h);

UpdateGUIstate(h);

% elevate Matlab.exe process to a high priority in Windows
[~,~] = dos('wmic process where name="MATLAB.exe" CALL setpriority "high priority"');

% --- Outputs from this function are returned to the command line.
function varargout = ep_RunExpt_OutputFcn(hObj, ~, h) 
varargout{1} = h.output;











%%
function ExptDispatch(hObj,h) %#ok<DEFNU>
tag = get(hObj,'tag');

ontop = getpref('ep_RunExpt','AlwaysOnTop',false);
AlwaysOnTop(h,false)

switch tag
    case 'ctrl_run'
        BeginExpt(h);
    case 'ctrl_preview'
        BeginExpt(h);
    case 'ctrl_pause'
    case 'ctrl_halt'
end
AlwaysOnTop(h,ontop)

function BeginExpt(h)
global PRGMSTATE CONFIG G_RP G_DA

% Launch Box figure to display information during experiment
% h.BoxFig = ep_BoxFig;

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



function PsychTimerStart(hObj,evnt)
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

function PsychTimerRunTime(hObj,evnt)
global CONFIG G_RP G_DA
CONFIG = feval(CONFIG(1).TIMER.RunTime,CONFIG,G_RP,G_DA);

function PsychTimerError(hObj,evnt)
global CONFIG G_RP G_DA PRGMSTATE
PRGMSTATE = 'ERROR';

CONFIG(1).ERROR = lasterror;

CONFIG = feval(CONFIG(1).TIMER.Error,CONFIG,G_RP,G_DA);

feval(CONFIG(1).SavingFcn,CONFIG);

UpdateGUIstate(guidata(hObj));

SaveDataCallback(h);

function PsychTimerStop(hObj,evnt)
global CONFIG G_RP G_DA PRGMSTATE
PRGMSTATE = 'STOP';

CONFIG = feval(CONFIG(1).TIMER.Stop,CONFIG,G_RP,G_DA);

feval(CONFIG(1).SavingFcn,CONFIG);

UpdateGUIstate(guidata(hObj));

SaveDataCallback(h);



















% Setup------------------------------------------------------


function CreateBoxFig
% Find and close box figures which are not in use


% create and populate GUI based on CONFIG.  Maybe loop-call an external
% function to generate GUIs


function LoadConfig(h) %#ok<DEFNU>
global PRGMSTATE

pn = getpref('ep_PsychConfig','CDir',cd);
[fn,pn] = uigetfile('*.config','Open Configuration File',pn);
if ~fn, return; end
setpref('ep_PsychConfig','CDir',pn);

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

% make config structure easier to address during runtime
if isfield(h,'C'), h = rmfield(h,'C'); end

tC.COMPILED = [config.PROTOCOL.COMPILED];
tC.OPTIONS  = [config.PROTOCOL.OPTIONS];
tC.MODULES  = {config.PROTOCOL.MODULES};
tC.SUBJECT  = [config.SUBJECT];
for i = 1:length(config.SUBJECT)
    h.C(i) = structfun(@(x) (x(i)),tC,'UniformOutput',false);
end

h.C(1).TIMER  = config.TIMER;
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

PRGMSTATE = 'CONFIGLOADED';
UpdateGUIstate(h);

set(h.config_file,'String',fn,'tooltipstring',pn);




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

hCtrl = findobj(h,'-regexp','tag','^ctrl');
set([hCtrl,h.locate_config_file,h.save_data],'Enable','off');

switch PRGMSTATE
    case 'NOCONFIG'
        set(h.locate_config_file,'Enable','on');
        
    case 'CONFIGLOADED'
        PRGMSTATE = 'READY';
        guidata(h.figure1,h);
        UpdateGUIstate(h);
        
    case 'READY'
        set([h.ctrl_run,h.ctrl_preview],'Enable','on');
        
    case 'RUNNING'
        set([h.ctrl_pauseall,h.ctrl_halt],'Enable','on');
        
    case 'STOP'
        set([h.save_data,h.ctrl_run,h.ctrl_preview,h.locate_config_file],'Enable','on');
        
    case 'ERROR'
        set([h.save_data,h.ctrl_run,h.ctrl_preview,h.locate_config_file],'Enable','on');     
end
    
drawnow





function AlwaysOnTop(h,ontop)

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
