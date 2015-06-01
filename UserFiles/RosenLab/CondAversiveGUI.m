function varargout = CondAversiveGUI(varargin)
% FORWARDMASKAVERSIVEGUI M-file for ForwardMaskAversiveGUI.fig
%      FORWARDMASKAVERSIVEGUI, by itself, creates a new FORWARDMASKAVERSIVEGUI or raises the existing
%      singleton*.
%
%      H = FORWARDMASKAVERSIVEGUI returns the handle to a new FORWARDMASKAVERSIVEGUI or the handle to
%      the existing singleton*.
%
%      FORWARDMASKAVERSIVEGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FORWARDMASKAVERSIVEGUI.M with the given input arguments.
%
%      FORWARDMASKAVERSIVEGUI('Property','Value',...) creates a new FORWARDMASKAVERSIVEGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ForwardMaskAversiveGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ForwardMaskAversiveGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ForwardMaskAversiveGUI

% Last Modified by GUIDE v2.5 26-May-2015 17:25:13

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ForwardMaskAversiveGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ForwardMaskAversiveGUI_OutputFcn, ...
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


% --- Executes just before ForwardMaskAversiveGUI is made visible.
function ForwardMaskAversiveGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ForwardMaskAversiveGUI (see VARARGIN)

% Choose default command line output for ForwardMaskAversiveGUI
handles.output = hObject;


% Update handles structure
guidata(hObject, handles);


T = CreateTimer(handles.figure1);

start(T);






% --- Outputs from this function are returned to the command line.
function varargout = ForwardMaskAversiveGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;















function CloseReq(f) %#ok<DEFNU>
T = timerfind('Name','BoxTimer');
if ~isempty(T), stop(T); delete(T); end

delete(f);




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



function BoxTimerSetup(hObj,~,f)
global RUNTIME

h = guidata(f);

RUNTIME.StartTime = clock;

cols = {'ResponseCode','TrialType','Tone_Dur','Tone_dBSPL','Noise_Dur','Noise_dBSPL'};

set(h.DataTable,'ColumnName',cols,'data',[]);
set(h.NextTrialTable,'ColumnName',cols(2:end),'data',[],'RowName','>');

cla(h.AxPerformance);


function BoxTimerRunTime(hObj,~,f)
global RUNTIME

h = guidata(f);

T = RUNTIME.TRIALS;

if T.TrialIndex == 1, return; end

cols = get(h.DataTable,'ColumnName');

if RUNTIME.UseOpenEx
    cols = cellfun(@(a) (['Behave_' a]),cols,'UniformOutput',false);
    ind = ~cellfun(@isempty,strfind(cols,'ResponseCode'));
    cols{ind} = 'ResponseCode';
end

d = zeros(T.TrialIndex-1,length(cols));
for i = 1:length(cols)
    d(:,i) = [T.DATA.(cols{i})];
end


ts = zeros(T.TrialIndex-1,1);
for i = 1:T.TrialIndex-1
    ts(i) = etime(T.DATA(i).ComputerTimestamp,RUNTIME.StartTime);
end

PlotPerformance(h.AxPerformance,ts,[T.DATA.ResponseCode]);


d = flipud(d);

rows = T.TrialIndex-1:-1:1;

set(h.DataTable,'Data',d,'RowName',rows);

cols = get(h.NextTrialTable,'ColumnName');

if RUNTIME.UseOpenEx
    cols = cellfun(@(a) (['Behave.' a]),cols,'UniformOutput',false);
end

p = T.trials(T.NextTrialID,:);
nt = zeros(size(cols));
for i = 1:length(cols)
    ind = ismember(T.writeparams,cols{i});
    nt(i) = p{find(ind,1)};
end
set(h.NextTrialTable,'Data',nt(:)');

ind = ~cellfun(@isempty,strfind(T.writeparams,'TrialType'));
ind = find(ind,1);
if p{ind} == 1
    set(h.NextTrialTable,'ForegroundColor','g');
else
    set(h.NextTrialTable,'ForegroundColor','r');
end





function BoxTimerError(~,~)



function BoxTimerStop(~,~)









function PlotPerformance(ax,ts,RCode)

HITS = RCode == 17;
MISS = RCode == 18;
CR   = RCode == 40;
FA   = RCode == 36;


ind = ts < ts(end) - 60;
ts(ind) = [];
HITS(ind) = [];
MISS(ind) = [];
CR(ind) = [];
FA(ind) = [];

cla(ax);

hold(ax,'on');
plot(ax,ts(HITS),2*ones(sum(HITS),1),'rs','markerfacecolor','r');
plot(ax,ts(MISS),ones(sum(MISS),1),'ro','markerfacecolor','r');
plot(ax,ts(CR),ones(sum(CR),1),'gs','markerfacecolor','g');
plot(ax,ts(FA),2*ones(sum(FA),1),'go','markerfacecolor','g');
hold(ax,'off');

set(ax,'ylim',[0 2.5],'xlim',[ts(end)-60 ts(end)]);


% --- Executes on button press in TrigWater.
function TrigWater_Callback(hObject, eventdata, handles)
% hObject    handle to TrigWater (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global AX RUNTIME

c = get(hObject,'backgroundcolor');
set(hObject,'backgroundcolor','g'); drawnow

if RUNTIME.UseOpenEx
    AX.SetTargetVal('Behave.!AddDrop',1);
    pause(0.001);
    AX.SetTargetVal('Behave.!AddDrop',0);
else
    AX.SetTagVal('!AddDrop',1);
    pause(0.001);
    AX.SetTagVal('!AddDrop',0);
end

set(hObject,'backgroundcolor',c); drawnow


% --- Executes on button press in Pause.
function Pause_Callback(hObject, eventdata, handles)
% hObject    handle to Pause (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Pause

global AX RUNTIME

c = get(handles.figure1,'color');





if get(hObject,'Value') == 1
    set(hObject,'backgroundcolor','r'); drawnow
    if RUNTIME.UseOpenEx
        AX.SetTargetVal('Behave.!Pause',1);
    else
        AX.SetTagVal('!Pause',1);
    end
else
    if RUNTIME.UseOpenEx
        AX.SetTargetVal('Behave.!Pause',0);
    else
        AX.SetTagVal('!Pause',0);
    end
    set(hObject,'backgroundcolor',c); drawnow
end


% --- Executes on selection change in toneamp_pop.
function toneamp_pop_Callback(hObject, eventdata, handles)
% hObject    handle to toneamp_pop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns toneamp_pop contents as cell array
%        contents{get(hObject,'Value')} returns selected item from toneamp_pop

global AX RUNTIME


vals = get(hObject,'String');
chosen = get(hObject,'Value');
str2num(vals{chosen})
if RUNTIME.UseOpenEx
    switch str2num(vals{chosen})
        case 40
            AX.SetTargetVal('Behave.Tone_dBSPL',40);
        case 60
            AX.SetTargetVal('Behave.Tone_dBSPL',60);
        case 80
            AX.SetTargetVal('Behave.Tone_dBSPL',80);
    end
else
    switch str2num(vals{chosen})
        case 40
            AX.SetTagVal('Tone_dBSPL',40);
        case 60
            AX.SetTagVal('Tone_dBSPL',60);
        case 80
            AX.SetTagVal('Tone_dBSPL',80);
    end
end
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function toneamp_pop_CreateFcn(hObject, eventdata, handles)
% hObject    handle to toneamp_pop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
