function varargout = Pure_tone_detection_GUI(varargin)
% GUI for pure tone detection task
%     
% Written by ML Caras Jun 10, 2015
%
% Last Modified by GUIDE v2.5 10-Jun-2015 11:24:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Pure_tone_detection_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @Pure_tone_detection_GUI_OutputFcn, ...
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


% --- Executes just before Pure_tone_detection_GUI is made visible.
function Pure_tone_detection_GUI_OpeningFcn(hObject, eventdata, handles, varargin)


% Choose default command line output for Pure_tone_detection_GUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);



% --- Outputs from this function are returned to the command line.
function varargout = Pure_tone_detection_GUI_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

% Create new timer for RPvds control of experiment
T = CreateTimer(hObject);

%Start timer
start(T);





%CREATE TIMER
function T = CreateTimer(f)

% Creates new timer for RPvds control of experiment
T = timerfind('Name','BoxTimer');
if ~isempty(T)
    stop(T);
    delete(T);
end

%All values in seconds
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


%TIMER START FUNCTION
function BoxTimerSetup(hObj,~,f)

%Initialize some GUI text
h = guidata(f);

cols = {'Trial Type','Silent Delay (msec)','Response'};
set(h.DataTable,'Data',{'',[],''},'RowName','0','ColumnName',cols);

nexttrial_cols = {'Trial Type','Silent Delay (msec)'};
set(h.NextTrial,'Data',{'',[]},'RowName','NextTrial','ColumnName',nexttrial_cols);

trial_history_cols = {'Trial Type','Silent Delay (msec)', 'Number of trials'};
set(h.TrialHistory,'Data',{'',[],''},'ColumnName',trial_history_cols);


%TIMER CALLBACK FUNCTION
function BoxTimerRunTime(hObj,~,f)
global RUNTIME USERDATA
persistent lastupdate starttime

%Start the clock
if isempty(starttime) 
    starttime = clock; 
end

h = guidata(f);


%DATA structure
DATA = RUNTIME.TRIALS.DATA; 
ntrials = length(DATA);



%Check if a new trial has been completed
if (RUNTIME.UseOpenEx && isempty(DATA(1).Behavior_TrialType)) ...
        | (~RUNTIME.UseOpenEx && isempty(DATA(1).TrialType)) ...
        | ntrials == lastupdate
    return
end



%Update behavioral variables
if RUNTIME.UseOpenEx
    TrialType = [DATA.Behavior_TrialType]';
    SilentDelay = [DATA.Behavior_Silent_delay]';
else
    TrialType = [DATA.TrialType]';
    SilentDelay = [DATA.Silent_delay]';
end

bitmask = [DATA.ResponseCode]';

HITind  = logical(bitget(bitmask,1));
MISSind = logical(bitget(bitmask,2));
FAind   = logical(bitget(bitmask,4));
CRind   = logical(bitget(bitmask,3));

GOind = find(TrialType == 0);
NOGOind = find(TrialType == 1);

% TS = zeros(ntrials,1);
% for i = 1:ntrials
%     TS(i) = etime(DATA(i).ComputerTimestamp,starttime);
% end





%Update Next trial information 
updateNextTrial(h.NextTrial,USERDATA);

%Update response history table
updateResponseHistory(h.DataTable,HITind,MISSind,...
     FAind,CRind,GOind,NOGOind,TrialType,SilentDelay,ntrials)
 
%Update FA rate
updateFArate(h.FArate,SilentDelay,FAind,NOGOind) 
 

%Calculate hit rates and update plot
updateIOPlot(h.IOPlot,SilentDelay,HITind,GOind);

 
%Update trial history table
updateTrialHistory(h.TrialHistory,SilentDelay,GOind,NOGOind)



%Update Realtime Plot
%UpdateAxHistory(h.axHistory,TS,HITind,MISSind,FAind,CRind);
lastupdate = ntrials;







%----------------------------------------------------------------------
%NEXT TRIAL UPDATE FUNCTION
function updateNextTrial(str,USERDATA)

if USERDATA.TrialType == 0
    trialtype_str = 'GO';
elseif USERDATA.TrialType == 1
    trialtype_str = 'NOGO';
end

NextTrialData = {trialtype_str,USERDATA.SilentDelay};
set(str,'Data',NextTrialData);


%RESPONSE HISTORY FUNCTION
function updateResponseHistory(handle,HITind,MISSind,...
    FAind,CRind,GOind,NOGOind,TrialType,SilentDelay,ntrials)

%Set up response cell array
Responses = cell(size(HITind));
Responses(HITind)  = {'Hit'};
Responses(MISSind) = {'Miss'};
Responses(FAind)   = {'FA'};
Responses(CRind)   = {'CR'};

%Set up trial type cell array
TrialTypeArray = cell(size(TrialType));
TrialTypeArray(GOind) = {'GO'};
TrialTypeArray(NOGOind) = {'NOGO'};

