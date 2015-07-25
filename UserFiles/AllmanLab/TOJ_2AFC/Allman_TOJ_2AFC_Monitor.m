function varargout = Allman_TOJ_2AFC_Monitor(varargin)
% ALLMAN_TOJ_2AFC_MONITOR MATLAB code for Allman_TOJ_2AFC_Monitor.fig
%
% DJS 7/2015

% Last Modified by GUIDE v2.5 16-Jul-2015 16:28:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Allman_TOJ_2AFC_Monitor_OpeningFcn, ...
                   'gui_OutputFcn',  @Allman_TOJ_2AFC_Monitor_OutputFcn, ...
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


% --- Executes just before Allman_TOJ_2AFC_Monitor is made visible.
function Allman_TOJ_2AFC_Monitor_OpeningFcn(hObj, e, h, varargin)

h.output = hObj;

% Update h structure
guidata(hObj, h);


T = CreateTimer(hObj);

start(T);


% --- Outputs from this function are returned to the command line.
function varargout = Allman_TOJ_2AFC_Monitor_OutputFcn(hObj, e, h) 
varargout{1} = h.output;








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
    'TasksToExecute',inf);







function BoxTimerSetup(~,~,f)
h = guidata(f);

% trial history table
cols = {'Trial Type','Noise re Flash','Response','Hit/Miss'};

set(h.history,'Data',{[],[],[],[]},'RowName','0','ColumnName',cols);

cla(h.ax_history);
cla(h.ax_performance);
cla(h.ax_bias);









function BoxTimerRunTime(~,~,f)
global RUNTIME
persistent lastupdate 

ntrials = RUNTIME.TRIALS.DATA(end).TrialID;

if isempty(ntrials)
    ntrials = 0;
    lastupdate = 0;
end

if ntrials == lastupdate, return; end
% ------------------------------------------

lastupdate = ntrials;

h = guidata(f);

DATA = RUNTIME.TRIALS.DATA;

TrialType    = [DATA.TrialType]';
NoiseDelay   = [DATA.NoiseDelay]';
FlashDelay   = [DATA.FlashDelay]';
NoiseReFlash = NoiseDelay - FlashDelay;



bitmask = [DATA.ResponseCode]';

HITind   = logical(bitget(bitmask,3));
MISSind  = logical(bitget(bitmask,4));
RIGHTind = logical(bitget(bitmask,6));
LEFTind  = logical(bitget(bitmask,7));

ASYNCind = TrialType == 0;
SYNCind  = TrialType == 1;
AMBIGind = TrialType == 2;

TS = zeros(ntrials,1);
for i = 1:ntrials
    TS(i) = etime(DATA(i).ComputerTimestamp,RUNTIME.StartTime);
end
TS = TS / 60; % seconds -> minutes

UpdateAxHistory(h.ax_history,TS,HITind,MISSind,ASYNCind,SYNCind,AMBIGind);

UpdateAxPerformance(h.ax_performance,NoiseReFlash,HITind);

UpdateAxBias(h.ax_bias,LEFTind,RIGHTind)

HITMISS = cell(size(HITind));
HITMISS(HITind)  = {'Hit'};
HITMISS(MISSind) = {'Miss'};

RESPONSES = cell(size(RIGHTind));
RESPONSES(RIGHTind) = {'Right'};
RESPONSES(LEFTind)  = {'Left'};
RESPONSES(~(RIGHTind|LEFTind)) = {'None'};

TRIALTYPE = cell(size(TrialType));
TRIALTYPE(TrialType == 0) = {'0 - Sync'};
TRIALTYPE(TrialType == 1) = {'1 - Async'};
TRIALTYPE(TrialType == 2) = {'2 - Ambig'};

D = cell(ntrials,4);
D(:,1) = TRIALTYPE;
D(:,2) = num2cell(NoiseReFlash);
D(:,3) = RESPONSES;
D(:,4) = HITMISS;


D = flipud(D);

