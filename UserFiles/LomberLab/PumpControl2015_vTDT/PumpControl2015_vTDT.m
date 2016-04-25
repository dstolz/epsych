function varargout = PumpControl2015_vTDT(varargin)
% PumpControl2015_vTDT MATLAB code for PumpControl2015_vTDT.fig

% Edit the above text to modify the response to help PumpControl2015_vTDT

% Last Modified by GUIDE v2.5 23-Sep-2015 10:30:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PumpControl2015_v2_OpeningFcn, ...
                   'gui_OutputFcn',  @PumpControl2015_v2_OutputFcn, ...
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


% --- Executes just before PumpControl2015_vTDT is made visible.
function PumpControl2015_v2_OpeningFcn(hObj, ~, h, varargin)
global DUINO

% elevate Matlab.exe process to a high priority in Windows
[~,~] = dos('wmic process where name="MATLAB.exe" CALL setpriority "high priority"');

h.output = hObj;

guidata(hObj, h);

h = StartupPrefs(h);

ColEditable(h.ControlTable,1);

if isempty(DUINO)
    DUINO = ArduinoConnect;
end

h.MaxNumPumps = ArduinoCom(DUINO,'n');

T = CreateTimer(h);

guidata(hObj, h);

start(T);



% --- Outputs from this function are returned to the command line.
function varargout = PumpControl2015_v2_OutputFcn(hObj, ~, h)
varargout{1} = h.output;


function CloseFig(h) %#ok<DEFNU>
global DUINO

StorePrefs(h);

try
    T = timerfind('Tag','PumpTimer');
    if ~isempty(T) && isvalid(T)
        stop(T);
        pause(0.1);
        delete(T);
        clear T;
    end
end

if ~isempty(DUINO)
    fprintf('Closing serial connection with Arduino ...')
    fclose(DUINO);
    delete(DUINO);
    clear global DUINO
    fprintf(' Closed\n');
end


delete(h.PumpControl);

[~,~] = dos('wmic process where name="MATLAB.exe" CALL setpriority "normal"');


function h = StartupPrefs(h)
sp = getpref('PumpControl2015_vTDT','PLOT',true);
if sp
    set(h.show_plot,'checked','on');
else
    set(h.show_plot,'checked','off');
end

prevdata = getpref('PumpControl2015_vTDT','ControlTable_Data',dfltpump);
prevdata(:,4) = {0}; % begin with PID off

set(h.ControlTable,'Data',prevdata);
h.NPumps = size(prevdata,1);

[h.PLOT(1:h.NPumps).show] = deal(sp);

[h.DATA(1:h.NPumps).temp] = deal([]);
[h.DATA(1:h.NPumps).rate] = deal([]);
[h.DATA(1:h.NPumps).time] = deal([]);
[h.DATA(1:h.NPumps).targ] = deal([]);
[h.DATA(1:h.NPumps).etime] = deal([]);
[h.DATA(1:h.NPumps).StartTime] = deal(clock);
for i = 1:h.NPumps
    h.DATA(i).name = prevdata{i,1};
end

aot = getpref('PumpControl2015_vTDT','AOT',false);
AlwaysOnTop(h,aot);

function StorePrefs(h)
setpref('PumpControl2015_vTDT','ControlTable_Data',get(h.ControlTable,'Data'));
setpref('PumpControl2015_vTDT','PLOT',strcmp(get(h.show_plot,'checked'),'on'));
setpref('PumpControl2015_vTDT','AOT',strcmp(get(h.always_on_top,'Checked'),'on'));










%% TDT integration
function Temp = TDT_TempUpdate(PumpID)
global G_DA

% read value from TDT module






%% Get
function Mode = GetPumpMode(PumpID)
Mode = ArduinoCom(sprintf('m,%d',PumpID));
if isempty(Mode), Mode = nan; end

function PumpSpeed = GetPumpSpeed(PumpID)
PumpSpeed = ArduinoCom(sprintf('s,%d',PumpID));
if isempty(PumpSpeed), PumpSpeed = nan; end

function Temp = GetTemp(PumpID)
Temp = ArduinoCom(sprintf('c,%d',PumpID));
if isempty(Temp), Temp = nan; end

function Targ = GetTargTemp(PumpID)
Targ = ArduinoCom(sprintf('t,%d',PumpID));
if isempty(Targ), Targ = nan; end



%% Set
function SetPumpMode(PumpID,Automatic)
ArduinoCom(sprintf('M,%d,%d',PumpID,Automatic));

function SetPumpSpeed(PumpID,Speed)
ArduinoCom(sprintf('S,%d,%0.2f',PumpID,Speed));

