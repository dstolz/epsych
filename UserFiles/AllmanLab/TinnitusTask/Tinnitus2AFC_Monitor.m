function varargout = Tinnitus2AFC_Monitor(varargin)
% TINNITUS2AFC_MONITOR MATLAB code for Tinnitus2AFC_Monitor.fig
%      TINNITUS2AFC_MONITOR, by itself, creates a new TINNITUS2AFC_MONITOR or raises the existing
%      singleton*.
%
%      H = TINNITUS2AFC_MONITOR returns the handle to a new TINNITUS2AFC_MONITOR or the handle to
%      the existing singleton*.
%
%      TINNITUS2AFC_MONITOR('CALLBACK',hObj,e,h,...) calls the local
%      function named CALLBACK in TINNITUS2AFC_MONITOR.M with the given input arguments.
%
%      TINNITUS2AFC_MONITOR('Property','Value',...) creates a new TINNITUS2AFC_MONITOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Tinnitus2AFC_Monitor_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Tinnitus2AFC_Monitor_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIh

% Edit the above text to modify the response to help Tinnitus2AFC_Monitor

% Last Modified by GUIDE v2.5 02-Jul-2015 18:26:28

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Tinnitus2AFC_Monitor_OpeningFcn, ...
                   'gui_OutputFcn',  @Tinnitus2AFC_Monitor_OutputFcn, ...
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


% --- Executes just before Tinnitus2AFC_Monitor is made visible.
function Tinnitus2AFC_Monitor_OpeningFcn(hObj, e, h, varargin)
% This function has no output args, see OutputFcn.
% hObj    handle to figure
% e  reserved - to be defined in a future version of MATLAB
% h    structure with h and user data (see GUIDATA)
% varargin   command line arguments to Tinnitus2AFC_Monitor (see VARARGIN)

% Choose default command line output for Tinnitus2AFC_Monitor
h.output = hObj;

% Update h structure
guidata(hObj, h);

% UIWAIT makes Tinnitus2AFC_Monitor wait for user response (see UIRESUME)
% uiwait(h.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Tinnitus2AFC_Monitor_OutputFcn(hObj, e, h) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObj    handle to figure
% e  reserved - to be defined in a future version of MATLAB
% h    structure with h and user data (see GUIDATA)

% Get default command line output from h structure
varargout{1} = h.output;

cla(h.axHistory);
set(h.PanSummary,'Title', ['#TRIALS: ',0])
set(h.textLefts,'String', ['#A: ',0])
set(h.textRights,'String',['#B: ',0])
set(h.textHIT,'String',   ['#HIT: ',0])
set(h.textMISS,'String',  ['#MISS: ',0])

T = CreateTimer(hObj);

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
    'Period',0.1, ...
    'StartFcn',{@BoxTimerSetup,f}, ...
    'TimerFcn',{@BoxTimerRunTime,f}, ...
    'ErrorFcn',{@BoxTimerError}, ...
    'StopFcn', {@BoxTimerStop}, ...
    'TasksToExecute',inf, ...
    'StartDelay',0);





function BoxTimerSetup(hObj,~,f)
global RUNTIME

h = guidata(f);

% trial history table
cols = {'Trial Type','Freq','Cue Delay','Response'};

set(h.DataTable,'Data',{[],[],[],''},'RowName','0','ColumnName',cols);


% timeoutdur
val = SelectTrial(RUNTIME.TRIALS,'timeout_dur');
set(h.TimeOutDur,'String',sprintf('%0.1f',val));



function BoxTimerRunTime(hObj,~,f)
global RUNTIME
persistent lastupdate starttime

if isempty(starttime), starttime = clock; end

h = guidata(f);

DATA = RUNTIME.TRIALS.DATA;

ntrials = length(DATA);





if isempty(DATA(1).trial_type_1) | ntrials == lastupdate, return; end

TrialType = [DATA.trial_type_1]';
Freq      = [DATA.HPFreq_1]';
CueDelay  = [DATA.cue_delay_1]';

bitmask = [DATA.ResponseCode]';

HITind      = logical(bitget(bitmask,3));
MISSind     = logical(bitget(bitmask,4));
Aind        = logical(bitget(bitmask,6));
Bind        = logical(bitget(bitmask,7));
NORESPind   = logical(bitget(bitmask,10));

TS = zeros(ntrials,1);
for i = 1:ntrials
    TS(i) = etime(DATA(i).ComputerTimestamp,starttime);
end
TS = TS / 60;

UpdateAxHistory(h.axHistory,TS,HITind,MISSind,NORESPind,Aind,Bind);
%set(h.axHistory,'XLim',[0,TS(i)+TS(i)/100])

