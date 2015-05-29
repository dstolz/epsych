function varargout = StimDetect_Monitor(varargin)
% StimDetect_Monitor

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
function StimDetect_Monitor_OpeningFcn(hObject, ~, handles, varargin)
handles.output = hObject;
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = StimDetect_Monitor_OutputFcn(hObject, ~, handles) 
varargout{1} = handles.output;

T = CreateTimer(hObject);

start(T);







function BoxTimerSetup(~,~,f)
% Setup tables and plots

h = guidata(f);
cols = {'Trial Type','Speaker ID','Tone Frequency','Tone SPL','Response Latency','Response'};
set(h.DataTable,'Data',{[],[],[],[],[],''},'RowName','0','ColumnName',cols);

set(h.ScoreTable,'RowName',{'Response','No Response'}, ...
    'ColumnName',{'Standard (0)','Deviant (0)'},'Data',repmat({'0 (0%)'},2,2));

cla(h.axHistory);
cla(h.axFunc);



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
    'Period',1, ...
    'StartFcn',{@BoxTimerSetup,f}, ...
    'TimerFcn',{@BoxTimerRunTime,f}, ...
    'ErrorFcn',{@BoxTimerError}, ...
    'StopFcn', {@BoxTimerStop}, ...
    'TasksToExecute',inf, ...
    'StartDelay',2);



function BoxTimerRunTime(~,~,f)
global RUNTIME % Contains info about currently running experiment including trial data collected so far
persistent lastupdate starttime % persistent variables hold their values across calls to this function

% retrieve figure handles structure
h = guidata(f);

% set initial values for persistent variables
if isempty(starttime),  starttime = clock;  end
if isempty(lastupdate), lastupdate = 0;     end

% number of trials is length of 
ntrials = length(RUNTIME.TRIALS.DATA);


% Update text indicating time since last trial
if ntrials > 1
    t = etime(clock,RUNTIME.TRIALS.DATA(end).ComputerTimestamp);
    set(h.TimeSinceLastTrial,'String',sprintf('Time Since Last Trial: %3.2f m',t/60));
    if t > 60
        set(h.TimeSinceLastTrial,'ForegroundColor','r');
    else
        set(h.TimeSinceLastTrial,'ForegroundColor','k');
    end
end

% escape until a new trial has been completed
if ntrials == lastupdate, return; end




%-----------------------------------------------------

% Update persistent variable 'lastupdate'
lastupdate = ntrials;









%-----------------------------------------------------


% copy DATA structure to make it easier to use
DATA = RUNTIME.TRIALS.DATA;


% Extract a few variables from the DATA structure
TrialType = [DATA.Behavior_TrialType]';
SpeakerID = [DATA.Behavior_DAC_Channel]';
ToneFreq  = [DATA.Behavior_Freq]';
ToneSPL   = [DATA.Behavior_Tone_dB]';
RespLat   = [DATA.Behavior_RespLatency]';








%-----------------------------------------------------

% Use Response Code bitmask to compute performance
RCode_bitmask = [DATA.ResponseCode]';

% find Hits, Misses, False Alarms, and Correct Rejects in the ResponseCode
% bitmask as defined using the ep_BitmaskGen GUI
HITind  = logical(bitget(RCode_bitmask,3));
MISSind = logical(bitget(RCode_bitmask,4));
FAind   = logical(bitget(RCode_bitmask,7));
CRind   = logical(bitget(RCode_bitmask,6));
STDind  = HITind|MISSind;
DEVind  = FAind|CRind;

nSTD = sum(STDind);
nDEV = sum(DEVind);

% Count number of Hits, Misses, False Alarms, and Correct Rejects
Ht = sum(HITind);
Ms = sum(MISSind);
FA = sum(FAind);
CR = sum(CRind);

nStd = FA + CR;
nDev = Ht + Ms;

