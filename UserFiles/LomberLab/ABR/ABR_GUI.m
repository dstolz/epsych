function varargout = ABR_GUI(varargin)
% ABR_GUI;
%
% For use in conjunction with ep_EPhys and TrialFcn_ABR
%
% Daniel.Stolzberg@gmail.com 2015

% Last Modified by GUIDE v2.5 15-Dec-2015 16:30:37

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ABR_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ABR_GUI_OutputFcn, ...
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


% --- Executes just before ABR_GUI is made visible.
function ABR_GUI_OpeningFcn(hObj, e, h, varargin)
% Choose default command line output for ABR_GUI
h.output = hObj;

h = initGUI(h);

% Update h structure
guidata(hObj, h);



% --- Outputs from this function are returned to the command line.
function varargout = ABR_GUI_OutputFcn(hObj, e, h) 

% Get default command line output from h structure
varargout{1} = h.output;
























% GUI =====================================================================

function h = initGUI(h)
global TT G_DA

% G_DA should already be initialized by ep_EPsych
h.INFO.tankName = G_DA.GetTankName;

TT = TDT_SetupTT;

vprintf(1,'Opening tank: %s',h.INFO.tankName)
TT.OpenTank(h.INFO.tankName,'R');

h.INFO.blockName = TT.GetHotBlock;

if isempty(h.INFO.blockName)
    vprintf(2,'Current Block name not found using TT.GetHotBlock.')
    vprintf(2,'Trying to get block name using TDT2mat.')
    b = TDT2mat(h.INFO.tankName);
    h.INFO.blockName = b{end};
end

vprintf(1,'Current block: %s',h.INFO.blockName)

h.TIMER = CreateTimer(h.figure1);

start(h.TIMER);

vprintf(1,'Waiting for ABR timer to begin ...')


function [Freq,Level] = updateParamTable(htbl)
global G_DA G_COMPILED


cur_val = cell(size(G_COMPILED.writeparams));
for i = 1:length(G_COMPILED.writeparams)
    cur_val{i} = G_DA.GetTargetVal(G_COMPILED.writeparams{i});
    vprintf(3,'Parameter: ''%s'' = %0.3f',G_COMPILED.writeparams{i},cur_val{i})
end


Freq  = cur_val{ismember(G_COMPILED.writeparams,'ABRStim.Freq')};
Level = cur_val{ismember(G_COMPILED.writeparams,'ABRStim.Level')};

set(htbl,'Data',[G_COMPILED.writeparams(:), cur_val(:)]);













% Timer ===================================================================

function T = CreateTimer(f)
% Create new timer for RPvds control of experiment
T = timerfind('Name','ABRtimer');
if ~isempty(T)
    stop(T);
    delete(T);
end

T = timer('BusyMode','drop', ...
    'ExecutionMode','fixedSpacing', ...
    'Name','ABRtimer', ...
    'Period',0.5, ...
    'StartDelay',1, ...
    'StartFcn',{@ABRtimerSetup,f}, ...
    'TimerFcn',{@ABRtimerRun,f}, ...
    'ErrorFcn',{@ABRtimerError,f}, ...
    'StopFcn', {@ABRtimerStop,f}, ...
    'TasksToExecute',inf, ...
    'StartDelay',0);


function ABRtimerSetup(~,~,f)
global TT G_DA

h = guidata(f);

h.INFO.startTime = clock;

guidata(f,h);

h.INFO.T1 = 0;
h.INFO.T2 = 0.5;

h.wABR = [];

% get the sampling rate
% D = TDT2mat(h.INFO.tankName,h.INFO.blockName,'T1',0,'T2',1,'type',{'streams'});
% h.INFO.Fs = D.streams.wABR.fs;
h.INFO.Fs = TT.EvSampFreq;

