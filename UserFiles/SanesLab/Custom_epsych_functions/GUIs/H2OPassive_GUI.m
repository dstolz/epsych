function varargout = H2OPassive_GUI(varargin)
% GUI for passive trial presentation, while animal drinks from spout.
%
%To do:
%
% KP Nov 6 2016, based on Aversive_detection_GUI by ML Caras


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @H2OPassive_GUI_OpeningFcn, ...
    'gui_OutputFcn',  @H2OPassive_GUI_OutputFcn, ...
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


%SET UP INITIAL GUI TEXT BEFORE GUI IS MADE VISIBLE
function H2OPassive_GUI_OpeningFcn(hObject, ~, handles, varargin)
global GUI_HANDLES PERSIST AX

%Start fresh
GUI_HANDLES = [];
PERSIST = 0;

%Choose default command line output for H2OPassive_GUI
handles.output = hObject;

%Find the index of the RZ6 device (running behavior)
handles = findModuleIndex_SanesLab('RZ6', handles);

%Initialize physiology settings for 16 channel recording (if OpenEx)
[handles,AX] = initializePhysiology_SanesLab(handles,AX);

%Setup Trial History Table
handles = setupTrialHistoryPassive_SanesLab(handles);

%Setup Next Trial Table
handles = setupNextTrial_SanesLab(handles);

%Set up list of possible trial types (ignores reminder)
handles = populateLoadedTrials_SanesLab(handles);

%Setup X-axis options for I/O plot
% handles = setupIOplot_SanesLab(handles);

%Collect GUI parameters for selecting next trial, and for pump settings
collectGUIHANDLES_SanesLab(handles);

%Start with paused trial delivery
handles = initializeTrialDelivery_SanesLab(handles);

%Disable frequency dropdown if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.freq,handles.dev,handles.module,'Freq')

%Disable FMRate dropdown if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.FMRate,handles.dev,handles.module,'FMrate')

%Disable FMDepth dropdown if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.FMDepth,handles.dev,handles.module,'FMdepth')

%Disable AMRate dropdown if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.AMRate,handles.dev,handles.module,'AMrate')

%Disable AMDepth dropdown if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.AMDepth,handles.dev,handles.module,'AMdepth')

%Disable Highpass dropdown if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.Highpass,handles.dev,handles.module,'Highpass')

%Disable Lowpass dropdown if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.Lowpass,handles.dev,handles.module,'Lowpass')

%Disable level dropdown if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.level,handles.dev,handles.module,'dBSPL')

%Disable sound duration dropdown if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.sound_dur,handles.dev,handles.module,'Stim_Duration')

%Disable response window duration dropdown if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.respwin_dur,handles.dev,handles.module,'RespWinDur')

%Disable intertrial interval if it's not a parameter tag in the circuit
disabledropdown_SanesLab(handles.ITI,handles.dev,handles.module,'ITI_dur')

%Disable shock status if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.ShockStatus,handles.dev,handles.module,'ShockFlag')

%Disable shock duration if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.Shock_dur,handles.dev,handles.module,'ShockDur')

%Disable optogtenetic trigger if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.optotrigger,handles.dev,handles.module,'Optostim')

%Link axes
linkaxes([handles.trialAx,handles.spoutAx],'x');

%Load in calibration file
handles = initializeCalibration_SanesLab(handles);

%Apply current settings
apply_Callback(handles.apply,[],handles)

%Update handles structure
guidata(hObject, handles);


%GUI OUTPUT FUNCTION AND INITIALIZING OF TIMER
function varargout = H2OPassive_GUI_OutputFcn(hObject, ~, handles)

% Get default command line output from handles structure
varargout{1} = handles.output;



% Create new timer for RPvds control of experiment
T = CreateTimer(hObject);

%Start timer
start(T);



%----------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%    TIMER FUNCTIONS   %%%%%%%%%%%%%%%%%%%%%%%%
%----------------------------------------------------------------------
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
    'Period',0.025, ...
    'StartFcn',{@BoxTimerSetup,f}, ...
    'TimerFcn',{@BoxTimerRunTime,f}, ...
    'ErrorFcn',{@BoxTimerError}, ...
    'StopFcn', {@BoxTimerStop}, ...
    'TasksToExecute',inf, ...
    'StartDelay',2);

%TIMER RUNTIME FUNCTION
function BoxTimerRunTime(~,event,f)
global RUNTIME PERSIST AX

persistent lastupdate starttime waterupdate bits

%--------------------------------------------------------
%Abort if active X controls have been closed
%--------------------------------------------------------
%--------------------------------------------------------
if ~(isa(AX,'COM.RPco_x')||isa(AX,'COM.TDevAcc_X'))
    return
end

%Clear persistent variables if it's a fresh run
if PERSIST == 0
    lastupdate = [];
    starttime = clock;
    waterupdate = 0;
    bits = [];
    
    PERSIST = 1;
end

%Retrieve GUI handles structure
h = guidata(f);


