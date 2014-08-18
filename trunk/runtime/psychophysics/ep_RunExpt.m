function varargout = ep_RunExpt(varargin)


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

h.CONFIG = [];

PRGMSTATE = 'NOCONFIG';

guidata(hObj, h);

UpdateGUIstate(h);

% elevate Matlab.exe process to a high priority in Windows
[~,~] = dos('wmic process where name="MATLAB.exe" CALL setpriority "high priority"');

% --- Outputs from this function are returned to the command line.
function varargout = ep_RunExpt_OutputFcn(hObj, ~, h) 
varargout{1} = h.output;








%%
function ExptDispatch(h) %#ok<DEFNU>
global PRGMSTATE CONFIG G_RP G_DA


BoxFig = CreateBoxFix(h.C.SUBJECT);

if h.UseOpenEx
        
    [G_DA,CONFIG] = SetupDAexpt(h.C);
    if isempty(G_DA), return; end
    
    T = CreateDATimer;
    
else

    [G_RP,CONFIG] = SetupRPexpt(h.C);  
    if isempty(G_RP), return; end
    
    T = CreateRPTimer;
end


start(T); % Begin Experiment

PRGMSTATE = 'RUNNING';

UpdateGUIstate(h);


% DA Timer Functions-------------------------------------------------------
function T = CreateDATimer
% Create new timer for RPvds control of experiment
delete(timerfind('Name','PsychTimer'));

T = timer('BusyMode','queue', ...
    'ExecutionMode','fixedSpacing', ...
    'Name','PsychTimer', ...
    'Period',0.1, ...
    'StartFcn',{@PsychDATimerStart}, ...
    'TimerFcn',{@PsychDATimerRuntime,BoxFig}, ...
    'ErrorFcn',{@PsychDATimerError}, ...
    'StopFcn', {@PsychDATimerStop}, ...
    'TasksToExecute',inf);



function PsychDATimerError(hObj,evnt)
global PRGMSTATE
PRGMSTATE = 'ERROR';

% TO DO: Error handling

function PsychDATimerStop(hObj,evnt)
global PRGMSTATE G_DA


G_DA.


PRGMSTATE = 'STOP';

% TO DO: Cleanup


function PsychDATimerStart(~,~)


function PsychDATimerRuntime(~,~)











% RP Timer Functions-------------------------------------------------------
function T = CreateRPTimer
% Create new timer for RPvds control of experiment
delete(timerfind('Name','PsychTimer'));

T = timer('BusyMode','queue', ...
    'ExecutionMode','fixedSpacing', ...
    'Name','PsychTimer', ...
    'Period',0.1, ...
    'StartFcn',{@PsychRPTimerStart}, ...
    'TimerFcn',{@PsychRPTimerRuntime}, ...
    'ErrorFcn',{@PsychRPTimerError}, ...
    'StopFcn', {@PsychRPTimerStop}, ...
    'TasksToExecute',inf);



function PsychRPTimerError(hObj,evnt)
global PRGMSTATE
PRGMSTATE = 'ERROR';

% TO DO: Error handling

function PsychRPTimerStop(hObj,evnt)
global PRGMSTATE
PRGMSTATE = 'STOP';

% TO DO: Cleanup


function PsychRPTimerStart(~,~)
global CONFIG G_RP
% Initialize parameters and take care of some other things just before
% beginning experiment

% make temporary directory in current folder for storing data during
% runtime in case of a computer crash or Matlab error
if ~isfield(CONFIG(1),'RunTimeDataDir') || ~isdir(CONFIG(1).RunTimeDataDir)
    CONFIG(1).RunTimeDataDir = [cd filesep 'RunTimeDATA'];
end
if ~isdir(CONFIG(1).RunTimeDataDir), mkdir(CONFIG(1).RunTimeDataDir); end

for i = 1:length(CONFIG)
    C = CONFIG(i);
 
    % Initalize C.TrialCount
    C.TrialCount = zeros(size(C.COMPILED.trials,1),1);

    % Initialize first trial
    C = feval(C.OPTIONS.trialfunc,C);
    
    e = UpdateRPtags(G_RP,C);

    
    % Initialize C.DATA
    for mrp = C.COMPILED.Mreadparams
        C.DATA.(char(mrp)) = [];
    end
    

    % Create data file for saving data during runtime in case there is a problem
    % * this file will automatically be overwritten
    C.RunTimeDataDir  = CONFIG(1).RunTimeDataDir;
    dfn = sprintf('TEMP_DATA_%s_Box_%02d.mat',genvarname(C.SUBJECT.Name),C.SUBJECT.BoxID);
    C.RunTimeDataFile = fullfile(C.RunTimeDataDir,dfn);
    
    
    % Store CONFIG structure with corresponding box figure
    C.BOXLABEL = sprintf('CONFIG_%02d',C.SUBJECT.BoxID);
    setappdata(BoxFig,C.BOXLABEL,C);
end




function PsychRPTimerRuntime(~,~)
global CONFIG G_RP

for i = 1:length(CONFIG)
    C = CONFIG(i);
    
    BoxID = C.SUBJECT.BoxID;
    
    % Check #RespCode parameter for non-zero value or if #InTrial is true
    RCtag = sprintf('#RespCode~%d',BoxID);
    ITtag = sprintf('#InTrial~%d',BoxID);
    S = ReadRPtags(G_RP,C,{RCtag,ITtag});
    if ~S.(RCtag) || S.(ITtag), continue; end
    
    
    % There was a response and the trial is over.
    % Retrieve parameter data from RPvds circuits
    C.DATA(end+1) = ReadRPtags(G_RP,C);
   
    
    % Save runtime data in case of crash
    save(C.RunTimeDataFile,'C','-v6'); % -v6 is much faster because it doesn't use compression  


    % Select next trial with default or custom function
    C = feval(C.OPTIONS.trialfunc,C,true);
    
    % Update parameters for next trial
    e = UpdateRPTags(RP,C);
end




















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

% make config structure easier to address later on 
tC.COMPILED = [config.PROTOCOL.COMPILED];
tC.OPTIONS  = [config.PROTOCOL.OPTIONS];
tC.MODULES  = {config.PROTOCOL.MODULES};
tC.SUBJECT  = [config.SUBJECT];
if isfield(h,'C'), h = rmfield(h,'C'); end
for i = 1:length(config.SUBJECT)
    h.C(i) = structfun(@(x) (x(i)),tC,'UniformOutput',false);
end

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











function UpdateGUIstate(h)
global PRGMSTATE

hCtrl = findobj(h,'-regexp','tag','^ctrl');
set([hCtrl,h.locate_config_file],'Enable','off');

switch PRGMSTATE
    case 'NOCONFIG'
        set(h.locate_config_file,'Enable','on');
        
    case 'CONFIGLOADED'
        if h.UseOpenEx
            
        else
            PRGMSTATE = 'READY';
            guidata(h.figure1,h);
            UpdateGUIstate(h);
        end
        
    case 'READY'
        set([h.ctrl_run,h.ctrl_preview],'Enable','on');
        
    case 'RUNNING'
        set([h.ctrl_pauseall,h.ctrl_halt],'Enable','on');
        
    case 'HALTED'
        set([h.ctrl_run,h.ctrl_preview,h.locate_config_file],'Enable','on');
        
end
    