function SetTargTemp(PumpID,TargTemp)
if TargTemp <= 0
    q = questdlg(sprintf('Low target temperature (%0.2f C).  Are you certain you would like to continue?',TargTemp), ...
        'Low Target Temp','Continue','Cancel','Cancel');
    if isequal(q,'Cancel'), return; end
end
ArduinoCom(sprintf('T,%d,%0.2f',PumpID,TargTemp));















%% Control Table
function ControlTable_CellEditCallback(hObj,e,~) %#ok<DEFNU>
% Column definitions:
% 1. Pump Name
% 2. Current Temp (read only)
% 3. Target Temp
% 4. PID
% 5. Pump Speed (read only if PID == 1; write if PID == 0)

PumpID = e.Indices(1)-1;
Col    = e.Indices(2);
Val    = e.NewData;

switch Col
    case 3 % Check if within range and update target temperature
        SetTargTemp(PumpID,Val);
        
    case 4 % Toggle Automatic PID/Manual control 
        if e.EditData
            SetPumpMode(PumpID,e.EditData);
        else
            SetPumpSpeed(PumpID,0);
        end
        ColEditable(hObj,e.EditData+1);
        Cdata = get(hObj,'Data');
        Cdata{PumpID+1,4} = e.EditData;
        set(hObj,'Data',Cdata);

        
    case 5 % Update pump speed (Manual mode only)
        SetPumpSpeed(PumpID,Val);
end

setpref('PumpControl2015_vTDT','ControlTable_Data',get(hObj,'Data'));


function ControlTable_CellSelectionCallback(hObj, e, ~) %#ok<DEFNU>
if isempty(e.Indices), return; end
PumpID = e.Indices(1)-1;
Col    = e.Indices(2);

Cdata = get(hObj,'Data');
switch Col
    case 3 % Update target temp
        ct = Cdata{PumpID+1,3};
        if isempty(ct), ct = Cdata{PumpID+1,2}; end
        ct = num2str(ct,'%0.2f');
        a = inputdlg(sprintf('Enter Target Temperature for Pump ''%s'':', ...
            Cdata{PumpID+1,1}),'Target Temp',1,{ct});
        a = char(a);
        if isempty(a), return; end
        Cdata{PumpID+1,3} = str2double(a);
        SetTargTemp(PumpID,Cdata{PumpID+1,3});
        set(hObj,'Data',Cdata);
        

end


function p = dfltpump
p = {'Pump',[],[],0,[]};


function ce = ColEditable(Obj,state)
switch state 
    case 1 % PID off
        ce = [1 0 1 1 1];
        
    case 2 % PID on
        ce = [1 0 1 1 0];
        
end
ce = logical(ce);
set(Obj,'ColumnEditable',ce);




function TargetTemps(hObj,h)
t = str2double(get(hObj,'String'));
for PumpID = 0:h.NPumps-1
    SetTargTemp(PumpID,t);
end

function ToggleModes(hObj,h)
v = get(hObj,'Value');
for PumpID = 0:h.NPumps-1
    SetPumpMode(PumpID,v);
end

function PumpSpeeds(hObj,h)
Speed = str2double(get(hObj,'String'));
if Speed < 0 || Speed > 100
    msgbox('Invalid speed value.  Must be between 0 and 100.','Invalid Value', ...
        'error','modal');
    return
end

for PumpID = 0:h.NPumps-1
    SetPumpSpeed(PumpID,Speed)
end











%% GUI
function AddPump(h) %#ok<DEFNU>

Cdata = get(h.ControlTable,'Data');

if h.NPumps == h.MaxNumPumps
    msgbox(sprintf('Arduino code currently running permits a maximum of %d pumps.',h.MaxNumPumps),...
        'Max Pumps','warn','modal');
    return
end

Cdata(end+1,:) = dfltpump;

h.DATA(end+1).temp = [];
h.DATA(end).rate = [];
h.DATA(end).time = [];
h.DATA(end).targ = [];
h.DATA(end).etime = [];
h.DATA(end).StartTime = clock;
h.DATA(end).name = 'Pump';

h.NPumps = length(h.DATA);

set(h.ControlTable,'Data',Cdata);

guidata(h.PumpControl,h);
pause(0.01);

function RemovePump(h) %#ok<DEFNU>

Cdata = get(h.ControlTable,'Data');

PumpNames = cellfun(@(a,b) (sprintf('%d. %s',a,b)),num2cell(1:size(Cdata,1))',Cdata(:,1), ...
    'UniformOutput',false);

