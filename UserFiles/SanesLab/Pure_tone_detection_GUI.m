function varargout = Pure_tone_detection_GUI(varargin)
% PURE_TONE_DETECTION_GUI MATLAB code for Pure_tone_detection_GUI.fig
%      PURE_TONE_DETECTION_GUI, by itself, creates a new PURE_TONE_DETECTION_GUI or raises the existing
%      singleton*.
%
%      H = PURE_TONE_DETECTION_GUI returns the handle to a new PURE_TONE_DETECTION_GUI or the handle to
%      the existing singleton*.
%
%      PURE_TONE_DETECTION_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PURE_TONE_DETECTION_GUI.M with the given input arguments.
%
%      PURE_TONE_DETECTION_GUI('Property','Value',...) creates a new PURE_TONE_DETECTION_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Pure_tone_detection_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Pure_tone_detection_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Pure_tone_detection_GUI

% Last Modified by GUIDE v2.5 21-May-2015 13:29:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Pure_tone_detection_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @Pure_tone_detection_GUI_OutputFcn, ...
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


% --- Executes just before Pure_tone_detection_GUI is made visible.
function Pure_tone_detection_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Pure_tone_detection_GUI (see VARARGIN)

% Choose default command line output for Pure_tone_detection_GUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Pure_tone_detection_GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Pure_tone_detection_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


T = CreateTimer(hObject);

start(T);








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
    'Period',1, ...
    'StartFcn',{@BoxTimerSetup,f}, ...
    'TimerFcn',{@BoxTimerRunTime,f}, ...
    'ErrorFcn',{@BoxTimerError}, ...
    'StopFcn', {@BoxTimerStop}, ...
    'TasksToExecute',inf, ...
    'StartDelay',2);





function BoxTimerSetup(hObj,~,f)

h = guidata(f);

cols = {'Trial Type','Silent Delay','Response'};
set(h.DataTable,'Data',{[],[],''},'RowName','0','ColumnName',cols);

nexttrial_cols = {'Trial Type','Silent Delay'};
set(h.NextTrial,'Data',{[],[]},'RowName','NextTrial','ColumnName',nexttrial_cols);




function BoxTimerRunTime(hObj,~,f)
global RUNTIME USERDATA
persistent lastupdate starttime

if isempty(starttime), starttime = clock; end

h = guidata(f);

% DATA structure
DATA = RUNTIME.TRIALS.DATA; 

ntrials = length(DATA);



% Check if a new trial has been completed
if (RUNTIME.UseOpenEx && isempty(DATA(1).Behavior_TrialType)) ...
        || (~RUNTIME.UseOpenEx && isempty(DATA(1).TrialType)) ...
        | ntrials == lastupdate
    return
end

NextTrialData = {USERDATA.TrialType,USERDATA.SilentDelay};
set(h.NextTrial,'Data',NextTrialData);

if RUNTIME.UseOpenEx
    TrialType = [DATA.Behavior_TrialType]';
    SilentDelay = [DATA.Behavior_Silent_delay]';
else
    TrialType = [DATA.TrialType]';
    SilentDelay = [Data.Silent_delay]';
end

bitmask = [DATA.ResponseCode]';

HITind  = logical(bitget(bitmask,1));
MISSind = logical(bitget(bitmask,2));
FAind   = logical(bitget(bitmask,4));
CRind   = logical(bitget(bitmask,3));

TS = zeros(ntrials,1);
for i = 1:ntrials
    TS(i) = etime(DATA(i).ComputerTimestamp,starttime);
end

UpdateAxHistory(h.axHistory,TS,HITind,MISSind,FAind,CRind);



Responses = cell(size(HITind));
Responses(HITind)  = {'Hit'};
Responses(MISSind) = {'Miss'};
Responses(FAind)   = {'FA'};
Responses(CRind)   = {'CR'};

D = cell(ntrials,4);
D(:,1) = num2cell(TrialType);
D(:,2) = num2cell(SilentDelay);
D(:,3) = Responses;

D = flipud(D); % flip table data so the recent trials are on top

r = length(Responses):-1:1;
r = cellstr(num2str(r'));


set(h.DataTable,'Data',D,'RowName',r)


lastupdate = ntrials;





function BoxTimerError(~,~)



function BoxTimerStop(~,~)














function UpdateAxHistory(ax,TS,HITind,MISSind,FAind,CRind)
cla(ax)

hold(ax,'on')
plot(ax,TS(HITind),ones(sum(HITind,1)),'go','markerfacecolor','g');
plot(ax,TS(MISSind),ones(sum(MISSind,1)),'rs','markerfacecolor','r');
plot(ax,TS(FAind),zeros(sum(FAind,1)),'rs','markerfacecolor','r');
plot(ax,TS(CRind),zeros(sum(CRind,1)),'go','markerfacecolor','g');
hold(ax,'off');

set(ax,'ytick',[0 1],'yticklabel',{'STD','DEV'},'ylim',[-0.1 1.1]);







