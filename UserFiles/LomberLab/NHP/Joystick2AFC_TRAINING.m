function varargout = Joystick2AFC_TRAINING(varargin)
% Joystick2AFC_TRAINING
% 
% Simple GUI for training Left/Right movements on a Joystick
%
% Daniel.Stolzberg@gmail.com 2016

% Last Modified by GUIDE v2.5 31-Jan-2016 22:30:20

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Joystick2AFC_TRAINING_OpeningFcn, ...
                   'gui_OutputFcn',  @Joystick2AFC_TRAINING_OutputFcn, ...
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


% --- Executes just before Joystick2AFC_TRAINING is made visible.
function Joystick2AFC_TRAINING_OpeningFcn(hObj, ~, h, varargin)

% Choose default command line output for Joystick2AFC_TRAINING
h.output = hObj;

% Update h structure
guidata(hObj, h);


% --- Outputs from this function are returned to the command line.
function varargout = Joystick2AFC_TRAINING_OutputFcn(hObj, ~, h) 
% Get default command line output from h structure
varargout{1} = h.output;

cla(h.axPerformance);
set(h.axPerformance,'xtick',[1 2],'xticklabel',{'Left 0','Right 0'});
title(h.axPerformance,'Total: 0');

T = CreateTimer(hObj);

start(T);






% Timer Functions --------------------------------------

function T = CreateTimer(f)
% Create new timer for RPvds control of experiment
T = timerfind('Name','BoxTimer');
if ~isempty(T)
    stop(T);
    delete(T);
end

T = timer('BusyMode','drop', ...
    'ExecutionMode','fixedSpacing', ...
    'Name','BoxTimer', ...
    'Period',0.05, ...
    'StartFcn',{@BoxTimerSetup,f}, ...
    'TimerFcn',{@BoxTimerRunTime,f}, ...
    'ErrorFcn',{@BoxTimerError}, ...
    'StopFcn', {@BoxTimerStop}, ...
    'TasksToExecute',inf, ...
    'StartDelay',0);


function BoxTimerSetup(~,~,f)

h = guidata(f);

% Initalize using both directions
EnableDirections(h.enable_Both,h,'both')

set(h.lblInfo,'String',sprintf('# Contacts: 0\nDelivered: 0.0 ml'));

function BoxTimerRunTime(~,~,f)
% global variables
% RUNTIME contains info about currently running experiment including trial data collected so far
% AX is the ActiveX control being used

global RUNTIME AX
persistent lastupdate  % persistent variables hold their values across calls to this function

try
    % number of trials is length of
    ntrials = RUNTIME.TRIALS.DATA(end).TrialID;
    
    if isempty(ntrials)
        ntrials = 0;
        lastupdate = 0;
    end
    
    
catch me
    % good place to put a breakpoint for debugging
    rethrow(me)    
end

% retrieve figure handles structure
h = guidata(f);

JV = AX.GetTargetVal('Joystick.*JoystickV');
set(h.lblJoystickV,'String',sprintf('Joystick V = % 4.2f',JV));

% Number of valid joystick contacts
nContacts = AX.GetTargetVal('TRAINING.*NumContacts');
InfoStr = sprintf('# Contacts: %d',nContacts);


% Reward duration
RewardSamps = AX.GetTargetVal('TRAINING.*RewardSamps');
RewardDur = RewardSamps / 48828.125;
RewardEst = round(10*RewardDur*1000 / 5263)/10;

InfoStr = sprintf('%s\nDelivered: %0.1f ml',InfoStr,RewardEst);

set(h.lblInfo,'String',InfoStr)


% escape until a new trial has been completed
if ntrials == lastupdate,  return; end
lastupdate = ntrials;


% copy DATA structure to make it easier to use
DATA = RUNTIME.TRIALS.DATA;

% Use Response Code bitmask to compute performance
RCode_bitmask = [DATA.ResponseCode]';

LEFTIND  = logical(bitget(RCode_bitmask,6));
RIGHTIND = logical(bitget(RCode_bitmask,7));

nLeft = sum(LEFTIND);
nRight = sum(RIGHTIND);

bar(h.axPerformance,[1 2],[nLeft nRight]);
set(h.axPerformance,'xtick',[1 2],'xticklabel', ...
    {sprintf('Left %d',nLeft),sprintf('Right %d',nRight)})
grid(h.axPerformance,'on');

title(h.axPerformance,sprintf('Total: %d',nLeft+nRight))






function BoxTimerError(~,~)
disp('BoxERROR');


function BoxTimerStop(~,~)









function EnableDirections(hObj,h,direction)
global AX
set([h.enable_Both,h.enable_LeftOnly,h.enable_RightOnly],'ForegroundColor','k')
set(hObj,'ForegroundColor','g');

switch direction
    case 'both'
        AX.SetTargetVal('TRAINING.*EnableRight',1);
        AX.SetTargetVal('TRAINING.*EnableLeft',1);
    case 'rightonly'
        AX.SetTargetVal('TRAINING.*EnableLeft',0);
        AX.SetTargetVal('TRAINING.*EnableRight',1);
    case 'leftonly'
        AX.SetTargetVal('TRAINING.*EnableRight',0);
        AX.SetTargetVal('TRAINING.*EnableLeft',1);
        
end







% Button Functions -----------------------------------------------
function TrigWater(hObj,~) %#ok<DEFNU>
global AX RUNTIME 

% AX is the handle to either the OpenDeveloper (if using OpenEx) or RPvds
% (if not using OpenEx) ActiveX controls

c = get(hObj,'BackgroundColor');
set(hObj,'BackgroundColor','r'); drawnow

if RUNTIME.UseOpenEx
    AX.SetTargetVal('TRAINING.*Water_Trig_Dur',750);
    AX.SetTargetVal('TRAINING.!Water_Trig',1);
    while AX.GetTargetVal('TRAINING.*Rewarding')
        pause(0.1);
    end
    AX.SetTargetVal('TRAINING.!Water_Trig',0);
else
    AX.SetTagVal('!Water_Trig',1);
    while AX.GetTagVal('*Rewarding')
        pause(0.1);
    end
    AX.SetTagVal('!Water_Trig',0);
end

set(hObj,'BackgroundColor',c);












