function varargout = SimpleABR(varargin)
% SIMPLEABR MATLAB code for SimpleABR.fig
%      SIMPLEABR, by itself, creates a new SIMPLEABR or raises the existing
%      singleton*.
%
%      H = SIMPLEABR returns the handle to a new SIMPLEABR or the handle to
%      the existing singleton*.
%
%      SIMPLEABR('CALLBACK',hObj,~,h,...) calls the local
%      function named CALLBACK in SIMPLEABR.M with the given input arguments.
%
%      SIMPLEABR('Property','Value',...) creates a new SIMPLEABR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SimpleABR_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SimpleABR_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SimpleABR

% Last Modified by GUIDE v2.5 11-Dec-2015 19:03:23

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SimpleABR_OpeningFcn, ...
                   'gui_OutputFcn',  @SimpleABR_OutputFcn, ...
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


% --- Executes just before SimpleABR is made visible.
function SimpleABR_OpeningFcn(hObj, ~, h, varargin)
global Verbose

h.output = hObj;

Verbose = true;

populateParams(h);


% Update h structure
guidata(hObj, h);

% UIWAIT makes SimpleABR wait for user response (see UIRESUME)
% uiwait(h.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SimpleABR_OutputFcn(hObj, ~, h) 

varargout{1} = h.output;
















% GUI =====================================================================
function prgrmState(hobj,h)
global DA

state = get(hObj,'String');

switch upper(state)
    case 'START'
        T = createTimer(h);
        initOpenDev(ABRtank);
        
        
    case 'PAUSE'
        
        
    case 'STOP'
        if isa(DA,'TDevAcc.X')
            DA.CloseConnection;
            delete(DA);
        end
        
end


function populateParams(h)

P = getpref('SimpleABR','Params',[]);

if isempty(P)
    P.StimRate.value       = 21; % stim per second
    P.StimRate.tag         = [];
    P.StimDuration.value   = 5;
    P.StimDuration.tag     = 'StimDur';
    P.NumPulses.value      = 1024;
    P.NumPulses.tag        = 'Npls';
    P.ISI.value            = 1000/P.Rate-P.StimDur;
    P.ISI.tag              = 'ISI';
    P.Frequency.value      = 1000;
    P.Frequency.tag        = 'Freq';
    P.Level.value          = 0.5;
    P.Level.tag            = 'Level';
end

fn = fieldnames(P);
S = cell(length(fn),2);
for i = 1:length(fn)
    S{i,1} = fn{i};
    S{i,2} = P.(fn{i}).value;
end
set(h.tblParams,'Data',S,'UserData',P);

setprefs('SimpleABR','Params',P);



function updateVals(h)
global DA




DA.SetTargetVal('ABRStim.StimOn',0);



DA.SetTargetVal('ABRStim.Freq',freq)
DA.SetTargetVal('ABRStim.Level',level)

fprintf('Updated values: Frequency = % 5.1f Hz, Level = % 3.2 V\n', freq, level)

DA.SetTargetVal('ABRStim.StimOn',1);

















% Data Access =============================================================
function wABR = GetResponses(Freq,Level)
global TT Verbose


TT.SetFilterTolerance(0.01);

TT.SetGlobals('Channel=1; MaxReturn=1000000; Options=FILTERED');

fwdstr = sprintf('Freq=%d AND Level=%0.1f',Freq,Level);
TT.SetFilterWithDescEx(fwdstr);
if Verbose, fprintf('TT.SetFilterWithDescEx(%s)',fwdstr); end

% Filter tank for -2 to 12 ms around stimulus
if ~TT.SetEpocTimeFilterV('Freq',-0.002,0.014)
    error(['SimpleABR | Unable to set epoc time filter ' ...
        '\n\t(TT.SetEpocTimeFilterV(''Freq'',-0.002,0.014)'])
end


n = TT.ReadEventsSimple('wABR');

if Verbose, fprintf('TT.ReadEventsSimple(''wABR'') == %d\n',n); end

wABR = TT.ParseEvV(0,n);



function initOpenDev(ABRtank)
global TT DA

DA = TDT_SetupDA(ABRtank);

TT = TDT_SetupTT;
TT.OpenTank(ABRtank,'R');
block = TT.GetHotBlock;
TT.SelectBlock(block);
TT.CreateEpocIndexing;



























% Graphing ================================================================
function plotCurrentResponse(data,style)

plotfig = findFigure('meanABRfig','backgorundcolor','w');

figure(plotfig);

ax = get(plotfig,'children');

if isempty(ax), ax = gca; end

cla(ax);

mdata = mean(data);
sdata = std(data);

tvec = linspace(-2,12,size(mdata,1));

hold(ax,'on');
plot(ax,tvec,mdata,'-','linewidth',3);
plot(ax,1:size(data,1),mdata+sdata,'-','linewidth',1);
plot(ax,1:size(data,1),mdata-sdata,'-','linewidth',1);
hold(ax,'off');

ylim(ax,[-1 1]*max(abs(mdata)+(sdata)));

grid(ax,'on');













% Timer functions
function T = createTimer(h)
f = h.figure1;

T = timerfind('tag','ABRtimer');
if ~isempty(T), delete(T); end

T = timer('tag','ABRtimer','ExecutionMode','fixedDelay','BusyMode','drop', ...
    'Period',1,'TasksToExecute',inf, ...
    'StartFcn',{@ABRtimerStart,f}, ...
    'TimerFcn',{@ABRtimerRun,f}, ...
    'StopFcn', {@ABRtimerStop,f});




function ABRtimerStart(hObj,e,f)
initOpenDev('ABRtank');





function ABRtimerRun(hObj,e,f)

h = guidata(f);

freq = str2double(get(h.txtFreq,'String'));
level = str2double(get(h.txtLevel,'String'));

wABR = GetResponses(freq,level);

plotCurrentResponse(wABR)









function ABRtimerStop(hObj,e,f)

global TT

TT.CloseTank;

















