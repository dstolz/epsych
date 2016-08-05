function varargout = Appetitive_detection_GUI_v2(varargin)
% GUI for appetitive detection task
%   
%To do:
%Add trial order control (ascending, descending, shuffled)
%Add bandwidth cutoffs
%
%
%Written by ML Caras Jun 10, 2015
%Updated Apr 26, 2016


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Appetitive_detection_GUI_v2_OpeningFcn, ...
                   'gui_OutputFcn',  @Appetitive_detection_GUI_v2_OutputFcn, ...
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
function Appetitive_detection_GUI_v2_OpeningFcn(hObject, ~, handles, varargin)
global  GUI_HANDLES PERSIST

%Start fresh
GUI_HANDLES = [];
PERSIST = 0;

%Choose default command line output for Appetitive_detection_GUI_v2
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

%Disable expected probability dropdown if it's not a roved parameter 
%or if it's not a parameter tag in the circuit
disabledropdown_SanesLab(handles.ExpectedProb,handles.dev,'Expected')

%Disable level dropdown if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.level,handles.dev,'dBSPL')

%Disable sound duration dropdown if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.sound_dur,handles.dev,'Stim_Duration')

%Disable silent delay dropdown if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.silent_delay,handles.dev,'Silent_delay')

%Disable minimum poke duration dropdown if it's a roved parameter
%or if it's not a parameter tag in the circuit
disabledropdown_SanesLab(handles.MinPokeDur,handles.dev,'MinPokeDur')

%Disable response window delay if it's a roved parameter or if it's not a
%parameter tag in the circuit
disabledropdown_SanesLab(handles.respwin_delay,handles.dev,'RespWinDelay')

%Disable intertrial interval if it's not a parameter tag in the circuit
disabledropdown_SanesLab(handles.ITI,handles.dev,'ITI_dur')

%Load in calibration file
handles = initializeCalibration_SanesLab(handles);

%Apply current settings
apply_Callback(handles.apply,[],handles)

%Update handles structure
guidata(hObject, handles);


%GUI OUTPUT FUNCTION AND INITIALIZING OF TIMER
function varargout = Appetitive_detection_GUI_v2_OutputFcn(hObject, ~, handles) 

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
    'Period',0.05, ...
    'StartFcn',{@BoxTimerSetup,f}, ...
    'TimerFcn',{@BoxTimerRunTime,f}, ...
    'ErrorFcn',{@BoxTimerError}, ...
    'StopFcn', {@BoxTimerStop}, ...
    'TasksToExecute',inf, ...
    'StartDelay',2); 

%TIMER RUNTIME FUNCTION
function BoxTimerRunTime(~,event,f)
global RUNTIME  PERSIST
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
    reminders,variables,TrialTypeInd,TrialType,waterupdate,h,bits,...
    expectInd,YESind,NOind] = ...
    update_params_runtime_SanesLab(waterupdate,ntrials,h,bits);

%Update next trial table in gui
h = updateNextTrial_SanesLab(h);

%Update response history table
h = updateResponseHistory_SanesLab(h,HITind,MISSind,...
    FAind,CRind,GOind,NOGOind,variables,...
    ntrials,TrialTypeInd,TrialType,...
    REMINDind,expectInd,YESind,NOind);

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




%----------------------------------------------------------------------



%----------------------------------------------------------------------
%%%%%%%%%%%%%%%%%   BUTTON AND SELECTION FUNCTIONS   %%%%%%%%%%%%%%%%%%
%----------------------------------------------------------------------

%APPLY CHANGES BUTTON
function apply_Callback(hObject,~,handles)

handles = Apply_Callback_SanesLab(handles);

guidata(hObject,handles)

%REMIND BUTTON
function Remind_Callback(hObject, ~, handles)

handles = Remind_Callback_SanesLab(handles);

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

%REPEAT NOGO IF FA CHECKBOX 
function RepeatNOGO_Callback(hObject, ~, handles)
set(hObject,'ForegroundColor','r');
set(handles.apply,'enable','on');

guidata(hObject,handles);


%-----------------------------------------------------------
%%%%%%%%%%%%%% PLOTTING FUNCTIONS %%%%%%%%%%%%%%%
%------------------------------------------------------------

%PLOT REALTIME HISTORY
function UpdateAxHistory(handles,starttime,event)

%Update the TTL histories
[handles,xmin,xmax,timestamps,trial_hist,spout_hist,~,poke_hist,...
    water_hist,sound_hist,response_hist] = ...
    update_TTLhistory_SanesLab(handles,starttime,event);

%Update realtime displays
str = get(handles.realtime_display,'String');
val = get(handles.realtime_display,'Value');