[sel,ok] = listdlg('ListString',PumpNames,'SelectionMode','multiple',...
    'Name','Remove Pump','PromptString','Remove one or multiple pumps', ...
    'OKString','Remove','listsize',[160 100]);
if ~ok, return; end


Cdata(sel,:) = [];

if isempty(Cdata), Cdata = dfltpump; end

set(h.ControlTable,'Data',Cdata);

h.DATA(sel) = [];
h.NPumps = length(h.DATA);

if any([h.PLOT.show])
    h = CreatePlotFigure(h);
end

guidata(h.PumpControl,h);
pause(0.1);









%% Timer
function T = CreateTimer(h)
T = timerfind('Tag','PumpTimer');
if ~isempty(T) && isvalid(T), stop(T); delete(T); end

F = h.PumpControl;
C = h.ControlTable;

T = timer('Tag','PumpTimer','StartDelay',0,'Period',1,'TasksToExecute',inf, ...
    'ExecutionMode','fixedDelay','BusyMode','queue', ...
    'StartFcn',{@PumpTimerStartFcn,F}, ...
    'TimerFcn',{@PumpTimerFcn,F,C}, ...
    'StopFcn', {@PumpTimerStopFcn,F}, ...
    'ErrorFcn',{@PumpTimerErrorFcn,F});

function PumpTimerStartFcn(~,~,F)
h = guidata(F);
if any([h.PLOT.show]), h = CreatePlotFigure(h); end
set(h.comstatusindicator,'BackgroundColor',[0.40 1.00 0.40]); drawnow
guidata(F,h);

function PumpTimerFcn(hObj, e, F, C) %#ok<INUSL>
try
h = guidata(F);


Cdata = cell(h.NPumps,5);
for PumpID = 0:h.NPumps-1
    while 1
        PumpData = GetSomeData(PumpID);
        if ~isempty(PumpData.temp), break; end
    end
    h.DATA(PumpID+1).time(end+1) = now;
    h.DATA(PumpID+1).etime(end+1) = etime(clock,h.DATA(PumpID+1).StartTime);
    h.DATA(PumpID+1).temp(end+1) = PumpData.temp;
    h.DATA(PumpID+1).targ(end+1) = PumpData.targ;
    h.DATA(PumpID+1).rate(end+1) = PumpData.rate;
    Cdata{PumpID+1, 1} = h.DATA(PumpID+1).name;
    Cdata{PumpID+1, 2} = h.DATA(PumpID+1).temp(end);
    Cdata{PumpID+1, 3} = h.DATA(PumpID+1).targ(end); % <== unneccessary?
    Cdata{PumpID+1, 4} = PumpData.mode;
    Cdata{PumpID+1, 5} = h.DATA(PumpID+1).rate(end);
end


set(C,'Data',Cdata);

if get(h.Record_Control,'Value')
    RecordData(h);
end

h = PlotData(h);

guidata(h.PumpControl,h);
catch me
   rethrow(me) 
end

function PumpTimerStopFcn(~, ~, F)
h = guidata(F);
% set(h.comstatusindicator,'BackgroundColor',[0.85 0.35 0.40]); drawnow
set(h.comstatusindicator,'BackgroundColor',[0.93 0.96 0.62]); drawnow




function PumpTimerErrorFcn(~, e, F)
h = guidata(F);

set(h.comstatusindicator,'BackgroundColor','R'); drawnow

errordlg(e.Data.message,e.Data.messageID,'modal')

rethrow(e.Data);
















%% Data handling
function LogFileName(h)
[fn,pn] = uiputfile({'*.csv','Comma Separated Values (*.csv)'}, ...
    'Log File Name');

if ~fn, return; end

h.logfilename = fullfile(pn,fn);

set(h.Log_File_Name,'Label',sprintf('Log File: %s',fn));

guidata(h.PumpControl,h);



function RecordControl(hObj,h) %#ok<DEFNU>
T = timerfind('tag','PumpTimer');
stop(T);

if get(hObj,'Value') == 1
    % need log file to begin recording
    if ~isfield(h,'logfilename')
        LogFileName(h);
        h = guidata(h.PumpControl);
    end
    
    if ~isfield(h,'logfilename')
        start(T);
        return
    end
        
    h.logfid = fopen(h.logfilename,'a+');
    if h.logfid == -1
        set(hObj,'Value',0);
        error('Unable to access file ''%s''.',h.logfilename)
    end
    
    c = clock;
    fprintf(h.logfid,'\n\nStart Timestamp:,%s\n\n',datestr(c,'mmm.dd,yyyy HH:MM:SS.FFF'));
    [h.DATA(1:h.NPumps).StartTime] = deal(c);

    fprintf(h.logfid,'Timestamp,Pump ID,Pump Name,Temp,Target Temp,PID State,Pump Speed\n');
    
    fprintf('Recording data to log file: %s\n',h.logfilename)
    
    set(hObj,'BackgroundColor',[0.40 1.00 0.40],'String','Recording', ...
        'FontAngle','italic','TooltipString','Click to STOP Recording'); drawnow
    
    