Responses = cell(size(HITind));
Responses(HITind)  = {'Hit'};
Responses(MISSind) = {'Miss'};
Responses(NORESPind) = {'Abort'};

D = cell(ntrials,4);
D(:,1) = num2cell(TrialType);
D(:,2) = num2cell(Freq);
D(:,3) = num2cell(CueDelay);
D(:,4) = Responses;


D = flipud(D);

r = length(Responses):-1:1;
r = cellstr(num2str(r'));


set(h.DataTable,'Data',D,'RowName',r)

set(h.PanSummary,'Title', ['#TRIALS: ', num2str(ntrials)])
set(h.textLefts,'String', ['#Lefts: ',  num2str(sum(Aind))])
set(h.textRights,'String',['#Rights: ', num2str(sum(Bind))])
set(h.textHIT,'String',   ['#HIT: ',    num2str(sum(HITind))])
set(h.textMISS,'String',  ['#MISS: ',   num2str(sum(MISSind))])

lastupdate = ntrials;





function BoxTimerError(~,~)



function BoxTimerStop(~,~)














function UpdateAxHistory(ax,TS,HITind,MISSind,NORESPind,Aind,Bind)
cla(ax)

hold(ax,'on')
plot(ax,TS(HITind&Aind), ones(sum(HITind&Aind,1)),'go','markerfacecolor','g');
plot(ax,TS(MISSind&Aind),ones(sum(MISSind&Aind,1)),'ro','markerfacecolor','r');
plot(ax,TS(HITind&Bind), zeros(sum(HITind&Bind,1)),'gs','markerfacecolor','g');
plot(ax,TS(MISSind&Bind),zeros(sum(MISSind&Bind,1)),'rs','markerfacecolor','r');
plot(ax,TS(NORESPind),   0.5*ones(sum(NORESPind),1),'md','markerfacecolor','m');
hold(ax,'off');

set(ax,'ytick',[0 1],'yticklabel',{'A','B'},'ylim',[-0.1 1.1]);

xlabel(ax,'time (min)');


















% --- Executes on button press in InhibitTrial.
function InhibitTrial_Callback(hObj, e, h)
global AX RUNTIME

% v = get(hObj,'Value');
% 
% if v
%     set(hObj,'BackgroundColor','r','String','INHIBITED');
%     if RUNTIME.UseOpenEx
%         AX.SetTargetVal('Behavior.!InhibitTrial',1);
%     else
%         AX.SetTagVal('!InhibitTrial',1);
%     end
% else
%     set(hObj,'BackgroundColor',get(gcf,'Color'),'String','Inhibit Trial');
%     if RUNTIME.UseOpenEx
%         AX.SetTargetVal('Behavior.!InhibitTrial',0);
%     else
%         AX.SetTagVal('!InhibitTrial',0);
%     end
% end
% 




















% --- Executes on button press in UpdateTimeoutDur.
function UpdateTimeoutDur_Callback(hObj, e, h)
global AX RUNTIME


set(hObj,'String','UPDATING','BackgroundColor','g'); drawnow

v = str2double(get(h.TimeOutDur,'String'));

if RUNTIME.UseOpenEx
    AX.SetTargetVal('Behavior.timeout_dur~1',v);
    i = ismember(RUNTIME.TRIALS.writeparams,'Behavior.timeout_dur_1');

else
    AX.SetTagVal('timeout_dur~1',v);
    i = ismember(RUNTIME.TRIALS.writeparams,'timeout_dur_1');

end

RUNTIME.TRIALS.trials(:,i) = {v};


pause(0.5)

set(hObj,'String','update','BackgroundColor',get(gcf,'Color'));













% --- Executes on button press in UpdateParams.
function UpdateParams_Callback(hObj, e, h)
global RUNTIME
% 
% 
% set(hObj,'String','UPDATING','BackgroundColor','g'); drawnow
% 
% data = get(h.ParamTable,'Data');
% i = ismember(RUNTIME.TRIALS.writeparams,'*MIN_STANDARDS');
% RUNTIME.TRIALS.trials(:,i) = data(1,2);
% i = ismember(RUNTIME.TRIALS.writeparams,'*MAX_STANDARDS');
% RUNTIME.TRIALS.trials(:,i) = data(2,2);
% i = ismember(RUNTIME.TRIALS.writeparams,'*MIN_STANDARDS_POSTDEVMISS');
% RUNTIME.TRIALS.trials(:,i) = data(3,2);
% i = ismember(RUNTIME.TRIALS.writeparams,'*MAX_STANDARDS_POSTDEVMISS');
% RUNTIME.TRIALS.trials(:,i) = data(4,2);
% 
% 
% pause(0.5)
% 
% set(hObj,'String','update','BackgroundColor',get(gcf,'Color'));











