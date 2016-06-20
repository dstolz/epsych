function varargout = DRAFT_Headtracker_Behavior(varargin)
% DRAFT_HEADTRACKER_BEHAVIOR MATLAB code for DRAFT_Headtracker_Behavior.fig
%      DRAFT_HEADTRACKER_BEHAVIOR, by itself, creates a new DRAFT_HEADTRACKER_BEHAVIOR or raises the existing
%      singleton*.
%
%      H = DRAFT_HEADTRACKER_BEHAVIOR returns the handle to a new DRAFT_HEADTRACKER_BEHAVIOR or the handle to
%      the existing singleton*.
%
%      DRAFT_HEADTRACKER_BEHAVIOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DRAFT_HEADTRACKER_BEHAVIOR.M with the given input arguments.
%
%      DRAFT_HEADTRACKER_BEHAVIOR('Property','Value',...) creates a new DRAFT_HEADTRACKER_BEHAVIOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before DRAFT_Headtracker_Behavior_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to DRAFT_Headtracker_Behavior_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help DRAFT_Headtracker_Behavior

% Last Modified by GUIDE v2.5 30-Mar-2016 14:02:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DRAFT_Headtracker_Behavior_OpeningFcn, ...
                   'gui_OutputFcn',  @DRAFT_Headtracker_Behavior_OutputFcn, ...
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


% --- Executes just before DRAFT_Headtracker_Behavior is made visible.
function DRAFT_Headtracker_Behavior_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for DRAFT_Headtracker_Behavior
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes DRAFT_Headtracker_Behavior wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = DRAFT_Headtracker_Behavior_OutputFcn(hObject, eventdata, handles) 
% Get default command line output from handles structure
varargout{1} = handles.output;












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


inResponseWindow = AX.GetTagVal('*RespWindow');


if inResponseWindow
   %  
    
end
    
    
    
    
    
    

% escape until a new trial has been completed
if ntrials == lastupdate,  return; end
lastupdate = ntrials;


% copy DATA structure to make it easier to use
DATA = RUNTIME.TRIALS.DATA;

% Use Response Code bitmask to compute performance
RCode = [DATA.ResponseCode]';





function BoxTimerError(~,~)
% disp('BoxERROR');


function BoxTimerStop(~,~)
