else
    if isfield(h,'logfid') && h.logfid > 2
        fclose(h.logfid);
    end
    
    set(hObj,'BackgroundColor',[1.0 0.388 0.388],'String','Record', ...
        'FontAngle','normal','TooltipString','Click to START Recording'); drawnow
end

guidata(h.PumpControl,h);

start(T);



function RecordData(h)
Cdata = get(h.ControlTable,'Data');


T = timerfind('Tag','PumpTimer'); % TESTING
ip = get(T,'InstantPeriod');
for i = 1:length(h.DATA)
    fprintf(h.logfid,'%s,%d,%s,% 2.2f,% 2.2f,%d,% 3.2f,%0.6f\n', ...
        h.DATA(i).etime(end),i-1,h.DATA(i).name, ...
        Cdata{i,2},h.DATA(i).targ(end),Cdata{i,4},Cdata{i,5},ip);
end

















%% Plotting
function ShowPlot(PlotOn,h)
if PlotOn
    if isfield(h,'PLOT') && isfield(h.PLOT,'f') && ishandle(h.PlotFigh)
        close(h.PlotFigh);
    end
    set(h.show_plot,'checked','off');
else
    h = CreatePlotFigure(h);
    set(h.show_plot,'checked','on');

end

[h.PLOT.show] = deal(~PlotOn);

guidata(h.PumpControl,h);

function ClosePlotFigure(hObj,~,hMain)
try
    h = guidata(hMain);
    [h.PLOT.show] = deal(false);
    set(h.show_plot,'checked','off');
    delete(hObj);
catch %#ok<CTCH>
    close(hObj,'force');
end

function h = CreatePlotFigure(h)
f = findFigure('PumpControlFig','color',get(h.PumpControl,'color'), ...
    'units','normalized','Position',[0.4 0.07 0.5 0.3], ...
    'CloseRequestFcn',{@ClosePlotFigure,h.PumpControl});

clf(f);
figure(f);

Cdata = get(h.ControlTable,'Data');

nrows = size(Cdata,1);
[P(1:nrows).ax_temp] = deal(0);
[P(1:nrows).ax_rate] = deal(0);
for PumpID = 0:nrows-1
    P(PumpID+1).ax_temp = subplot(nrows,1,PumpID+1,'ycolor','b','xticklabel',[], ...
        'parent',f);
    
    P(PumpID+1).ax_rate = axes('position',get(P(PumpID+1).ax_temp,'position'), ...
        'color','none','yaxislocation','right','ycolor','k','xticklabel',[], ...
        'xtick',[],'parent',f); 
    title(P(PumpID+1).ax_temp,Cdata{PumpID+1,1});
    ylabel(P(PumpID+1).ax_temp,'temp');
    ylabel(P(PumpID+1).ax_rate,'pump rate');
%     grid(ax_temp,'on');
end
xlabel(P(end).ax_temp,'time');
set(P(end).ax_temp,'xticklabelmode','auto');
set([P.ax_temp],'ylim',[-10 40]);

[P(1:nrows).ln_temp] = deal(0);
[P.show] = deal(true);

h.PLOT = P;
h.PlotFigh = f;


function h = PlotData(h)
if ~any([h.PLOT.show]), return; end

p = ancestor(h.PLOT(1).ax_temp,'figure');
if isempty(p), return; end


