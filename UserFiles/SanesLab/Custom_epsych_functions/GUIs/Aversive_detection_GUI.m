function varargout = Aversive_detection_GUI(varargin)
% GUI for aversive detection task
%
%To do:
%Fix AM depth percent plotting
%Change GO trial color on plot
%Add grouping variable plotting cabailities for optogenetics
%Add pause mode (make default) so animal can warm up and get reminders
%Remove Inf option for NOGO limit
%Add TTL plot like in Brad's program to monitor spout contact
%
% Written by ML Caras Apr 21, 2016


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @Aversive_detection_GUI_OpeningFcn, ...
    'gui_OutputFcn',  @Aversive_detection_GUI_OutputFcn, ...
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
function Aversive_detection_GUI_OpeningFcn(hObject, ~, handles, varargin)
global GUI_HANDLES PERSIST

%Start fresh
GUI_HANDLES = [];
PERSIST = 0;

%Choose default command line output for Aversive_detection_GUI
handles.output = hObject;

%Find the index of the RZ6 device (running behavior)
handles = findModuleIndex_SanesLab('RZ6', handles);

%Initialize physiology settings for 16 channel recording (if OpenEx)
handles = initializePhysiology_SanesLab(handles);

%Setup Response History Table and Trial History Table
handles = setupResponseandTrialHistory_SanesLab(handles);

%Setup Next Trial Table
handles = setupNextTrial_SanesLab(handles);

%Set up list of possible trial types (ignores reminder)
handles = populateLoadedTrials_SanesLab(handles);

%Setup X-axis options for I/O plot
handles = setupIOplot_SanesLab(handles);

%Collect GUI parameters for selecting next trial, and for pump settings
collectGUIHANDLES_SanesLab(handles);

%Start with paused trial delivery
handles = initializeTrialDelivery_SanesLab(handles);

%Disable frequency dropdown if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.freq,handles.dev,'Freq')

%Disable FMRate dropdown if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.FMRate,handles.dev,'FMrate')

%Disable FMDepth dropdown if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.FMDepth,handles.dev,'FMdepth')

%Disable AMRate dropdown if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.AMRate,handles.dev,'AMrate')

%Disable AMDepth dropdown if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.AMDepth,handles.dev,'AMdepth')

%Disable Highpass dropdown if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.Highpass,handles.dev,'Highpass')

%Disable Lowpass dropdown if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.Lowpass,handles.dev,'Lowpass')

%Disable level dropdown if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.level,handles.dev,'dBSPL')

%Disable sound duration dropdown if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.sound_dur,handles.dev,'Stim_Duration')

%Disable response window duration dropdown if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.respwin_dur,handles.dev,'RespWinDur')

%Disable intertrial interval if it's not a parameter tag in the circuit
disabledropdown_SanesLab(handles.ITI,handles.dev,'ITI_dur')

%Disable shock status if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.ShockStatus,handles.dev,'ShockFlag')

%Disable shock duration if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.Shock_dur,handles.dev,'ShockDur')

%Disable optogtenetic trigger if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.optotrigger,handles.dev,'Optostim')

%Load in calibration file
handles = initializeCalibration_SanesLab(handles);

%Apply current settings
apply_Callback(handles.apply,[],handles)

%Update handles structure
guidata(hObject, handles);


%GUI OUTPUT FUNCTION AND INITIALIZING OF TIMER
function varargout = Aversive_detection_GUI_OutputFcn(hObject, ~, handles)

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
global RUNTIME
global PERSIST
persistent lastupdate starttime waterupdate bits

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
[HITind,MISSind,CRind,FAind,GOind,NOGOind,REMINDind,...
    reminders,variables,TrialTypeInd,TrialType,waterupdate,h,bits] = ...
    update_params_runtime_SanesLab(waterupdate,ntrials,h,bits);

%Update next trial table in gui
h = updateNextTrial_SanesLab(h);

%Update response history table
h = updateResponseHistory_SanesLab(h,HITind,MISSind,...
    FAind,CRind,GOind,NOGOind,variables,...
    ntrials,TrialTypeInd,TrialType,...
    REMINDind);

