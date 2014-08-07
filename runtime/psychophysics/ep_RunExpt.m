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
function ExptDispatch(type,h) %#ok<DEFNU>
global PRGMSTATE 


BoxFigs = CreateBoxFix(h.C.SUBJECT);

if h.UseOpenEx
    % launch modal figure with TDT ActiveX GUI
    
    
else
    if isfield(h,'RP'), delete(h.RP); h = rmfield(h,'RP'); end

    [h.RP,h.C] = SetupRPexpt(h.C);
    
    % Store RP with ep_RunExpt in case anyone wants to access it from
    % outside this program
    setappdata(h.figure1,'RP',RP);
end

T = CreateTimer(BoxFigs,h.RP,h.C);

start(T); % Begin Experiment

PRGMSTATE = 'RUNNING';

UpdateGUIstate(h);






% Timer Functions-------------------------------------------------------
function T = CreateTimer(f, RP, CONFIG)
% Create new timer for RPvds control of experiment
delete(timerfind('Name','PsychTimer'));

T = timer('BusyMode','queue', ...
    'ExecutionMode','fixedSpacing', ...
    'Name','PsychTimer', ...
    'Period',0.1, ...
    'StartFcn',{@PsychRPTimerStart,  f, CONFIG}, ...
    'TimerFcn',{@PsychRPTimerRuntime,f, RP}, ...
    'ErrorFcn',{@PsychRPTimerError,  f, RP}, ...
    'StopFcn', {@PsychRPTimerStop,   f, RP}, ...
    'UserData',{f, RP}, ...
    'TasksToExecute',inf);





function PsychTimerStart(~,~,BoxFigs,CONFIG) %#ok<DEFNU>
for i = 1:length(BoxFigs)
    C = CONFIG(i);
 
    % Initalize C.TrialCount
    C.TrialCount = zeros(size(C.COMPILED.trials,1),1);

    % Initialize first trial
    C = feval(C.OPTIONS.trialfunc,C);
    
    UpdateRPtags(RP,C,C.NextIndex);

    
    % Initialize C.DATA with null values 
    % (truncate or expand later as needed)
    for mrp = C.COMPILED.Mreadparams
        C.DATA.(char(mrp)) = nan(500,1);
    end
    
    % Store CONFIG structure with corresponding box figure
    setappdata(BoxFigs(i),'C',C);


    
    % TO DO: OPEN FILE FOR SAVING DATA COLLECTED DURING RUNTIME
end




function PsychRPTimerRuntime(~,~,BoxFigs,RP)

for i = 1:length(BoxFigs)
    C = getappdata(BoxFigs,'CONFIG');
    
    BoxID = C.SUBJECT.BoxID;
    
    % Check #RespCode parameter for non-zero value or if #InTrial is true
    RCtag = sprintf('#RespCode~%d',BoxID);
    ITtag = sprintf('#InTrial~%d',BoxID);
    S = ReadRPtags(RP,C,{RCtag,ITtag});
    if ~S.(RCtag) || S.(ITtag), continue; end
    
    
    % There was a response and the trial is over.
    % Retrieve parameter data from RPvds circuits
    C.DATA(end+1) = ReadRPtags(RP,C);
   
    
    % Store CONFIG structure with corresponding box figure
    setappdata(BoxFigs(i),'C');

    
    % TO DO: SAVE NEWLY ACQUIRED DATA TO FILE ON HDD IN CASE OF ERROR
    %        THIS SHOULD BE DONE VERY QUICKLY SO AS NOT TO INTERRUPT
    %        PROCESSING OF OTHER BOXES
   
    
    
    % Call function(s) to update BoxFig
%     feval(@UpdateBoxFig,BoxFigs(i));
    


    % Select next trial
    C = feval(C.OPTIONS.trialfunc,C,true);
    
end




















% Setup------------------------------------------------------


function BoxFigs = CreateBoxFigs(SUBJECT)
BoxFigs = findobj('type','figure','-and','-regexp','name','^ep_Box*');

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

if isappdata(h.figure1,'RP'), rmappdata(h.figure1,'RP'); end


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
    