% Update Score Table
ScoreTableData = {sprintf('%3.1f%% (%3d)',FA/nStd*100,FA), sprintf('%3.1f%% (%3d)',Ht/nDev*100,Ht), ...
                  sprintf('%3.1f%% (%3d)',CR/nStd*100,CR), sprintf('%3.1f%% (%3d)',Ms/nDev*100,Ms)};
ColName = {sprintf('Standard (%3d)',nStd),sprintf('Deviant (%3d)',nDev)};
RowName = {sprintf('Response (%3d)',Ht+FA),sprintf('No Response (%3d)',Ms+CR)};
set(h.ScoreTable,'Data',ScoreTableData,'ColumnName',ColName,'RowName',RowName);











%-----------------------------------------------------

% Compute elapsed time for trials since beginning of experiment
TS = zeros(ntrials,1);
for i = 1:ntrials
    TS(i) = etime(DATA(i).ComputerTimestamp,starttime);
end

% Update trial history plot
UpdateAxHistory(h.axHistory,starttime,TS,HITind,MISSind,FAind,CRind);












%-----------------------------------------------------

% Compute performance (d') for each speaker location
uSpkr = unique(SpeakerID);
dPrime  = zeros(size(uSpkr));
HitRate = zeros(size(uSpkr));
FARate  = zeros(size(uSpkr));
for i = 1:length(uSpkr)
    ind = SpeakerID == uSpkr(i);
    HitRate(i) = sum(HITind(ind))/nSTD;
    FARate(i)  = sum(FAind(ind))/nDEV;
    
    % adjust for extreme values which result in nonsense dprime values (Macmillan & Kaplan, 1985
    if HitRate(i) == 1, HitRate(i) = (ntrials-0.5)/ntrials; end
    if FARate(i)  == 1, FARate(i)  = (ntrials-0.5)/ntrials; end
    if HitRate(i) == 0, HitRate(i) = 0.5/ntrials; end
    if FARate(i)  == 0, FARate(i)  = 0.5/ntrials; end
    
    dPrime(i) = norminv(HitRate(i),0,1)-norminv(FARate(i),0,1);
end

% Update performance plot
UpdateAxPerformance(h.axPerformance,uSpkr,dPrime);












%-----------------------------------------------------

% Update Trial history data table
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






function BoxTimerError(~,~)



function BoxTimerStop(~,~)












% Plotting functions --------------------------------------------

function UpdateAxHistory(ax,starttime,TS,HITind,MISSind,FAind,CRind)
cla(ax)

hold(ax,'on')
plot(ax,TS(HITind), ones(sum(HITind,1)), 'go','markerfacecolor','g');
plot(ax,TS(MISSind),ones(sum(MISSind,1)),'rs','markerfacecolor','r');
plot(ax,TS(FAind),  zeros(sum(FAind,1)), 'rs','markerfacecolor','r');
plot(ax,TS(CRind),  zeros(sum(CRind,1)), 'go','markerfacecolor','g');
hold(ax,'off');

set(ax,'ytick',[0 1],'yticklabel',{'STD','DEV'},'ylim',[-0.1 1.1], ...
    'xlim',[etime(TS(end),starttime)-120 TS(end)+5])


function UpdateAxPerformance(ax,SpkrID,Performance)
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


















% Button Functions -----------------------------------------------
function TrigWater(hObj,~) %#ok<DEFNU>
global AX RUNTIME

% AX is the handle to either the OpenDeveloper (if using OpenEx) or RPvds
% (if not using OpenEx) ActiveX controls


set(hObj,'BackgroundColor','r'); drawnow
if RUNTIME.UseOpenEx
    AX.SetTargetVal('Behavior.!Water_Trig',1);
    pause(1);
    AX.SetTargetVal('Behavior.!Water_Trig',0);
else
    AX.SetTagVal('!Water_Trig',1);
    pause(1);
    AX.SetTagVal('!Water_Trig',0);
end
set(hObj,'BackgroundColor',c);
















