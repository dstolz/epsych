function varargout = SimpleABR(varargin)
% SimpleABR

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

Verbose = getpref('StimpleABR','Verbose',true);

populateParams(h);


% Update h structure
guidata(hObj, h);





% --- Outputs from this function are returned to the command line.
function varargout = SimpleABR_OutputFcn(hObj, ~, h) 

varargout{1} = h.output;
















% GUI =====================================================================
function prgrmState(hObj,h)
global DA



state = get(hObj,'String');

switch upper(state)
    case 'START'
        T = createTimer(h);
        initOpenDev('ABRtank');
        start(T);
        set(hObj,'String','Stop');
       
        
    case 'STOP'
        T = timerfind('tag','SimpleABRtimer');
        if ~isempty(T), stop(T); end
        if isa(DA,'COM.TDevAcc_X')
            DA.CloseConnection;
            delete(DA);
        end
        set(hObj,'String','Start');
        
    case 'ERROR'
        set(hObj,'String','Start');
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
    P.ISI.value            = 1000/P.StimRate.value-P.StimDuration.value;
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

setpref('SimpleABR','Params',P);



function updateVals(h)
global DA Verbose

S = get(h.tblParams,'Data');
P = get(h.tblParams,'UserData');
fn = fieldnames(P);

DA.SetTargetVal('ABRStim.StimOn',0);

for i = 1:length(fn)
    if isempty(P.(fn{i}).tag), continue; end

    ustr = sprintf('Updated ''%s'' => %0.2f ',P.(fn{i}).tag,P.(fn{i}).value);
    
    e = DA.SetTargetVal(['ABRStim.' P.(fn{i}).tag],S{i,2});
    
    if e
        fprintf(2,'%sFAILED!\n',ustr) %#ok<PRTCAL>
    elseif Verbose
        fprintf('%sok\n',ustr)
    end
end

% fprintf('Updated values: Frequency = % 5.1f Hz, Level = % 3.2 V\n', freq, level)

e = DA.SetTargetVal('ABRStim.StimOn',1);

if e && Verbose
    fprintf('ABRStim.StimOn: SUCCESSFUL\n')
elseif ~e
    fprintf(2,'ABRStim.StimOn: FAILED!\n')
end

















% Data Access =============================================================
function wABR = GetResponses(Freq,Level)
global TT Verbose


TT.SetFilterTolerance(0.01);

TT.SetGlobals('Channel=1; MaxReturn=1000000; Options=FILTERED');

fwdstr = sprintf('Freq=%d AND Levl=%0.1f',Freq,Level);
TT.SetFilterWithDescEx(fwdstr);
if Verbose, fprintf('TT.SetFilterWithDescEx(%s)\n',fwdstr); end

% Filter tank for -2 to 12 ms around stimulus
% if ~TT.SetEpocTimeFilterV('Freq',-0.002,0.014)
%     error(['SimpleABR | Unable to set epoc time filter ' ...
%         '\n\t(TT.SetEpocTimeFilterV(''Freq'',-0.002,0.014)'])
% end


n = TT.ReadEventsSimple('wABR');

if Verbose, fprintf('TT.ReadEventsSimple(''wABR'') == %d\n',n); end

if n > 0
    wABR = TT.ParseEvV(0,n);
else
    wABR = [];
end



function initOpenDev(ABRtank)
global TT DA Verbose

dastr = sprintf('Opening TDevAcc.X connection to tank: ''%s'' ',ABRtank);
DA = TDT_SetupDA(ABRtank);

if isa(DA,'COM.TDevAcc_X')
    if Verbose, fprintf('%s ok\n',dastr); end
else
    error('%s FAILED!\n',dastr);
end

if Verbose, fprintf('Setting OpenWorkbench mode to ''Record'''); end
DA.SetSysMode(3);
pause(3);
if ~DA.GetSysMode == 3
    error('SimpleABR | Unable to set mode to ''Record''');
else
    if Verbose, fprintf(' ok\n'); end
end

ttstr = sprintf('Opening TTank.X connection to tank: ''%s'' ',ABRtank);
TT = TDT_SetupTT;
if isa(TT,'COM.TTank_X')
    if Verbose, fprintf('%s ok\n',ttstr); end
else
    error('%s FAILED!\n',ttstr);
end

TT.OpenTank(ABRtank,'R');
block = TT.GetHotBlock;
if Verbose, fprintf('Current Block: %s\n',block); end
TT.SelectBlock(block);
TT.CreateEpocIndexing;



























% Graphing ================================================================
function plotCurrentResponse(data)

plotfig = findFigure('meanABRfig','color','w');

figure(plotfig);

ax = get(plotfig,'children');

if isempty(ax), ax = gca; end

cla(ax);

if isempty(data)
    title('No Data to Display')
    return
end

mdata = mean(data);
sdata = std(data);

tvec = linspace(-2,12,length(mdata));

hold(ax,'on');
plot(ax,tvec,mdata,'-','linewidth',3);
plot(ax,1:size(data,1),mdata+sdata,'-','linewidth',1);
plot(ax,1:size(data,1),mdata-sdata,'-','linewidth',1);
hold(ax,'off');

ym = max(abs(mdata)+(sdata));
if isnan(ym) || ym == 0 || ~isnumeric(ym), ym = 1; end
ylim(ax,[-1 1]*ym);

grid(ax,'on');













% Timer functions
function T = createTimer(h)
f = h.figure1;

T = timerfind('tag','SimpleABRtimer');
if ~isempty(T), delete(T); end

T = timer('tag','SimpleABRtimer','ExecutionMode','fixedDelay','BusyMode','drop', ...
    'Period',1,'TasksToExecute',inf, ...
    'StartFcn',{@ABRtimerStart,f}, ...
    'TimerFcn',{@ABRtimerRun,f}, ...
    'ErrorFcn',{@ABRtimerError,f}, ...
    'StopFcn', {@ABRtimerStop,f});




function ABRtimerStart(hObj,e,f)

updateVals(guidata(f));



function ABRtimerRun(hObj,e,f)

h = guidata(f);

S = get(h.tblParams,'Data');
ind = ismember(S(:,1),'Frequency');
freq = S{ind,2};

ind = ismember(S(:,1),'Level');
level = S{ind,2};

wABR = GetResponses(freq,level);

plotCurrentResponse(wABR)



function ABRtimerError(hObj,e,f)
closeTDT

h = guidata(f);
set(h.btnState,'String','ERROR!','tooltipstring','Click to reset')



function ABRtimerStop(hObj,e,f)
closeTDT
h = guidata(f);
set(h.btnState,'String','Start');


function closeTDT
global TT DA

try
    TT.CloseTank;
    h = findobj('Type','figure','-and','Name','TTankFig');
    close(h);
end

try
    DA.SetSysMode(0);
    pause(0.5);
    h = findobj('Type','figure','-and','Name','ODevFig');
    close(h);
end