%Update FA rate
h = updateFArate_SanesLab(h,variables,FAind,NOGOind,f);

%Calculate hit rates and update plot
h = updateIOPlot_SanesLab(h,variables,HITind,GOind,REMINDind);

%Update trial history table
h =  updateTrialHistory_SanesLab(h,variables,reminders,HITind,FAind,GOind);

lastupdate = ntrials;

%TIMER ERROR FUNCTION
function BoxTimerError(~,~)

%TIMER STOP FUNCTION
function BoxTimerStop(~,~)

%TIMER START FUNCTION
function BoxTimerSetup(~,~,~)

%---------------------------------------------------------------------
%---------------------------------------------------------------------



%----------------------------------------------------------------------
%%%%%%%%%%%%%%%%%   BUTTON AND SELECTION FUNCTIONS   %%%%%%%%%%%%%%%%%%
%----------------------------------------------------------------------

%APPLY CHANGES BUTTON
function apply_Callback(hObject,~,handles)
global  AX

%Determine if we're currently in the middle of a trial
trial_TTL = TDTpartag(AX,[handles.module,'.InTrial_TTL']);

%Determine if we're in a safe trial
trial_type = TDTpartag(AX,[handles.module,'.TrialType']);

%If we're not in the middle of a trial, or we're in the middle of a NOGO
%trial
if trial_TTL == 0 || trial_type == 1
    
    %Collect GUI parameters for selecting next trial
    collectGUIHANDLES_SanesLab(handles);
    
    %Update RUNTIME structure and parameters for next trial delivery
    updateRUNTIME_SanesLab
    
    %Update Next trial information in gui
    handles = updateNextTrial_SanesLab(handles);
    
    %Re-collect GUIHANDLES
    collectGUIHANDLES_SanesLab(handles);
    
    %Update pump control
    updatepump_SanesLab(handles)

    %Update Response Window Duration
    updatetag_SanesLab(handles.respwin_dur,handles.module,'RespWinDur')
   
    %Update sound duration
    updatetag_SanesLab(handles.sound_dur,handles.module,'Stim_Duration')
 
    %Update sound frequency and level
    handles = updateSoundLevelandFreq_SanesLab(handles);
    
    %Update FM rate
    updatetag_SanesLab(handles.FMRate,handles.module,'FMrate')
    
    %Update FM depth
    updatetag_SanesLab(handles.FMDepth,handles.module,'FMdepth')
    
    %Update AM rate: Important must be called BEFORE update AM depth
    updatetag_SanesLab(handles.AMRate,handles.module,'AMrate')
    
    %Update AM depth
    updatetag_SanesLab(handles.AMDepth,handles.module,'AMdepth')
    
    %Update Highpass cutoff
    updatetag_SanesLab(handles.Highpass,handles.module,'Highpass')
   
    %Update Lowpass cutoff
    updatetag_SanesLab(handles.Lowpass,handles.module,'Lowpass')
    
    %Update intertrial interval
    updatetag_SanesLab(handles.ITI,handles.module,'ITI_dur')

    %Update Optogenetic Trigger
    updatetag_SanesLab(handles.optotrigger,handles.module,'Optostim')
    
    %Update Shocker Status
    updatetag_SanesLab(handles.ShockStatus,handles.module,'ShockFlag')
    updatetag_SanesLab(handles.Shock_dur,handles.module,'ShockDur')
    
    %Reset foreground colors of remaining drop down menus to blue
    set(handles.nogo_max,'ForegroundColor',[0 0 1]);
    set(handles.nogo_min,'ForegroundColor',[0 0 1]);
    set(handles.TrialFilter,'ForegroundColor',[0 0 1]);
    
    %Disable apply button
    set(handles.apply,'enable','off')
    
end


guidata(hObject,handles)

%REMIND BUTTON
function Remind_Callback(hObject, ~, handles)

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

ReferencePhys_SanesLab(handles)

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