r = length(RESPONSES):-1:1;
r = cellstr(num2str(r'));


set(h.history,'Data',D,'RowName',r)




function UpdateAxBias(ax,LEFTind,RIGHTind)
cla(ax)

total = sum(LEFTind|RIGHTind);
LeftBias  = sum(LEFTind)/total;
RightBias = sum(RIGHTind)/total;
bar(ax,[1 2],[LeftBias RightBias],'facecolor','k');

Lstr = sprintf('Left (%3.1f%%)', LeftBias*100);
Rstr = sprintf('Right (%3.1f%%)',RightBias*100);
set(ax,'xtick',[1 2],'xticklabel',{Lstr,Rstr});
title(ax,sprintf('# Trials = %d',total))


function UpdateAxHistory(ax,TS,HITind,MISSind,ASYNCind,SYNCind,AMBIGind)
cla(ax)

hold(ax,'on')
% Hits to Async Trials
plot(ax,TS(HITind&ASYNCind), ones(sum(HITind&ASYNCind,1)),'go','markerfacecolor','g');

% Misses to Async Trials
plot(ax,TS(MISSind&ASYNCind), ones(sum(MISSind&ASYNCind,1)),'rs','markerfacecolor','r');

% Hits to Sync Trials
plot(ax,TS(HITind&SYNCind), zeros(sum(HITind&SYNCind,1)),'g^','markerfacecolor','g');

% Misses to Sync Trials
plot(ax,TS(MISSind&SYNCind), zeros(sum(MISSind&SYNCind,1)),'r^','markerfacecolor','r');

% "Hits" to Ambiguous Trials
plot(ax,TS(HITind&AMBIGind), 0.5*ones(sum(HITind&AMBIGind,1)),'g<','markerfacecolor','g');

% "Misses" to Ambiguous Trials
plot(ax,TS(MISSind&AMBIGind), 0.5*ones(sum(MISSind&AMBIGind,1)),'r<','markerfacecolor','g','linewidth',2);


% No response
plot(ax,TS(~(HITind|MISSind)&ASYNCind),zeros(sum(~(HITind|MISSind)&ASYNCind,1)), 'rx', ...
    'linewidth',3,'markerfacecolor','r','markersize',8);
plot(ax,TS(~(HITind|MISSind)&SYNCind),ones(sum(~(HITind|MISSind)&SYNCind,1)), 'rx', ...
    'linewidth',3,'markerfacecolor','r','markersize',8);
plot(ax,TS(~(HITind|MISSind)&AMBIGind),0.5*ones(sum(~(HITind|MISSind)&AMBIGind,1)), 'rx', ...
    'linewidth',3,'markerfacecolor','r','markersize',8);
hold(ax,'off');

set(ax,'ytick',[0 0.5 1],'yticklabel',{'Async','Ambig','Sync'},'ylim',[-0.2 1.2],'xlim',TS(end)-[2 0]);

xlabel(ax,'time (min)');

box(ax,'on')


function UpdateAxPerformance(ax,SOA,HITind)
cla(ax)


uSOA = unique(SOA);
for i = 1:length(uSOA)
    SOAind = SOA == uSOA(i);
    HitRate(i) = sum(HITind & SOAind) / sum(SOAind); %#ok<AGROW>
end


plot(ax,uSOA,HitRate,'-ok','linewidth',2,'markerfacecolor','k');

set(ax,'xtick',uSOA,'ylim',[0 1],'xscale','log')
ylabel(ax,'Hit Rate');
xlabel(ax,'SOA (ms)');
grid(ax,'on');


function TrigPellet(hObj,e,side)
global AX 

parstr = sprintf('!%sPellet',side);
AX.SetTagVal(parstr,1);
pause(0.01);
AX.SetTagVal(parstr,0);
fprintf('%s side pellet triggered at %s\n',side,datestr(now,'HH:MM:SS'))


% --- Executes on button press in UpdateParams.
function UpdateParams_Callback(hObj, e, h)
global RUNTIME


set(hObj,'String','UPDATING','BackgroundColor','g'); drawnow

data = get(h.ParamTable,'Data');
i = ismember(RUNTIME.TRIALS.writeparams,'*MIN_STANDARDS');
RUNTIME.TRIALS.trials(:,i) = data(1,2);
i = ismember(RUNTIME.TRIALS.writeparams,'*MAX_STANDARDS');
RUNTIME.TRIALS.trials(:,i) = data(2,2);
i = ismember(RUNTIME.TRIALS.writeparams,'*MIN_STANDARDS_POSTDEVMISS');
RUNTIME.TRIALS.trials(:,i) = data(3,2);
i = ismember(RUNTIME.TRIALS.writeparams,'*MAX_STANDARDS_POSTDEVMISS');
RUNTIME.TRIALS.trials(:,i) = data(4,2);


pause(0.5)

set(hObj,'String','update','BackgroundColor',get(gcf,'Color'));





