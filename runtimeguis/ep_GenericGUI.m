function varargout = ep_GenericGUI(varargin)
% EP_GENERICGUI MATLAB code for ep_GenericGUI.fig
%      EP_GENERICGUI, by itself, creates a new EP_GENERICGUI or raises the existing
%      singleton*.
%
%      H = EP_GENERICGUI returns the handle to a new EP_GENERICGUI or the handle to
%      the existing singleton*.
%
%      EP_GENERICGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EP_GENERICGUI.M with the given input arguments.
%
%      EP_GENERICGUI('Property','Value',...) creates a new EP_GENERICGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ep_GenericGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ep_GenericGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ep_GenericGUI

% Last Modified by GUIDE v2.5 25-Apr-2017 19:56:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ep_GenericGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ep_GenericGUI_OutputFcn, ...
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


% --- Executes just before ep_GenericGUI is made visible.
function ep_GenericGUI_OpeningFcn(hObj, ~, h, varargin)
h.output = hObj;
guidata(hObj, h);



% --- Outputs from this function are returned to the command line.
function varargout = ep_GenericGUI_OutputFcn(hObj, ~, h) 
varargout{1} = h.output;


T = CreateTimer(hObj);
start(T);

















% GUITimer ---------------------------------------------------------
function T = CreateTimer(f)
% Create new timer for RPvds control of experiment
T = timerfind('Name','GUITimer');
if ~isempty(T)
    stop(T);
    delete(T);
end

T = timer('BusyMode','drop', ...
    'ExecutionMode','fixedSpacing', ...
    'Name','GUITimer', ...
    'Period',0.05, ...
    'StartFcn',{@GUITimerSetup,f}, ...
    'TimerFcn',{@GUITimerRunTime,f}, ...
    'ErrorFcn',{@GUITimerError}, ...
    'StopFcn', {@GUITimerStop}, ...
    'TasksToExecute',inf, ...
    'StartDelay',0);




function GUITimerSetup(T,~,f)

h = guidata(f);

global RUNTIME

if isempty(T.UserData)
    T.UserData = clock; % start time
end


h.tbl_TrialHistory



function GUITimerRunTime(T,~,f)
% global variables
% > RUNTIME contains info about currently running experiment including
% trial data collected so far.
% > AX is the ActiveX control being used.  Gives direct programmatic access
% to running RPvds circuit(s)

global RUNTIME AX 
persistent lastupdate % persistent variables hold their values across calls to this function



% AX changes class if an error occurred during runtime
if isempty(AX) || ~isa(AX,'COM.TDevAcc_X'), stop(T); return; end


% number of trials is length of
ntrials = RUNTIME.TRIALS.DATA(end).TrialID;

if isempty(ntrials)
    ntrials = 0;
    lastupdate = 0;
end

    
% escape timer function until a trial has finished
if ntrials == lastupdate,  return; end
% ````````````````````````````````````````````````````````
lastupdate = ntrials;


% copy DATA structure to make it easier to use
DATA = RUNTIME.TRIALS.DATA;

    
% Use Response Code bitmask to compute performance
RCode = [DATA.ResponseCode];

% retrieve figure handles structure
h = guidata(f);