for i = 1:length(h.PLOT)   
    if isobject(h.PLOT(i).ln_temp)
        set(h.PLOT(i).ln_temp,'xdata',h.DATA(i).etime,'ydata',h.DATA(i).temp);
        set(h.PLOT(i).ln_rate,'xdata',h.DATA(i).etime,'ydata',h.DATA(i).rate);
        set(h.PLOT(i).pnt_temp,'xdata',h.DATA(i).etime(end),'ydata',h.DATA(i).temp(end));
        set(h.PLOT(i).pnt_rate,'xdata',h.DATA(i).etime(end),'ydata',h.DATA(i).rate(end));
        set(h.PLOT(i).ln_targ,'xdata',h.DATA(i).etime,'ydata',h.DATA(i).targ);
        
    else
        % Target temperature line
        h.PLOT(i).ln_targ = line(h.DATA(i).etime,h.DATA(i).targ, ...
            'linestyle',':','color','r','marker','none', ...
            'parent',h.PLOT(i).ax_temp);
                
        % Pump Rate Line
        h.PLOT(i).ln_rate = line(h.DATA(i).etime,h.DATA(i).rate, ...
            'linestyle',':','color','k','marker','none', ...
            'parent',h.PLOT(i).ax_rate);
        
         % Temperature Line
        h.PLOT(i).ln_temp = line(h.DATA(i).etime,h.DATA(i).temp, ...
            'linestyle','-','color','b','marker','none', ...
            'parent',h.PLOT(i).ax_temp);
        
        % Current Pump Rate Point
        h.PLOT(i).pnt_rate = line(h.DATA(i).etime(end),h.DATA(i).rate(end), ...
            'linestyle','none','marker','s','markeredgecolor','k', ...
            'markerfacecolor',[0.6 0.6 0.6],'parent',h.PLOT(i).ax_rate);
        
        % Current Temperature Point
        h.PLOT(i).pnt_temp = line(h.DATA(i).etime(end),h.DATA(i).temp(end), ...
            'linestyle','none','marker','o','markeredgecolor','b', ...
            'markerfacecolor','c','parent',h.PLOT(i).ax_temp);
        
    end
end












%%
function AdjustTunings(h) %#ok<DEFNU>
T = timerfind('Tag','PumpTimer');
stop(T); pause(0.01);

data = get(h.ControlTable,'Data');
PumpControl_Tunings(data(:,1));

start(T);


function SaveConfig(h)
dflt = getpref('PumpControl2015_vTDT','configpath',cd);

[fn,pn] = uiputfile({'*.pcfg','Pumps Config. (*.pcfg)'},'Save Pump Config File',dflt);

if ~fn, return; end

Data = get(h.ControlTable,'Data');

c = 'pid';
a = 'PID';

Kc = nan(size(Data,1),3);
Ka = nan(size(Data,1),3);
for PumpID = 0:size(Data,1)-1
    for i = 1:size(Kc,2)
        Kc(PumpID+1,i) = GetKval(PumpID,c(i));
        Ka(PumpID+1,i) = GetKval(PumpID,a(i));
    end
end

C.PumpNames = Data(:,1);
C.Kc = Kc;
C.Ka = Ka;
C.Gap = ArduinoCom('g');

save(fullfile(pn,fn),'C');

fprintf('Pump configuration file saved as: %s\n',fullfile(pn,fn))

setpref('PumpControl2015_vTDT','configpath',pn);

function Kval = GetKval(PumpID,p_i_d)
Kval = nan;
if ~ismember(p_i_d,'pidPID'), return; end
Kval = ArduinoCom(sprintf('k%c,%d',p_i_d,PumpID));

function data = GetSomeData(PumpID)
% order of returned buffer: temp,target temp,pump speed,pump mode
buf = ArduinoCom(sprintf('L,%d',PumpID));
c = textscan(buf,'%f,%f,%f,%d');
data.temp = c{1};
data.targ = c{2};
data.rate = c{3};
data.mode = logical(c{4});


function LoadConfig(h)
dflt = getpref('PumpControl2015_vTDT','configpath',cd);

[fn,pn] = uigetfile({'*.pcfg','Pumps Config. (*.pcfg)'},'Locate Pump Config File',dflt);

if ~fn, return; end

load(fullfile(pn,fn),'-mat');

c = 'pid';
a = 'PID';

Data = get(h.ControlTable,'Data');
Data(:,1) = C.PumpNames;
set(h.ControlTable,'Data',Data);

for PumpID = 0:size(C.Kc,1)-1
    for i = 1:size(C.Kc,2)
        ArduinoCom(sprintf('K%c,%d,%0.4f',c(i),PumpID,C.Kc(PumpID+1,i)));
        ArduinoCom(sprintf('K%c,%d,%0.4f',a(i),PumpID,C.Ka(PumpID+1,i)));
    end
end

ArduinoCom(sprintf('G,%d',C.Gap));

set(h.PumpControl,'Name',sprintf('PumpControl2015_vTDT (%s)',fn(1:end-5)));

fprintf('Loaded pump configuration file: %s\n',fullfile(pn,fn))





%% Misc
function ontop = AlwaysOnTop(h,ontop)

if nargin == 1 || isempty(ontop)
    s = get(h.always_on_top,'Checked');
    ontop = strcmp(s,'off');
end

if ontop
    set(h.always_on_top,'Checked','on');
else
    set(h.always_on_top,'Checked','off');
end

set(h.PumpControl,'WindowStyle','normal');

FigOnTop(h.PumpControl,ontop);