% windowing
h.INFO.win = [-0.002 0.012];
h.INFO.swin = round(h.INFO.Fs*h.INFO.win);
h.INFO.svec = h.INFO.swin(1):h.INFO.swin(2);
h.INFO.valid_win = [0 0.012];
h.INFO.valid_swin = round(h.INFO.Fs*h.INFO.valid_win);
h.INFO.valid_svec = h.INFO.valid_win(1):h.INFO.valid_win(2);

vprintf(2,'Plotting Window: [%0.3f %0.3f] seconds,\t[%d %d] samples', ...
    h.INFO.win,h.INFO.swin)
vprintf(2,'Analysis Window: [%0.3f %0.3f] seconds,\t[%d %d] samples', ...
    h.INFO.valid_win,h.INFO.valid_swin)

G_DA.SetTargetVal('ABRStim.StimOn',1);


guidata(f,h);




function ABRtimerRun(~,~,f)
h = guidata(f);

[h.INFO.Freq,h.INFO.Levl] = updateParamTable(h.tbl_Parameters);

% increment T1 to previous T2 and add 1 sample of time
h.INFO.T1 = h.INFO.T2 + 1/h.INFO.Fs; 

% update T2 to be its previous value plus 0.5 seconds
h.INFO.T2 = h.INFO.T2+0.5;


[data,h.wABR] = getData(h.INFO,h.wABR);


% compute metrics
h.DATA.nstim = size(data,1);
h.DATA.mdata = mean(data);
h.DATA.sdata = std(data);
h.DATA.cdata = corrcoef(data(:,h.INFO.valid_svec));


guidata(f,h);





function ABRtimerStop(~,~,f)




function ABRtimerError(~,~,f)










% Plotting ================================================================

function updateABRmonitor(h)




function hline = add2History(ax,data)



















% Data processing =========================================================



function [data,wABR] = getData(info,wABR)

data = [];

% retrieve all stimulus onsets
vprintf(3,'Retrieving stimulus onsets ...')
E = TDT2mat(info.tankName,info.blockName,'T1',0,'T2',0, ...
    'type',{'epocs'});
vprintf(3,'Number of stimuli present = %d\n\tEarliest = %0.3f,\tLatest = %0.3f', ...
    length(E.epocs.Freq.onsets),E.epocs.Freq.onsets(1),E.epocs.Freq.onsets(end))


ind = E.epocs.Freq.data == info.Freq & E.epocs.Levl.data == info.Level;
if ~any(ind)
    vprintf(2,'No events with values: Freq = %0.1f\tLevel = %0.3f', ...
        info.Freq,info.Level)
    return
end

stim_onsets = E.epocs.Freq.onsets(ind);




% retrieve ABR data stream from tank
vprintf(3,'Retrieving ABR data stream from tank\n\tT1 = %0.3f sec,\tT2 = %0.3f sec', ...
    info.T1,info.T2)
D = TDT2mat(info.tankName,info.blockName,'T1',info.T1,'T2',info.T2, ...
    'type',{'streams'});
vprintf(3,'Length of ABR data stream = %d which is ~%0.3f seconds of data', ...
    length(D.streams.wABR.data),length(D.streams.wABR.data)/info.Fs)

if isempty(D.streams.wABR.data) || any(isnan(D.streams.wABR.data))
    vprintf(2,'No data in wABR stream.')
    return
end
    


% append recent ABR data stream to buffer
wABR = [wABR D.streams.wABR];
vprintf(3,'New wABR buffer length = %d samples (%0.3f seconds)', ...
    length(wABR),length(wABR)/info.Fs)

% onset time -> onset samples
sons = round(info.Fs*stim_onsets); 

% stimulus onsets that would have a window beyond our current buffer
inv = sons+info.svec(end)>length(wABR);
sons(inv) = [];
vprintf(3,'Number of stimuli discarded = %d',sum(inv))

% Cut data buffer based on stimulus onsets
data = zeros(length(sons),length(info.svec));
for i = 1:length(sons)
    sidx = sons+info.svec;
    data(i,:) = wABR(sidx);
end
vprintf(3,'size(data) = [%d %d]',size(data))











