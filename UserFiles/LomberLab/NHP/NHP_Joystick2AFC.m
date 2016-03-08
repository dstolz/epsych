function varargout = NHP_Joystick2AFC(varargin)
% NHP_Joystick2AFC
% 
% Simple GUI for training Left/Right movements on a Joystick
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

% retrieve figure handles structure
h = guidata(f);

JV = AX.GetTargetVal('Joystick.*JoystickV');
set(h.lblJoystickV,'String',sprintf('Joystick V = % 4.2f',JV));

% Number of valid joystick contacts
nContacts = AX.GetTargetVal('Behavior.*NumContacts');
InfoStr = sprintf('# Contacts: %d',nContacts);


% Reward duration
RewardSamps = AX.GetTargetVal('Behavior.*RewardSamps');
RewardDur = RewardSamps / 48828.125;
RewardEst = round(10*RewardDur*1000 / 5263)/10;

InfoStr = sprintf('%s\nDelivered: %0.1f ml',InfoStr,RewardEst);

set(h.lblInfo,'String',InfoStr)


% escape until a new trial has been completed
if ntrials == lastupdate,  return; end
lastupdate = ntrials;


% copy DATA structure to make it easier to use
DATA = RUNTIME.TRIALS.DATA;

% Use Response Code bitmask to compute performance
RCode = [DATA.ResponseCode]';

% Decode bitmask generated using ep_BitmaskGen
IND.Reward      = bitget(RCode,1);
IND.Hit         = bitget(RCode,3);
IND.Miss        = bitget(RCode,4);
IND.Abort       = bitget(RCode,5);
IND.RespLeft    = bitget(RCode,6);
IND.RespRight   = bitget(RCode,7);
IND.NoRsponse   = bitget(RCode,10);
IND.Left        = bitget(RCode,11);
IND.Right       = bitget(RCode,12);
IND.Ambig       = bitget(RCode,13);
IND.NoResp      = bitget(RCode,14);

IND = structfun(@logical,IND,'UniformOutput',false);

SpkrAngles = [DATA.Behavior_Speaker_Angle];

UpdatePerformancePlot(h.axPerformance,SpkrAngles,IND);
UpdateSummaryPlot(h.axSummary,SpkrAngles,IND);

RespLatency = [DATA.Behavior_RespLatency];
RespLatency = round(RespLatency); % -> nearest ms
UpdateHistoryTable(h.tbl_History,IND,SpkrAngles,RespLatency)



function BoxTimerError(~,~)
% disp('BoxERROR');


function BoxTimerStop(~,~)



%
function SetupHistoryTable(hTbl)
set(hTbl,'ColumnName',{'TrialType','Angle','Response','Latency'}, ...
    'RowName',{'-'},'Data',cell(1,4));

function UpdateHistoryTable(hTbl,data,angles,latencies)

% Update Trial history data table
R = cell(size(data.Hit));
R(data.Hit)  = {'Hit'};
R(data.Miss) = {'Miss'};
R(data.Abort) = {'Abort'};
R(data.Ambig&data.Reward) = {'AmbigResp'};
R(data.NoResp) = {'No Resp'};

tt = cell(size(data.Left));
tt(data.Left)  = {'Left'};
tt(data.Right) = {'Right'};
tt(data.Ambig) = {'Ambig'};

D = cell(length(R),4);
D(:,1) = tt;
D(:,2) = num2cell(angles);
D(:,3) = R;
D(:,4) = num2cell(latencies);

D = flipud(D);

rnames = fliplr(num2cell(1:length(R)))';

set(hTbl,'Data',D,'RowName',rnames);



% Plotting
function UpdateSummaryPlot(ax,angles,data)
cla(ax)

sL = sum(data.Hit&data.Left); 
tL = sum(data.Left);
L = sL/tL;

sR = sum(data.Hit&data.Right);
tR = sum(data.Right);
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

title(ax,sprintf('%d Hits / %d Trials (%d/%d)',sL+sR,tL+tR,sAL+sAR,tAL+tAR));

hold(ax,'off');

function UpdatePerformancePlot(ax,angles,data)
cla(ax)

uangle = unique(angles(:)');

for i = 1:length(uangle)
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
function TrigWater(hObj,~) %#ok<DEFNU>
global AX RUNTIME 

% AX is the handle to either the OpenDeveloper (if using OpenEx) or RPvds
% (if not using OpenEx) ActiveX controls

c = get(hObj,'BackgroundColor');
set(hObj,'BackgroundColor','r'); drawnow

if RUNTIME.UseOpenEx
    AX.SetTargetVal('Behavior.*Water_Trig_Dur',750);
    AX.SetTargetVal('Behavior.!Water_Trig',1);
    while AX.GetTargetVal('Behavior.*Rewarding')
        pause(0.1);
    end
    AX.SetTargetVal('Behavior.!Water_Trig',0);
else
    AX.SetTagVal('!Water_Trig',1);
    while AX.GetTagVal('*Rewarding')
        pause(0.1);
    end
    AX.SetTagVal('!Water_Trig',0);
end

set(hObj,'BackgroundColor',c);












