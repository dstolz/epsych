function varargout = CondAvoidGUI(varargin)
% CondAvoidGUI M-file for CondAvoidGUI.fig
%      CondAvoidGUI, by itself, creates a new CondAvoidGUI or raises the existing
%      singleton*.
%
%      H = CondAvoidGUI returns the handle to a new CondAvoidGUI or the
%      handle to
%      the existing singleton*.
%
%      CondAvoidGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CondAvoidGUI.M with the given input arguments.
%
%      CondAvoidGUI('Property','Value',...) creates a new CondAvoidGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CondAvoidGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CondAvoidGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CondAvoidGUI

% Last Modified by GUIDE v2.5 29-May-2015 15:13:34

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CondAvoidGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @CondAvoidGUI_OutputFcn, ...
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


% --- Executes just before CondAvoidGUI is made visible.
function CondAvoidGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CondAvoidGUI (see VARARGIN)

% Choose default command line output for CondAvoidGUI
handles.output = hObject;


% Update handles structure
guidata(hObject, handles);


T = CreateTimer(handles.figure1);

start(T);

set(handles.MaskAlone_radio,'value',1);
set(handles.VaryToneDur_radio,'value',0);
set(handles.VaryToneLevel_radio,'value',0);

MaskAlone_radio_Callback(hObject, eventdata, handles)



% --- Outputs from this function are returned to the command line.
function varargout = CondAvoidGUI_OutputFcn(hObject, eventdata, handles) 
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
    'Period',0.5, ...
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




% This is left over from our first attempt to  use listboxes.
% % --- Executes on selection change in Tone_dBSPL_listbox.
% function Tone_dBSPL_listbox_Callback(hObject, eventdata, handles)
% % hObject    handle to Tone_dBSPL_listbox (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hints: contents = cellstr(get(hObject,'String')) returns Tone_dBSPL_listbox contents as cell array
% %        contents{get(hObject,'Value')} returns selected item from Tone_dBSPL_listbox
% 
% global AX RUNTIME
% 
% 
% string = get(hObject,'String');
% value = get(hObject,'Value');
% tonedBSPL = str2num(string{value});
% 
%    
% if RUNTIME.UseOpenEx
%     AX.SetTargetVal('Behave.Tone_dBSPL',tonedBSPL);
% else
%     AX.SetTagVal('Tone_dBSPL',tonedBSPL);
%     disp('setting the value')
% end
% % set(hObject,'Value',1);
% 
% 
% % --- Executes during object creation, after setting all properties.
% function Tone_dBSPL_listbox_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to Tone_dBSPL_listbox (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: listbox controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end






% --- Executes on button press in DeBug_pushbutton.
function DeBug_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to DeBug_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
keyboard








function WaterRate_edit_Callback(hObject, eventdata, handles)
% hObject    handle to WaterRate_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of WaterRate_edit as text
%        str2double(get(hObject,'String')) returns contents of WaterRate_edit as a double

global AX RUNTIME

rate = str2double(get(hObject,'String'));

%Initialize the pump with inner diameter of syringe and water rate in ml/min
TrialFcn_PumpControl(14.5,rate); % 14.5 mm ID (estimate); 0.3 ml/min water rate

% --- Executes during object creation, after setting all properties.
function WaterRate_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to WaterRate_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





% SPOUT TRAINING SECTION (safes only presented)
% --- Executes on button press in MaskAlone_radio.
function MaskAlone_radio_Callback(hObject, eventdata, handles)
% hObject    handle to MaskAlone_radio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of MaskAlone_radio
set(handles.VaryToneDur_radio,'value',0); % these two lines make the radio buttons mutually exclusive
set(handles.VaryToneLevel_radio,'value',0);

global traintype
traintype = 'spoutTrain';





% VARY TONE DURATION SECTION (training with increasingly shorter tones)
% --- Executes on button press in VaryToneDur_radio.
function VaryToneDur_radio_Callback(hObject, eventdata, handles)
% hObject    handle to VaryToneDur_radio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of VaryToneDur_radio
set(handles.MaskAlone_radio,'value',0);% these two lines make the radio buttons mutually exclusive
set(handles.VaryToneLevel_radio,'value',0);
% Update handles structure
guidata(hObject, handles);

%VaryToneDur_edit_Callback(hObject, eventdata, handles)
ToneDur_popup_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function VaryToneDur_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VaryToneDur_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in ToneDur_popup.
function ToneDur_popup_Callback(hObject, eventdata, handles)
% hObject    handle to ToneDur_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ToneDur_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ToneDur_popup
global tonedur traintype

hObject1 = handles.ToneDur_popup;
tone_pop_options = (get(hObject1,'String'));
tone_pop_select = tone_pop_options(get(hObject1,'Value'));
tonedur = str2double(tone_pop_select);
if get(handles.VaryToneDur_radio,'value');
traintype = 'varydurTrain';
end

% --- Executes during object creation, after setting all properties.
function ToneDur_popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ToneDur_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% VARY TONE LEVEL SECTION (testing for tone threshold)
% --- Executes on button press in VaryToneLevel_radio.
function VaryToneLevel_radio_Callback(hObject, eventdata, handles)
% hObject    handle to VaryToneLevel_radio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of VaryToneLevel_radio
set(handles.MaskAlone_radio,'value',0);% these two lines make the radio buttons mutually exclusive
set(handles.VaryToneDur_radio,'value',0);
% Update handles structure
guidata(hObject, handles);

%VaryToneLevel_edit_Callback(hObject, eventdata, handles)
ToneLev_popup_Callback(hObject, eventdata, handles)


% --- Executes on selection change in ToneLev_popup.
function ToneLev_popup_Callback(hObject, eventdata, handles)
% hObject    handle to ToneLev_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ToneLev_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ToneLev_popup
global tonelev traintype

hObject1 = handles.ToneLev_popup;
lev_pop_options = (get(hObject1,'String'));
lev_pop_select = lev_pop_options(get(hObject1,'Value'));
tonelev = str2double(lev_pop_select);
if get(handles.VaryToneLevel_radio,'value');
traintype = 'varylevTest';
end

% --- Executes during object creation, after setting all properties.
function ToneLev_popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ToneLev_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
