function varargout = TOJ_Monitor(varargin)
% TOJ_MONITOR MATLAB code for TOJ_Monitor.fig
%      TOJ_MONITOR, by itself, creates a new TOJ_MONITOR or raises the existing
%      singleton*.
%
%      H = TOJ_MONITOR returns the handle to a new TOJ_MONITOR or the handle to
%      the existing singleton*.
%
%      TOJ_MONITOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TOJ_MONITOR.M with the given input arguments.
%
%      TOJ_MONITOR('Property','Value',...) creates a new TOJ_MONITOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before TOJ_Monitor_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to TOJ_Monitor_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help TOJ_Monitor

% Last Modified by GUIDE v2.5 20-May-2015 18:42:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TOJ_Monitor_OpeningFcn, ...
                   'gui_OutputFcn',  @TOJ_Monitor_OutputFcn, ...
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


% --- Executes just before TOJ_Monitor is made visible.
function TOJ_Monitor_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to TOJ_Monitor (see VARARGIN)

% Choose default command line output for TOJ_Monitor
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes TOJ_Monitor wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = TOJ_Monitor_OutputFcn(hObject, eventdata, h) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = h.output;

cla(h.axHistory);
set(h.PanSummary,'Title',['#TRIALS: ',0])
set(h.textCR,'String',['#CR: ',0])
set(h.textFA,'String',['#FA: ',0])
set(h.textHIT,'String',['#HIT: ',0])
set(h.textMISS,'String',['#MISS: ',0])

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


cols = {'Trial Type','Noise Delay','Flash Delay','Response','#NP','RespWinDelay(sec)'};


set(h.DataTable,'Data',{[],[],[],'',[],[]},'RowName','0','ColumnName',cols);






function BoxTimerRunTime(hObj,~,f)
global RUNTIME
persistent lastupdate starttime

if isempty(starttime), starttime = clock; end

h = guidata(f);

DATA = RUNTIME.TRIALS.DATA;

ntrials = length(DATA);

if isempty(DATA(1).TrialType) | ntrials == lastupdate, return; end

TrialType = [DATA.TrialType]';
NoiseDelay = [DATA.NoiseDelay]';
FlashDelay = [DATA.FlashDelay]';
NumNosePokes = [DATA.NumNosePokes]';
RespWindDelay = [DATA.RespWinDelay]'/1000; 

bitmask = [DATA.ResponseCode]';

HITind  = logical(bitget(bitmask,3));
MISSind = logical(bitget(bitmask,4));
FAind   = logical(bitget(bitmask,7));
CRind   = logical(bitget(bitmask,6));

TS = zeros(ntrials,1);
for i = 1:ntrials
    TS(i) = etime(DATA(i).ComputerTimestamp,starttime);
end
TS = TS / 60;

UpdateAxHistory(h.axHistory,TS,HITind,MISSind,FAind,CRind);
%set(h.axHistory,'XLim',[0,TS(i)+TS(i)/100])

Responses = cell(size(HITind));
Responses(HITind)  = {'Hit'};
Responses(MISSind) = {'Miss'};
Responses(FAind)   = {'FA'};
Responses(CRind)   = {'CR'};

D = cell(ntrials,4);
D(:,1) = num2cell(TrialType);
D(:,2) = num2cell(NoiseDelay);
D(:,3) = num2cell(FlashDelay);
D(:,4) = Responses;
D(:,5) = num2cell(NumNosePokes);
D(:,6) = num2cell(RespWindDelay);

D = flipud(D);

r = length(Responses):-1:1;
r = cellstr(num2str(r'));


set(h.DataTable,'Data',D,'RowName',r)

set(h.PanSummary,'Title',['#TRIALS: ',num2str(ntrials)])
set(h.textCR,'String',['#CR: ',num2str(sum(CRind))])
set(h.textFA,'String',['#FA: ',num2str(sum(FAind))])
set(h.textHIT,'String',['#HIT: ',num2str(sum(HITind))])
set(h.textMISS,'String',['#MISS: ',num2str(sum(MISSind))])

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

xlabel(ax,'time (min)');