switch str{val}
    case {'Continuous'}
        
        %Plot the in trial realtime TTL
        plotContinuous_SanesLab(timestamps,trial_hist,handles.trialAx,[0.5 0.5 0.5],xmin,xmax);
        
        %Plot the poke realtime TTL
        plotContinuous_SanesLab(timestamps,poke_hist,handles.pokeAx,'g',xmin,xmax)
        
        %Plot the sound realtime TTL
        plotContinuous_SanesLab(timestamps,sound_hist,handles.soundAx,'r',xmin,xmax)
        
        %Plot the spout realtime TTL
        plotContinuous_SanesLab(timestamps,spout_hist,handles.spoutAx,'k',xmin,xmax)
        
        %Plot the response window realtime TTL
        plotContinuous_SanesLab(timestamps,response_hist,handles.respWinAx,[1 0.5 0],xmin,xmax);
        
        %Plot the water realtime TTL
        plotContinuous_SanesLab(timestamps,water_hist,handles.waterAx,'b',xmin,xmax,'Time (sec)')
        
        
        
    case {'Triggered'}
        
        %Plot the in trial realtime TTL (all triggered off of poke onset)
        plotTriggered_SanesLab(timestamps,trial_hist,poke_hist,handles.trialAx,[0.5 0.5 0.5]);
        
        %Plot the poke realtime TTL
        plotTriggered_SanesLab(timestamps,poke_hist,poke_hist,handles.pokeAx,'g');
        
        %Plot the sound realtime TTL
        plotTriggered_SanesLab(timestamps,sound_hist,poke_hist,handles.soundAx,'r');
        
        %Plot the spout realtime TTL
        plotTriggered_SanesLab(timestamps,spout_hist,poke_hist,handles.spoutAx,'k');
        
        %Plot the response window realtime TTL
        plotTriggered_SanesLab(timestamps,response_hist,poke_hist,handles.respWinAx,[1 0.5 0]);
        
        %Plot the water realtime TTL
        plotTriggered_SanesLab(timestamps,water_hist,poke_hist,handles.waterAx,'b','Time (sec)');
        
end


%PLOT CONTINUOUS REALTIME TTLS
function plotContinuous(timestamps,action_TTL,ax,clr,xmin,xmax,varargin)

%Plot action
ind = logical(action_TTL);
xvals = timestamps(ind);
yvals = ones(size(xvals));


if ~isempty(xvals)
    plot(ax,xvals,yvals,'s','color',clr,'linewidth',20)
end


%Format plot
set(ax,'ylim',[0.9 1.1]);
set(ax,'xlim',[xmin xmax]);
set(ax,'YTickLabel','');
set(ax,'XGrid','on');
set(ax,'XMinorGrid','on');

if nargin == 7
    xlabel(ax,varargin{1},'Fontname','Arial','FontSize',12)
else
    set(ax,'XTickLabel','');
end


%PLOT TRIGGERED REALTIME TTLS
function plotTriggered(timestamps,action_TTL,poke_TTL,ax,clr,varargin)
%Find the onset of the most recent poke
d = diff(poke_TTL);
onset = find(d == 1,1,'last')+1;

%Find end of the most recent action
action_end = find(action_TTL == 1,1,'last');

%Limit time and TTLs to the onset of the most recent trial and the end of
%the most recent action
timestamps = timestamps(onset:action_end);
action_TTL = action_TTL(onset:action_end);

%Plot action
ind = logical(action_TTL);
xvals = timestamps(ind);
yvals = ones(size(xvals));


if ~isempty(xvals)
    plot(ax,xvals,yvals,'s','color',clr,'linewidth',20)
    
    %Format plot
    xmin = timestamps(1) - 2; %start 2 sec before trial onset
    xmax = timestamps(1) + 5; %end 5 sec after trial onset
    set(ax,'xlim',[xmin xmax]);
    set(ax,'ylim',[0.9 1.1]);
    set(ax,'YTickLabel','');
    set(ax,'XGrid','on');
    set(ax,'XMinorGrid','on');
    
    %Enable zooming and panning
    dragzoom(ax);
    
end


if nargin == 6
    xlabel(ax,varargin{1},'Fontname','Arial','FontSize',12)
else
    set(ax,'XTickLabel','');
end



%-----------------------------------------------------------
%%%%%%%%%%%%%%        GUI FUNCTIONS           %%%%%%%%%%%%%%%
%------------------------------------------------------------

%CLOSE GUI WINDOW 
function figure1_CloseRequestFcn(hObject, ~, ~)
global RUNTIME PUMPHANDLE

%Check to see if user has already pressed the stop button
if~isempty(RUNTIME)
    if RUNTIME.UseOpenEx
        h = findobj('Type','figure','-and','Name','ODevFig');
    else
        h = findobj('Type','figure','-and','Name','RPfig');
    end
    
    %If not, prompt user to press STOP
    if ~isempty(h)
        beep
        warnstring = 'You must press STOP before closing this window';
        warnhandle = warndlg(warnstring,'Close warning');
    else
        %Close COM port to PUMP
        fclose(PUMPHANDLE);
        delete(PUMPHANDLE);
        
        %Clean up global variables
        clearvars -global PUMPHANDLE CONSEC_NOGOS CURRENT_EXPEC_STATUS
        clearvars -global CURRENT_FA_STATUS GUI_HANDLES ROVED_PARAMS USERDATA
        
        %Delete figure
        delete(hObject)
        
    end
    
else
    
    %Close COM port to PUMP
    fclose(PUMPHANDLE);
    delete(PUMPHANDLE);
    
    %Clean up global variables
    clearvars -global PUMPHANDLE CONSEC_NOGOS CURRENT_EXPEC_STATUS
    clearvars -global CURRENT_FA_STATUS GUI_HANDLES ROVED_PARAMS USERDATA
    
    %Delete figure
    delete(hObject)
    
end




