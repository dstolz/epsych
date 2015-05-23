function varargout = StimDetect_Monitor(varargin)
% STIMDETECT_MONITOR MATLAB code for StimDetect_Monitor.fig
%      STIMDETECT_MONITOR, by itself, creates a new STIMDETECT_MONITOR or raises the existing
%      singleton*.
%
%      H = STIMDETECT_MONITOR returns the handle to a new STIMDETECT_MONITOR or the handle to
%      the existing singleton*.
%
%      STIMDETECT_MONITOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in STIMDETECT_MONITOR.M with the given input arguments.
%
%      STIMDETECT_MONITOR('Property','Value',...) creates a new STIMDETECT_MONITOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before StimDetect_Monitor_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to StimDetect_Monitor_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help StimDetect_Monitor

% Last Modified by GUIDE v2.5 22-May-2015 16:02:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @StimDetect_Monitor_OpeningFcn, ...
                   'gui_OutputFcn',  @StimDetect_Monitor_OutputFcn, ...
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


% --- Executes just before StimDetect_Monitor is made visible.
function StimDetect_Monitor_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to StimDetect_Monitor (see VARARGIN)

% Choose default command line output for StimDetect_Monitor
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes StimDetect_Monitor wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = StimDetect_Monitor_OutputFcn(hObject, eventdata, handles) 
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


cols = {'Trial Type','Speaker ID','Tone Frequency','Tone SPL','Response Latency','Response'};


set(h.DataTable,'Data',{[],[],[],[],[],''},'RowName','0','ColumnName',cols);


cla(h.axHistory);
cla(h.axFunc);





function BoxTimerRunTime(hObj,~,f)
global RUNTIME
persistent lastupdate starttime

if isempty(starttime), starttime = clock; end

h = guidata(f);

DATA = RUNTIME.TRIALS.DATA;

ntrials = length(DATA);

if isempty(DATA(1).Behavior_TrialType) | ntrials == lastupdate, return; end

TrialType = [DATA.Behavior_TrialType]';
SpeakerID = [DATA.Behavior_DAC_Channel]';
ToneFreq  = [DATA.Behavior_Freq]';
ToneSPL   = [DATA.Behavior_Tone_dB]';
RespLat   = [DATA.Behavior_RespLatency]';

bitmask = [DATA.ResponseCode]';

HITind  = logical(bitget(bitmask,3));
MISSind = logical(bitget(bitmask,4));
FAind   = logical(bitget(bitmask,7));
CRind   = logical(bitget(bitmask,6));

TS = zeros(ntrials,1);
for i = 1:ntrials
    TS(i) = etime(DATA(i).ComputerTimestamp,starttime);
end

UpdateAxHistory(h.axHistory,TS,HITind,MISSind,FAind,CRind);

uSpkr = unique(SpeakerID);
Performance = zeros(size(uSpkr));
for i = 1:length(uSpkr)
    ind = SpeakerID == uSpkr(i);
    Performance(i) = sum(HITind(ind))/sum(ind);
end

UpdateAxFunc(h.axFunc,uSpkr,Performance);

Responses = cell(size(HITind));
Responses(HITind)  = {'Hit'};
Responses(MISSind) = {'Miss'};
Responses(FAind)   = {'FA'};
Responses(CRind)   = {'CR'};

D = cell(ntrials,4);
D(:,1) = num2cell(TrialType);
D(:,2) = num2cell(SpeakerID);
D(:,3) = num2cell(ToneFreq);
D(:,4) = num2cell(ToneSPL);
D(:,5) = num2cell(RespLat);
D(:,6) = Responses;

D = flipud(D);

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

set(ax,'ytick',[0 1],'yticklabel',{'STD','DEV'},'ylim',[-0.1 1.1])





function UpdateAxFunc(ax,SpkrID,Performance)
cla(ax)

th = SpkrID*pi/180;

h = polar(ax,th,Performance,'-ob');
set(h,'markerfacecolor','b');

hold(ax,'on');

g = findall(gcf,'type','line','-and','-not','color','b');
delete(g)

for i = 1:length(th)
    h(i) = polar(ax,[1 1]*th(i),[0 1]);
end
set(h,'color',[0.6 0.6 0.6]);

hold(ax,'off');