%Establish data table
D = cell(ntrials,4);
D(:,1) = TrialTypeArray;
D(:,2) = num2cell(SilentDelay);
D(:,3) = Responses;

%Flip so the recent trials are on top
D = flipud(D); 

%Number the rows with the correct trial number (i.e. reverse order)
r = length(Responses):-1:1;
r = cellstr(num2str(r'));

set(handle,'Data',D,'RowName',r)


%FALSE ALARM RATE FUNCTION
function updateFArate(handle,SilentDelay,FAind,NOGOind)

%Compile data into a matrix 
currentdata = [SilentDelay,FAind];

%Select out just the NOGO trials
NOGOtrials = currentdata(NOGOind,:);

%Calculate the FA rate and update handle
if ~isempty(NOGOtrials)
    FArate = 100*(sum(NOGOtrials(:,2))/numel(NOGOtrials(:,2)));
    set(handle,'String',num2str(FArate));
end


%INPUT-OUTPUT PLOTTING FUNCTION
function updateIOPlot(ax,SilentDelay,HITind,GOind)

%Compile data into a matrix 
currentdata = [SilentDelay,HITind];

%Select out just the GO trials
GOtrials = currentdata(GOind,:);

%Calculate hit rate for each silent delay period
delay_vals = unique(GOtrials(:,1));
plotting_data = [];

for i = 1: numel(delay_vals)
    delay_data = GOtrials(GOtrials(:,1) == delay_vals(i),:);
    hit_rate = 100*(sum(delay_data(:,2))/numel(delay_data(:,2)));
    plotting_data = [plotting_data;delay_vals(i),hit_rate];
    
end

%Update plot
cla(ax)
xmin = min(delay_vals)-10;
xmax = max(delay_vals)+10;
plot(ax,plotting_data(:,1),plotting_data(:,2),'bs-','linewidth',2,...
    'markerfacecolor','b')
set(ax,'ylim',[0 100],'xlim',[xmin xmax],'xgrid','on','ygrid','on');
xlabel(ax,'Silent Delay (msec)','FontSize',12,...
    'FontName','Arial','FontWeight','Bold')
ylabel(ax,'Hit rate (%)','FontSize',12,...
    'FontName','Arial','FontWeight','Bold')


%TRIAL HISTORY FUNCTION
function updateTrialHistory(handle,SilentDelay,GOind,NOGOind)

%Find GO and NOGO trials
GOtrials = SilentDelay(GOind);
NOGOtrials = SilentDelay(NOGOind);

%Find unique delay values for GO trials
go_delay_vals = unique(GOtrials);

%Find unique delay values for NOGO trials
nogo_delay_vals = unique(NOGOtrials);

D = cell(numel(go_delay_vals)+numel(nogo_delay_vals,3));

for i = 1:numel(go_delay_vals)
    D(i,1) = {'GO'};
    D(i,2) = num2cell(go_delay_vals(i));
    D(i,3) = num2cell(numel(find(GOtrials == go_delay_vals(i))));
end

for i = 1:numel(nogo_delay_vals)
    D(numel(go_delay_vals)+i,1) = {'NOGO'};
    D(numel(go_delay_vals)+i,2) = num2cell(nogo_delay_vals(i));
    D(numel(go_delay_vals)+i,3) = num2cell(numel(find(NOGOtrials == nogo_delay_vals(i))));
end

set(handle,'DATA',D)




%REALTIME PLOTTING FUNCTION
function UpdateAxHistory(ax,TS,HITind,MISSind,FAind,CRind)
cla(ax)

hold(ax,'on')
plot(ax,TS(HITind),ones(sum(HITind,1)),'go','markerfacecolor','g');
plot(ax,TS(MISSind),ones(sum(MISSind,1)),'rs','markerfacecolor','r');
plot(ax,TS(FAind),zeros(sum(FAind,1)),'rs','markerfacecolor','r');
plot(ax,TS(CRind),zeros(sum(CRind,1)),'go','markerfacecolor','g');
hold(ax,'off');

set(ax,'ytick',[0 1],'yticklabel',{'STD','DEV'},'ylim',[-0.1 1.1]);
















%----------------------------------------------------------------------


%TIMER ERROR FUNCTION
function BoxTimerError(~,~)

%TIMER STOP FUNCTION
function BoxTimerStop(~,~)


%REMIND FUNCTION
function Remind_Callback(hObject, eventdata, handles)
% hObject    handle to Remind (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%APPLY FUNCTION
function Apply_Callback(hObject, eventdata, handles)
% hObject    handle to Apply (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%Y AXIS FUNCTIONS
function Yaxis_Callback(hObject, eventdata, handles)
% hObject    handle to Yaxis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Yaxis contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Yaxis


% --- Executes during object creation, after setting all properties.
function Yaxis_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Yaxis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%X AXIS FUNCTIONS
function Xaxis_Callback(hObject, eventdata, handles)
% hObject    handle to Xaxis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Xaxis contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Xaxis


% --- Executes during object creation, after setting all properties.
function Xaxis_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Xaxis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
