function varargout = Allman_TOJ_2AFC_Monitor(varargin)
% ALLMAN_TOJ_2AFC_MONITOR MATLAB code for Allman_TOJ_2AFC_Monitor.fig
%
% DJS 7/2015

% Last Modified by GUIDE v2.5 14-Jan-2016 17:16:15

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
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

h.BOXID = varargin{1};

set(hObj,'name',sprintf('TOJ Box ID: %d',h.BOXID));
set(h.txt_BoxLabel,'String',sprintf('Box ID: %d',h.BOXID));

% Update h structure
guidata(hObj, h);


T = CreateTimer(hObj);

start(T);


% --- Outputs from this function are returned to the command line.
function varargout = Allman_TOJ_2AFC_Monitor_OutputFcn(hObj, e, h) 
varargout{1} = h.output;







function T = CreateTimer(f)

h = guidata(f);

% Create new timer for RPvds control of experiment
T = timerfind('Name',sprintf('BoxTimer~%d',h.BOXID));
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
    'TasksToExecute',inf, ...
    'StartDelay',0);






function BoxTimerSetup(~,~,f)
h = guidata(f);

% trial history table
cols = {'Trial Type','Noise re Flash','Response','Hit/Miss'};

set(h.history,'Data',{[],[],[],[]},'RowName','0','ColumnName',cols);

cla(h.ax_history);
cla(h.ax_performance);
cla(h.ax_bias);
cla(h.ax_PelletCounts);

set([h.right_pellet h.left_pellet],'UserData',[0 0]);


guidata(f,h);






function BoxTimerRunTime(~,~,f)
global RUNTIME
persistent lastupdate

h = guidata(f);

availableBoxes = [RUNTIME.TRIALS.BoxID];
BOX_IND = availableBoxes==h.BOXID;

ntrials = RUNTIME.TRIALS(BOX_IND).DATA(end).TrialID;

if isempty(ntrials)
    ntrials = 0;
    lastupdate(BOX_IND) = 0;
end

if ntrials == lastupdate(BOX_IND), return; end
% ------------------------------------------

lastupdate(BOX_IND) = ntrials;

DATA = RUNTIME.TRIALS(BOX_IND).DATA;

TrialType    = [DATA.(sprintf('TrialType_%d',h.BOXID))]';
NoiseDelay   = [DATA.(sprintf('NoiseDelay_%d',h.BOXID))]';
FlashDelay   = [DATA.(sprintf('FlashDelay_%d',h.BOXID))]';
NoiseReFlash = NoiseDelay - FlashDelay;


bitmask = [DATA.ResponseCode]';

REWind   = logical(bitget(bitmask,1));
HITind   = logical(bitget(bitmask,3));
MISSind  = logical(bitget(bitmask,4));
RIGHTind = logical(bitget(bitmask,6));
LEFTind  = logical(bitget(bitmask,7));

% a kludge, but it works
P = get(h.right_pellet,'UserData');
P(2) = sum(RIGHTind&REWind);
set(h.right_pellet,'UserData',P)

P = get(h.left_pellet,'UserData');
P(2) = sum(LEFTind&REWind);
set(h.left_pellet,'UserData',P)

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

UpdatePelletCount(h);

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
bar(ax,[1 2],[LeftBias RightBias],0.6,'facecolor','k');
xlim(ax,[0.5 2.5]);

Lstr = sprintf('Left (%3.1f%%)', LeftBias*100);
Rstr = sprintf('Right (%3.1f%%)',RightBias*100);
set(ax,'xtick',[1 2],'xticklabel',{Lstr,Rstr});
title(ax,sprintf('# Trials = %d',total))
ylabel(ax,'% Responses | % Hits');

function UpdateAxHistory(ax,TS,HITind,MISSind,ASYNCind,SYNCind,AMBIGind)
cla(ax)

hold(ax,'on')
 %Hits to Async Trials
plot(ax,TS(HITind&ASYNCind), ones(sum(HITind&ASYNCind,1)),'go','markerfacecolor','g');

 %Misses to Async Trials
plot(ax,TS(MISSind&ASYNCind), ones(sum(MISSind&ASYNCind,1)),'rs','markerfacecolor','r');

% Hits to Sync Trials
plot(ax,TS(HITind&SYNCind), zeros(sum(HITind&SYNCind,1)),'g^','markerfacecolor','g');

% Misses to Sync Trials
plot(ax,TS(MISSind&SYNCind), zeros(sum(MISSind&SYNCind,1)),'r^','markerfacecolor','r');

% "Hits" to Ambiguous Trials
plot(ax,TS(HITind&AMBIGind), 0.5*ones(sum(HITind&AMBIGind,1)),'g<','markerfacecolor','g');

% "Misses" to Ambiguous Trials
plot(ax,TS(MISSind&AMBIGind), 0.5*ones(sum(MISSind&AMBIGind,1)),'r<','markerfacecolor','g','linewidth',2);


%No response
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

nHits = zeros(size(uSOA));
HitRate = nHits;

for i = 1:length(uSOA)
    SOAind = SOA == uSOA(i);
    nHits(i) = sum(HITind & SOAind);
    HitRate(i) = nHits(i) / sum(SOAind); 
end

plot(ax,uSOA,HitRate,'-ok','linewidth',2,'markerfacecolor','k');
set(ax,'ylim',[0 1]);
xlabel(ax,'SOA (ms)');

grid(ax(1),'on');



function TrigPellet(hObj,~,side) %#ok<DEFNU>
global AX 

h = guidata(hObj);

parstr = sprintf('!%sPellet~%d',side,h.BOXID);
AX.SetTagVal(parstr,1);
pause(0.01);
AX.SetTagVal(parstr,0);
fprintf('Box %d: %s side pellet triggered at %s\n',h.BOXID,side,datestr(now,'HH:MM:SS'))

P = get(hObj,'UserData');
P(1) = P(1) + 1;
set(hObj,'UserData',P);

UpdatePelletCount(guidata(hObj));


% --- Executes on button press in UpdateParams.
function UpdateParams_Callback(hObj, ~, h) %#ok<DEFNU>
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





function UpdatePelletCount(h)

cla(h.ax_PelletCounts)


Pr = get(h.right_pellet,'UserData');
Pl = get(h.left_pellet,'UserData');


bar(h.ax_PelletCounts,[1 3.2],[Pl(2) Pr(2)],0.6,'k');
hold(h.ax_PelletCounts,'on');
bar(h.ax_PelletCounts,[1.5 3.7],[Pl(1) Pr(1)],0.6,'facecolor',[0.5 0.5 0.5]);

xlim(h.ax_PelletCounts,[0 4.5]);

pstr = sprintf('Total Pellets Rewarded %d | Triggered %d', ...
    Pl(2)+Pr(2),Pl(1)+Pr(1));

set(h.reward_panel,'Title',pstr)