try
    %Update Realtime Plot
    UpdateAxHistory(h,starttime,event)
    
    %Capture sound level from microphone
    h = capturesound_SanesLab(h);
    
    %Which trial are we on?
    ntrials = length(RUNTIME.TRIALS.DATA);
    
    %--------------------------------------------------------
    %Only continue updates if a new trial has been completed
    %--------------------------------------------------------
    %--------------------------------------------------------
    if (isempty(RUNTIME.TRIALS.DATA(1).TrialType))| ntrials == lastupdate %#ok<OR2>
        return
    end
    
    %Update runtime parameters
    [~,~,~,~,GOind,NOGOind,REMINDind,...
        reminders,variables,TrialTypeInd,TrialType,waterupdate,h,bits] = ...
        update_params_runtime_SanesLab(waterupdate,ntrials,h,bits);

    %Update next trial table in gui
    h = updateNextTrial_SanesLab(h);
    
    %Update trial history table
    h =  updateTrialHistoryPassive_SanesLab(h,variables);

    lastupdate = ntrials;
    
catch me
    keyboard
    vprintf(0,me) %Log error
end



%TIMER ERROR FUNCTION
function BoxTimerError(~,~)



%TIMER STOP FUNCTION
function BoxTimerStop(~,~)

%TIMER START FUNCTION
function BoxTimerSetup(~,~,~)
%---------------------------------------------------------------------


%----------------------------------------------------------------------
%%%%%%%%%%%%%%%%%   BUTTON AND SELECTION FUNCTIONS   %%%%%%%%%%%%%%%%%%
%----------------------------------------------------------------------

%APPLY CHANGES BUTTON
function apply_Callback(hObject,~,handles)

handles = Apply_Callback_SanesLab(handles);

guidata(hObject,handles)

%REMIND BUTTON
function Remind_Callback(hObject, ~, handles) %#ok<*DEFNU>

handles = Remind_Callback_SanesLab(handles);

guidata(hObject,handles)

%DELIVER TRIALS BUTTON
function DeliverTrials_Callback(hObject, ~, handles)

handles = TrialDelivery_Callback_SanesLab(handles,'on');

guidata(hObject,handles)

%PAUSE TRIALS BUTTON
function PauseTrials_Callback(hObject, ~, handles)

handles = TrialDelivery_Callback_SanesLab(handles,'off');

guidata(hObject,handles)

%REFERENCE PHYSIOLOGY BUTTON
function ReferencePhys_Callback(~, ~, handles)
global AX

AX = ReferencePhys_SanesLab(handles,AX);

%TRIAL FILTER SELECTION
function TrialFilter_CellSelectionCallback(hObject, eventdata, handles)

[hObject,handles] = filterTrials_SanesLab(hObject, eventdata, handles);

guidata(hObject,handles)

function TrialFilter_CellEditCallback(~, ~, ~)

%DROPDOWN CHANGE SELECTION
function selection_change_callback(hObject, ~, handles)

[hObject,handles] = select_change_SanesLab(hObject,handles);

guidata(hObject,handles)

%CLOSE GUI WINDOW
function figure1_CloseRequestFcn(hObject, ~, ~)

closeGUI_SanesLab(hObject)

%LOAD GUI SETTINGS
function loadSettings_ClickedCallback(hObject, ~, handles)

handles = loadGUISettings_SanesLab(handles);
apply_Callback(handles.apply,[],handles)

guidata(hObject,handles);


%SAVE GUI SETTINGS
function saveSettings_ClickedCallback(hObject, ~, handles)

handles = saveGUISettings_SanesLab(handles);

guidata(hObject,handles);
%---------------------------------------------------------------------


%-----------------------------------------------------------
%%%%%%%%%%%%%% PLOTTING FUNCTIONS %%%%%%%%%%%%%%%
%------------------------------------------------------------

%PLOT REALTIME HISTORY
function UpdateAxHistory(handles,starttime,event)

%Update the TTL histories
[handles,xmin,xmax,timestamps,trial_hist,spout_hist,type_hist] = ...
    update_TTLhistory_SanesLab(handles,starttime,event);

%Update realtime displays
str = get(handles.realtime_display,'String');
val = get(handles.realtime_display,'Value');

switch str{val}
    
    case {'Continuous'}
        
        %Plot the InTrial realtime TTL
        plotContinuous_SanesLab(timestamps,trial_hist,handles.trialAx,...
            [0.5 0.5 0.5],xmin,xmax,'',type_hist);
        
        %Plot the Spout realtime TTL
        plotContinuous_SanesLab(timestamps,spout_hist,handles.spoutAx,...
            'k',xmin,xmax,'Time (s)')
    
        
    case {'Triggered'}
        
        %Plot the InTrial realtime TTL (triggered off of trial onset)
        plotTriggered_SanesLab(timestamps,trial_hist,trial_hist,...
            handles.trialAx,[0.5 0.5 0.5],'',type_hist);
       
        %Plot the Spout realtime TTL (triggered off of trial onset)
        plotTriggered_SanesLab(timestamps,spout_hist,trial_hist,...
            handles.spoutAx,'k','Time (s)');
end

%-----------------------------------------------------------


