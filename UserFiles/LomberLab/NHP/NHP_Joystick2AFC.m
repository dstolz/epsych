function varargout = NHP_Joystick2AFC(varargin)
% NHP_Joystick2AFC
% 
% Simple GUI for Sound Localization using 2AFC paradigm
%
% Daniel.Stolzberg@gmail.com 2016

% Last Modified by GUIDE v2.5 07-Mar-2016 14:13:18

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @NHP_Joystick2AFC_OpeningFcn, ...
                   'gui_OutputFcn',  @NHP_Joystick2AFC_OutputFcn, ...
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


% --- Executes just before NHP_Joystick2AFC is made visible.
function NHP_Joystick2AFC_OpeningFcn(hObj, ~, h, varargin)

% Choose default command line output for NHP_Joystick2AFC
h.output = hObj;

% Update h structure
guidata(hObj, h);


% --- Outputs from this function are returned to the command line.
function varargout = NHP_Joystick2AFC_OutputFcn(hObj, ~, h) 
% Get default command line output from h structure
varargout{1} = h.output;

cla(h.axPerformance);
set(h.axPerformance,'xtick',[1 2],'xticklabel',{'Left 0','Right 0'});
title(h.axPerformance,'Total: 0');

T = CreateTimer(hObj);

start(T);






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

h = guidata(f);

SetupHistoryTable(h.tbl_History)

set(h.lblInfo,'String',sprintf('# Contacts: 0\nDelivered: 0.0 ml'));

cla(h.ax_BitmaskRecord);

set(h.tgl_InhibitTrial,'Value',0);
InhibitTrial(h.tgl_InhibitTrial)

% EyeTrackGUI;


function BoxTimerRunTime(~,~,f)
% global variables
% RUNTIME contains info about currently running experiment including trial data collected so far
% AX is the ActiveX control being used

global RUNTIME AX
persistent lastupdate BMRECORD T  % persistent variables hold their values across calls to this function

try
    % number of trials is length of
    ntrials = RUNTIME.TRIALS.DATA(end).TrialID;
    
    if isempty(ntrials)
        BMRECORD = [];
        T = [];
        ntrials = 0;
        lastupdate = 0;
    end
    
    
    
    
    % retrieve figure handles structure
    h = guidata(f);
    
    % Number of valid joystick contacts
    nContacts = AX.GetTargetVal('Behavior.*NumContacts')-1;
    InfoStr = sprintf('# Contacts: %d',nContacts);
    
    
    
    
    
    
    % set(h.lblInfo,'String',InfoStr)
    
    UpdateLabels(h,AX);
    
    BMRECORD(end+1) = AX.GetTargetVal('Behavior.*BitmaskRecord');
    T(end+1) = now;
    if get(h.pauseBitmaskRecord,'Value')
        title(h.ax_BitmaskRecord,'*PAUSED*');
    else
        title(h.ax_BitmaskRecord,'');
        UpdateBitmaskRecord(h.ax_BitmaskRecord,T,BMRECORD);
    end
    
    
    % escape until a new trial has been completed
    if ntrials == lastupdate,  return; end
    lastupdate = ntrials;
    
    
    % copy DATA structure to make it easier to use
    DATA = RUNTIME.TRIALS.DATA;
    
    % Plot response latency
    NHP_PlotResponseLatency(DATA);
    
    % Use Response Code bitmask to compute performance
    RCode = [DATA.ResponseCode]';
    
    
    % Decode bitmask generated using ep_BitmaskGen
    IND = NHP_decodeResponseCode(RCode);
    
    nValidTrials = sum(~IND.Abort&~IND.NoResp);
    InfoStr = sprintf('%s\n# Valid Trials: %d',InfoStr,nValidTrials);
    
    % Reward duration
    % EST_WATER_CAL = 5263; % ms
    % EST_WATER_CAL = 3060.9; % March 31, 2016 DJS
    EST_WATER_CAL = 2857.1; % April 25, 2016 DJS
    
    RewardSamps = AX.GetTargetVal('Behavior.*RewardSamps');
    RewardDur = RewardSamps / 48828.125;
    RewardEst = round(10*RewardDur*1000 / EST_WATER_CAL)/10;
    
    InfoStr = sprintf('%s\nDelivered: %0.1f ml',InfoStr,RewardEst);
    
    
    % Runs ----------------------------------------------------------------
    Runs = diff(findConsecutive(IND.Hit,1))+1;
    LongestRun = max(Runs);
    InfoStr = sprintf('%s\nLongest Run: %d',InfoStr,LongestRun);
    set(h.lblInfo,'String',InfoStr)
    UpdateRunsPlots(h,Runs)
    % --------------------------------------------------------------------
    
    
    
    % assignin('base','IND',IND);
    % assignin('base','DATA',DATA);
    IND = structfun(@logical,IND,'UniformOutput',false);
    
    SpkrAngles = [DATA.Behavior_Speaker_Angle];
    
    UpdatePerformancePlot(h.axPerformance,SpkrAngles,IND);
    UpdatePsychometricFcnPlot(h.axPsychometricFcn,SpkrAngles,IND);
    UpdateSummaryPlot(h.axSummary,SpkrAngles,IND);
    
    RespLatency = round([DATA.Behavior_RespLatency]);
    
    Rewards     = round([DATA.Behavior_Water_Thi]);
    
    UpdateHistoryTable(h.tbl_History,IND,SpkrAngles,RespLatency,Rewards)
