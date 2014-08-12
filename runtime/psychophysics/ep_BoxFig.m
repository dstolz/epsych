function varargout = ep_BoxFig(varargin)
% ep_BoxFig
% 
% Daniel.Stolzberg@gmail.com 2014

% Last Modified by GUIDE v2.5 11-Aug-2014 20:55:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ep_BoxFig_OpeningFcn, ...
                   'gui_OutputFcn',  @ep_BoxFig_OutputFcn, ...
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


% --- Executes just before ep_BoxFig is made visible.
function ep_BoxFig_OpeningFcn(hObj, ~, h, varargin)
% Choose default command line output for ep_BoxFig
h.output = hObj;

% Update h structure
guidata(hObj, h);

T = CreateTimer;

% UIWAIT makes ep_BoxFig wait for user response (see UIRESUME)
% uiwait(h.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ep_BoxFig_OutputFcn(hObj, ~, h) 

% Get default command line output from h structure
varargout{1} = h.output;






function T = CreateTimer
% Create new timer for RPvds control of experiment
delete(timerfind('Name','BoxTimer'));

T = timer('BusyMode','drop', ...
    'ExecutionMode','fixedSpacing', ...
    'Name','BoxTimer', ...
    'Period',1.0, ...
    'StartFcn',{@BoxTimerSetup}, ...
    'TimerFcn',{@BoxTimerRunTime}, ...
    'ErrorFcn',{@BoxTimerError}, ...
    'StopFcn', {@BoxTimerStop}, ...
    'TasksToExecute',inf);







function BoxTimerSetup(~,~)
global CONFIG



function BoxTimerRunTime(~,~)
global CONFIG

for i = 1:length(CONFIG)
    C = CONFIG(i);
    
    
end



function BoxTimerError(hObj,~)



function BoxTimerStop(~,~)