catch me
    % good place to put a breakpoint for debugging
    rethrow(me)    
end

function BoxTimerError(~,~)
% disp('BoxERROR');


function BoxTimerStop(~,~)


function ResetBoxTimer(~,~) %#ok<DEFNU>
t = timerfind('name','BoxTimer');
if isa(t,'timer') && isequal(t.Running,'on')
    return
elseif ~isa(t,'timer')
    t = CreateTimer(hObj);
end
start(t);

%
function SetupHistoryTable(hTbl)
cols = {'TrialType','Angle','Response','Reward','Latency'};
set(hTbl,'ColumnName',cols,'RowName',{'-'},'Data',cell(size(cols)));


function UpdateLabels(h,AX)
% Joystick position indicators

JoystickContact = AX.GetTargetVal('Behavior.*JoystickContact');
JoystickLeft    = AX.GetTargetVal('Behavior.*JoystickLeft');
JoystickRight   = AX.GetTargetVal('Behavior.*JoystickRight');

% figbg = get(h.figure1,'color');
set([h.txt_JoystickLeft, h.txt_JoystickRight, h.txt_JoystickCentered,h.txt_EyeFixed],'ForegroundColor',[0.6 0.6 0.6]);

if JoystickLeft
  set(h.txt_JoystickLeft,'ForegroundColor','g');

elseif JoystickRight
  set(h.txt_JoystickRight,'ForegroundColor','g');

elseif JoystickContact
  set(h.txt_JoystickCentered,'ForegroundColor','g');

end

% Eye fixation indicator
EyeFixed = AX.GetTargetVal('Behavior.*EyeFixed');
if EyeFixed
    set(h.txt_EyeFixed,'ForegroundColor','g','String','<o>');
else
    set(h.txt_EyeFixed,'ForegroundColor','k','String','<->');
end

% Trial Status
inTrial = AX.GetTargetVal('Behavior.*InTrial');
if inTrial
  set(h.txt_TrialStatus,'String','* In Trial *','ForegroundColor','g');
else
  set(h.txt_TrialStatus,'String','Waiting ...','ForegroundColor','k');
end

function UpdateHistoryTable(hTbl,data,angles,latencies,rewards)

% Update Trial history data table
R = cell(size(data.Hit));
R(data.Hit)     = {'Hit'};
R(data.Miss)    = {'Miss'};
R(data.Abort)   = {'Abort'};
R(data.Ambig&data.Reward) = {'AmbigResp'};
R(data.NoResp)  = {'No Resp'};

tt = cell(size(data.Left));
tt(data.Left)  = {'Left'};
tt(data.Right) = {'Right'};
tt(data.Ambig) = {'Ambig'};

rewards = rewards .* data.Reward';

D = cell(length(R),5);
D(:,1) = tt;
D(:,2) = num2cell(angles);
D(:,3) = R;
D(:,4) = num2cell(rewards);
D(:,5) = num2cell(latencies);

D = flipud(D);

rnames = fliplr(num2cell(1:length(R)))';

set(hTbl,'Data',D,'RowName',rnames);



% Plotting

function UpdateRunsPlots(h,Runs)
stem(h.axRuns,Runs,'ok','markerfacecolor','k');
mr = max(Runs); if isempty(mr) || ~mr, mr = 1; end
ylim(h.axRuns,[0 mr+1])
if length(Runs) > 2
    hold(h.axRuns,'on');
    p = polyfit(1:length(Runs),Runs,1);
    y = polyval(p,1:length(Runs));
    plot(h.axRuns,1:length(Runs),y,'b-','linewidth',2);
    title(h.axRuns,sprintf('Slope = %0.3f',p(1)))
    hold(h.axRuns,'off');
end
xlabel(h.axRuns,'Run Number'); ylabel(h.axRuns,'Run Length');

b = 1:max([Runs,10])+1;
hist(h.axRunHist,Runs,b);
xlabel(h.axRunHist,'Run Length'); ylabel(h.axRunHist,'Count');



function UpdateSummaryPlot(ax,angles,data)
cla(ax)

sL = sum(data.Hit&data.Left); 
tL = sum(~data.Abort&~data.NoResp&data.Left);
L = sL/tL;

sR = sum(data.Hit&data.Right);
tR = sum(~data.Abort&~data.NoResp&data.Right);
R = sR/tR;

bar(ax,[1 2],[L R],'k');

hold(ax,'on');

sAL = sum(data.Reward&data.Ambig&angles'<0);
tAL = sum(data.Reward&data.Ambig);
AL = sAL/tAL;

sAR = sum(data.Reward&data.Ambig&angles'>0);
tAR = sum(data.Reward&data.Ambig);
AR = sAR/tAR;

h = bar(ax,[1.25 2.25],[AL AR]);
set(h,'facecolor',[0.5 0.5 0.5]);

set(ax,'xtick',[1 2],'xticklabel',{sprintf('Left %d/%d (%d/%d)',sL,tL,sAL,tAL), ...
    sprintf('Right %d/%d (%d/%d)',sR,tR,sAR,tAR)});

title(ax,sprintf('%0.1f%% %d Hits / %d Trials (%d/%d)',(sL+sR)/(tL+tR)*100,sL+sR,tL+tR,sAL+sAR,tAL+tAR));

hold(ax,'off');


function UpdateBitmaskRecord(ax,T,BMRECORD)
persistent bmL bmC trialMarker

bufferLength = 300; % Timer rate = 10 Hz

% JContact    = bitget(cbuf,1); 
% LEDsig      = bitget(cbuf,2);
% RewardTrig  = bitget(cbuf,3);
% StimOn      = bitget(cbuf,4);
% RespWin     = bitget(cbuf,5);
% InTrial     = bitget(cbuf,6);
% JLeft       = bitget(cbuf,7);
% JRight      = bitget(cbuf,8);
% EyeFixed    = bitget(cbuf,9);

% bmap = [7 6 1 3 4 2 5 8];
bmap = [6 5 2 4 3 1 7 8 9];

if length(BMRECORD) > bufferLength
    cbuf = BMRECORD(end-bufferLength+1:end);
%     T = T(end-bufferLength+1:end);
else
    cbuf = BMRECORD;
end

cvals = zeros(bufferLength,length(bmap));
for i = 1:length(bmap)
    cvals(1:length(cbuf),i) = bitget(cbuf,i);
end
cvals(~cvals) = nan;

cvals = cvals(:,bmap); % remap data order for clarity

if isempty(bmC), bmC = lines(length(bmap));end

if isempty(bmL) || ~ishandle(bmL(1))
    cla(ax);
    for i = 1:length(bmap)
        bmL(i) = line(0,i,'parent',ax,'color',bmC(i,:),'linewidth',13);
    end
end


for i = 1:length(bmL)
    set(bmL(i),'xdata',1:bufferLength,'ydata',i*cvals(:,i));
end

% intrial = cvals(:,1);
% intrial(isnan(intrial)) = 0;
% fon  = find(intrial(1:end-1) < intrial(2:end)); % trial onsets
% foff = find(intrial(1:end-1) > intrial(2:end)); % trial offsets
% if ~isempty(trialMarker), delete(trialMarker); end
% trialMarker = [];
% for i = 1:length(fon)
%     trialMarker(i) = line([1 1]*T(fon(i)+1),[0 length(bmap)+1],'parent',ax, ...
%         'color','r','linestyle',':','linewidth',2,'marker','>','markerfacecolor','r');
% end
% for i = 1:length(foff)
%     trialMarker(end+1) = line([1 1]*T(foff(i)),[0 length(bmap)+1],'parent',ax, ...
%         'color','r','linestyle',':','linewidth',2,'marker','<','markerfacecolor','r');
% end
% assignin('base','T',T)


set(ax,'ylim',[0 length(bmap)+1],'xlim',[1 bufferLength],'xticklabel',[], ...
    'ytick',1:length(bmap),'yticklabel',{'In Trial','RespWin','LED', ...
    'Stim','Reward','Contact','Left','Right','EyeFixed'},'box','on')



function UpdatePsychometricFcnPlot(ax,angles,data)
% axPsychometricFcn
uangle = unique(angles(:)');
rr = uangle;
w  = uangle;
for i = 1:length(uangle)
    ind = uangle(i) == angles;
    w(i)  = sum(~(data.Abort(ind) | data.NoResponse(ind)));
    rr(i) = sum(data.RespRight(ind))/w(i);
end
% assignin('base','data',data);
% assignin('base','rr',rr);
% assignin('base','uangle',uangle);
h = plot(ax,uangle,rr,'ok');
set(h,'markersize',10,'linewidth',2,'markerfacecolor','k');
set(ax,'ytick',0:0.2:1,'ylim',[-0.05 1.05]);

hold(ax,'on')
h = plot(ax,angles(end),rr(uangle==angles(end)),'o');
if data.Hit(end)
    set(h,'linewidth',2,'markerfacecolor','g','color','g','markersize',6);
else
    set(h,'linewidth',2,'markerfacecolor','r','color','r','markersize',6);
end

if length(uangle) > 4
    rr = rr(:);
    y = smooth(uangle,rr,5);
    plot(ax,uangle,y,'-','color',[0.6 0.6 0.6],'linewidth',2);
    plot(ax,xlim(ax),[0.5 0.5],'-k');
end
hold(ax,'off');

set(ax,'ytick',0:0.2:1,'ylim',[-0.05 1.05],'xlim',[-90 90]);
xlabel(ax,'spkr angle');
ylabel(ax,'% right responses');
grid(ax,'on');

function UpdatePerformancePlot(ax,angles,data)
cla(ax)

uangle = unique(angles(:)');

for i = 1:length(uangle)
%     ind = uangle(i) == angles & data.Hit | data.Miss;
    ind = uangle(i) == angles;
    theta(i) = uangle(i)*pi/180; % deg -> rad   
    rho(i) = sum(data.Hit(ind))/sum(ind);    
end

h = polar(ax,theta,rho,'-ok');
set(h,'markerfacecolor','g','MarkerSize',10,'linewidth',2)

hold(ax,'on');
% highlight last trial speaker location
h = polar(ax,angles(end)*pi/180,1,'s');
if data.Hit(end)
    set(h,'linewidth',1,'marker','^', ...
        'color','k','markerfacecolor','g','markersize',10);
else
    set(h,'linewidth',3,'marker','x', ...
        'color','r','markersize',16);
end

grid(ax,'on');

hold(ax,'off');



% Button Functions -----------------------------------------------
function InhibitTrial(hObj,~)
global AX RUNTIME

% AX is the handle to either the OpenDeveloper (if using OpenEx) or RPvds
% (if not using OpenEx) ActiveX controls

if get(hObj,'Value')
    TDTpartag(AX,RUNTIME.TRIALS,'Behavior.!ManualInhibit_ON',1);
    TDTpartag(AX,RUNTIME.TRIALS,'Behavior.!ManualInhibit_ON',0);
    set(hObj,'BackgroundColor','r','String','INHIBITED!');
else
    TDTpartag(AX,RUNTIME.TRIALS,'Behavior.!ManualInhibit_OFF',1);
    TDTpartag(AX,RUNTIME.TRIALS,'Behavior.!ManualInhibit_OFF',0);
    set(hObj,'BackgroundColor',[1 1 1]*(240/255),'String','Inhibit Trial');
end



function TrigWater(hObj,~) %#ok<DEFNU>
global AX RUNTIME

% AX is the handle to either the OpenDeveloper (if using OpenEx) or RPvds
% (if not using OpenEx) ActiveX controls

c = get(hObj,'BackgroundColor');
set(hObj,'BackgroundColor','r'); drawnow

TDTpartag(AX,RUNTIME.TRIALS,'Behavior.*Water_Trig_Dur',750);
TDTpartag(AX,RUNTIME.TRIALS,'Behavior.!Water_Trig',1);
while TDTpartag(AX,RUNTIME.TRIALS,'Behavior.*Rewarding')
    pause(0.1);
end
TDTpartag(AX,RUNTIME.TRIALS,'Behavior.!Water_Trig',0);

set(hObj,'BackgroundColor',c);












