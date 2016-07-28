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
handles = initializePhysiology_SanesLab(handles,16);

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
persistent lastupdate starttime waterupdate

%Clear persistent variables if it's a fresh run
if PERSIST == 0
    lastupdate = [];
    starttime = clock;
    waterupdate = 0;
    
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
if (RUNTIME.UseOpenEx && isempty(RUNTIME.TRIALS.DATA(1).Behavior_TrialType)) ...
        | (~RUNTIME.UseOpenEx && isempty(RUNTIME.TRIALS.DATA(1).TrialType)) ...
        | ntrials == lastupdate %#ok<OR2>
    return
end

%Update runtime parameters
[HITind,MISSind,CRind,FAind,GOind,NOGOind,REMINDind,...
    reminders,variables,TrialTypeInd,TrialType,waterupdate,h] = ...
    update_params_runtime_SanesLab(waterupdate,ntrials,h);

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
%%%%%%%%%%%%%%%%%%%%%   TRIAL SELECTION FUNCTIONS   %%%%%%%%%%%%%%%%%%
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
    updateSoundLevelandFreq(handles)
    
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
global GUI_HANDLES AX RUNTIME

%Determine if we're currently in the middle of a trial
if RUNTIME.UseOpenEx
    trial_TTL = AX.GetTargetVal('Behavior.InTrial_TTL');
else
    trial_TTL = AX.GetTagVal('InTrial_TTL');
end

%Determine if we're in a safe trial
if RUNTIME.UseOpenEx
    trial_type = AX.GetTargetVal('Behavior.TrialType');
else
    trial_type = AX.GetTagVal('TrialType');
end



%If we're not in the middle of a trial, or we're in the middle of a safe
%trial
if trial_TTL == 0 || trial_type == 1
    
    %Force a reminder for the next trial
    GUI_HANDLES.remind = 1;
    
    %Update RUNTIME structure and parameters for next trial delivery
    updateRUNTIME
    
    %Update Next trial information in gui
    updateNextTrial(handles.NextTrial);
end

guidata(hObject,handles)


%DELIVER TRIALS BUTTON
function DeliverTrials_Callback(hObject, ~, handles)
global AX RUNTIME

%Determine if we're currently in the middle of a trial
if RUNTIME.UseOpenEx
    trial_TTL = AX.GetTargetVal('Behavior.InTrial_TTL');
else
    trial_TTL = AX.GetTagVal('InTrial_TTL');
end

%Determine if we're in a safe trial
if RUNTIME.UseOpenEx
    trial_type = AX.GetTargetVal('Behavior.TrialType');
else
    trial_type = AX.GetTagVal('TrialType');
end

%If we're not in the middle of a trial, or we're in the middle of a safe
%trial
if trial_TTL == 0 || trial_type == 1
    
    %Start Trial Delivery
    if RUNTIME.UseOpenEx
        AX.SetTargetVal('Behavior.TrialDelivery',1);
    else
        AX.SetTagVal('TrialDelivery',1);
    end
    
    %Enable pause trials button
    set(handles.PauseTrials,'enable','on');
    
    %Disable deliver trials button
    set(handles.DeliverTrials,'enable','off');
    
end

guidata(hObject,handles)


%PAUSE TRIALS BUTTON
function PauseTrials_Callback(hObject, ~, handles)
global AX RUNTIME

%Determine if we're currently in the middle of a trial
if RUNTIME.UseOpenEx
    trial_TTL = AX.GetTargetVal('Behavior.InTrial_TTL');
else
    trial_TTL = AX.GetTagVal('InTrial_TTL');
end

%Determine if we're in a safe trial
if RUNTIME.UseOpenEx
    trial_type = AX.GetTargetVal('Behavior.TrialType');
else
    trial_type = AX.GetTagVal('TrialType');
end


%If we're not in the middle of a trial, or we're in the middle of a safe
%trial
if trial_TTL == 0 || trial_type == 1
    
    %Pause Trial Delivery
    if RUNTIME.UseOpenEx
        AX.SetTargetVal('Behavior.TrialDelivery',0);
    else
        AX.SetTagVal('TrialDelivery',0);
    end
    
    %Disable pause trials button
    set(handles.PauseTrials,'enable','off');
    
    %Enable deliver trials button
    set(handles.DeliverTrials,'enable','on');
    
end

guidata(hObject,handles)

%TRIAL FILTER SELECTION
function TrialFilter_CellSelectionCallback(hObject, eventdata, handles)

if ~isempty(eventdata.Indices)
    
    %Get the row and column of the selected or de-selected checkbox
    r = eventdata.Indices(1);
    c = eventdata.Indices(2);
    
    
    %Identify some important columns
    col_names = get(hObject,'ColumnName');
    trial_type_col = find(ismember(col_names,'TrialType'));
    logical_col = find(ismember(col_names,'Present'));
    
    if c == logical_col
        
        %Determine the data we currently have active
        table_data = get(hObject,'Data');
        active_ind = (strfind(table_data(:,c),'false'));
        active_ind = cellfun('isempty',active_ind);
        active_data = table_data(active_ind,:);
        
        
        %Define the starting state of the check box
        starting_state = table_data{r,c};
        
        %If the box started out as checked, we need to determine whether it's
        %okay to uncheck it
        if strcmpi(starting_state,'true')
            %Prevent the only NOGO from being de-selected
            NOGO_row_active = find(ismember(active_data(:,trial_type_col),'NOGO'));
            if numel(NOGO_row_active) > 1
                NOGO_row = 0;
            else
                NOGO_row = find(ismember(table_data(:,trial_type_col),'NOGO'));
                NOGO_row = num2cell(NOGO_row');
            end
            
            %Prevent the only GO from being deselected
            GO_row_active = find(ismember(active_data(:,trial_type_col),'GO'));
            if numel(GO_row_active) > 1
                GO_row = 0;
            else
                GO_row = find(ismember(table_data(:,trial_type_col),'GO'));
                GO_row = num2cell(GO_row');
            end
            
            
            %If the box started out as unchecked, it's always okay to check it
        else
            NOGO_row = 0;
            GO_row = 0;
        end
        
        
        %If the selected/de-selected row matches one of the special cases,
        %present a warning to the user and don't alter the trial selection
        switch r
            case [NOGO_row, GO_row]
                
                beep
                warnstring = 'The following trial types cannot be deselected: (a) The only GO trial  (b) The only NOGO trial';
                warnhandle = warndlg(warnstring,'Trial selection warning');
                
                
                %If it's okay to select or de-select the checkbox, then proceed
            otherwise
                
                %If the box started as checked, uncheck it
                switch starting_state
                    case 'true'
                        table_data(r,c) = {'false'};
                        
                        %If the box started as unchecked, check it
                    otherwise
                        table_data(r,c) = {'true'};
                end
                
                set(hObject,'Data',table_data);
                set(hObject,'ForegroundColor',[1 0 0]);
                
                %Enable apply button
                set(handles.apply,'enable','on');
        end
        
        guidata(hObject,handles)
        
    end
end

function TrialFilter_CellEditCallback(~, ~, ~)

%DROPDOWN CHANGE SELECTION
function selection_change_callback(hObject, ~, handles)

set(hObject,'ForegroundColor','r');
set(handles.apply,'enable','on');

switch get(hObject,'Tag')
    
    case {'Highpass', 'Lowpass'}
        Highpass_str =  get(handles.Highpass,'String');
        Highpass_val =  get(handles.Highpass,'Value');
        
        Highpass_val = str2num(Highpass_str{Highpass_val}); %Hz
        
        Lowpass_str =  get(handles.Lowpass,'String');
        Lowpass_val =  get(handles.Lowpass,'Value');
        
        Lowpass_val = 1000*str2num(Lowpass_str{Lowpass_val}); %Hz
        
        if Lowpass_val < Highpass_val
            beep
            set(handles.apply,'enable','off');
            errortext = 'Lowpass filter cutoff must be larger than highpass filter cutoff';
            e = errordlg(errortext);
        end
        
end



guidata(hObject,handles)



%----------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%   HARDWARE CONTROL FUNCTIONS   %%%%%%%%%%%%%%%%%
%----------------------------------------------------------------------


%UPDATE SOUND LEVEL AND FREQUENCY
function updateSoundLevelandFreq(h)
global AX RUNTIME

%If the user has GUI control over the sound frequency, set the frequency in
%the RPVds circuit to the desired value. Otherwise, simply read the
%frequency from the circuit directly.
switch get(h.freq,'enable')
    case 'on'
        
        %Get sound frequency from GUI
        soundstr = get(h.freq,'String');
        soundval = get(h.freq,'Value');
        sound_freq = str2num(soundstr{soundval}); %Hz
        
        if RUNTIME.UseOpenEx
            AX.SetTargetVal('Behavior.Freq',sound_freq)
        else
            AX.SetTagVal('Freq',sound_freq);
        end
        
        set(h.freq,'ForegroundColor',[0 0 1]);
        
    otherwise
        
        %If Frequency is a parameter tag in the circuit
        if RUNTIME.UseOpenEx
            if ~isempty(find(ismember(RUNTIME.TDT.devinfo(h.dev).tags,'Freq'),1))
                sound_freq = AX.GetTargetVal('Behavior.Freq');
            end
        else
            if ~isempty(find(ismember(RUNTIME.TDT.devinfo(h.dev).tags,'Freq'),1))
                sound_freq = AX.GetTagVal('Freq');
            end
        end
end


%Set the voltage adjustment for calibration in RPVds circuit
%If Frequency is a parameter tag in the circuit
if ~isempty(find(ismember(RUNTIME.TDT.devinfo(h.dev).tags,'Freq'),1))
    CalAmp = Calibrate(sound_freq,h.C);
else
    CalAmp = h.C.data(1,4);
end

if RUNTIME.UseOpenEx
    AX.SetTargetVal('Behavior.~Freq_Amp',CalAmp);
else
    AX.SetTagVal('~Freq_Amp',CalAmp);
end


%If the user has GUI control over the sound level, set the level in
%the RPVds circuit to the desired value. Otherwise, do nothing.
switch get(h.level,'enable')
    case 'on'
        soundstr = get(h.level,'String');
        soundval = get(h.level,'Value');
        sound_level = str2num(soundstr{soundval}); %dB SPL
        
        %Use Active X controls to set duration directly in RPVds circuit
        if RUNTIME.UseOpenEx
            AX.SetTargetVal('Behavior.dBSPL',sound_level);
        else
            AX.SetTagVal('dBSPL',sound_level);
        end
        
        set(h.level,'ForegroundColor',[0 0 1]);
end


% %UPDATE SHOCKER
% function updateShock(h)
% global AX RUNTIME
% 
% switch get(h.ShockStatus,'enable')
%     case 'on'
%         %Get shock status from GUI
%         str = get(h.ShockStatus,'String');
%         val = get(h.ShockStatus,'Value');
%         shock_status = str{val};
%         
%         %Get shock duration from GUI
%         str = get(h.Shock_dur,'String');
%         val = get(h.Shock_dur,'Value');
%         shock_dur = str2num(str{val})*1000; %msec
%         
%         
%         switch shock_status
%             case 'On'
%                 ShockFlag = 1;
%             case 'Off'
%                 ShockFlag = 0;
%         end
%         
%         %Use Active X controls to set duration directly in RPVds circuit
%         if RUNTIME.UseOpenEx
%             AX.SetTargetVal('Behavior.ShockFlag',ShockFlag);
%             AX.SetTargetVal('Behavior.ShockDur',shock_dur);
%         else
%             AX.SetTagVal('ShockFlag',ShockFlag);
%             AX.SetTagVal('ShockDur',shock_dur);
%         end
%         
%         
%         set(h.ShockStatus,'ForegroundColor',[0 0 1]);
%         set(h.Shock_dur,'ForegroundColor',[0 0 1]);
% end
% 
% 






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
        plotContinuous(timestamps,trial_hist,handles.trialAx,[0.5 0.5 0.5],xmin,xmax,[],type_hist);
        plotContinuous(timestamps,spout_hist,handles.spoutAx,'k',xmin,xmax,'Time (s)')
    case {'Triggered'}
        %plotTriggered(timestamps,trial_hist,poke_hist,h.trialAx,[0.5 0.5 0.5]);
        %plotTriggered(timestamps,spout_hist,poke_hist,h.spoutAx,'k');
end


%PLOT CONTINUOUS REALTIME TTLS
function plotContinuous(timestamps,action_TTL,ax,clr,xmin,xmax,varargin)

%Plot action
ind = logical(action_TTL);
xvals = timestamps(ind);
yvals = ones(size(xvals));


%Find existing plots
current_plots = get(ax,'children');


if nargin == 8
    trial_history = varargin{2};
    trial_history = trial_history(ind);
    
    %Find nogos
    nogo_ind = find(trial_history == 1);
    xnogo = xvals(nogo_ind);
    ynogo = yvals(nogo_ind);
    
    %Find gos
    go_ind = find(trial_history == 0);
    xgo = xvals(go_ind);
    ygo = yvals(go_ind);
    
    
    
    %If the nogo and go plots already exist
    if numel(current_plots) >1
        h_nogo= current_plots(1);
        h_go = current_plots(2);
        
        %Update the nogo data
        if ~isempty(xnogo)
            set(h_nogo,'Xdata',xnogo);
            set(h_nogo,'Ydata',ynogo);
            set(h_nogo,'color',[0.5, 0.5, 0.5]);
        end
        
        %Update the go data
        if ~isempty(xgo)
            set(h_go,'Xdata',xgo);
            set(h_go,'Ydata',ygo);
            set(h_go,'color','g');
        end
        
        %If the nogo and go plots do not already exist
    else
        %Create nogo plot for first time
        if ~isempty(xnogo)
            h_nogo = plot(ax,xnogo,ynogo,'s','color',clr,'linewidth',20);
            hold(ax,'all');
        end
        
        %Create go plot for first time
        if ~isempty(xgo)
            h_go = plot(ax,xgo,ygo,'s','color','g','linewidth',20);
            hold(ax,'all');
        end
    end
    
    
    
else
    
    %If the spout plot already exists
    if ~isempty(current_plots)
        
        h_spout = current_plots(1);
        
        %Update plot
        if ~isempty(xvals)
            set(h_spout,'xdata',xvals);
            set(h_spout,'ydata',yvals);
        end
        
        
    else
        
        %Create spout plot for first time
        if ~isempty(xvals)
            plot(ax,xvals,yvals,'s','color',clr,'linewidth',20)
        end
        
    end
    
    
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

hold(ax,'off');


%PLOT TRIGGERED REALTIME TTLS
function plotTriggered(timestamps,action_TTL,trial_TTL,ax,clr,varargin)
%Find the onset of the most recent trial
d = diff(trial_TTL);
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
        clearvars -global PUMPHANDLE CONSEC_NOGOS
        clearvars -global GUI_HANDLES ROVED_PARAMS USERDATA
        
        %Delete figure
        delete(hObject)
        
    end
    
else
    
    %Close COM port to PUMP
    fclose(PUMPHANDLE);
    delete(PUMPHANDLE);
    
    %Clean up global variables
    clearvars -global PUMPHANDLE CONSEC_NOGOS
    clearvars -global GUI_HANDLES ROVED_PARAMS USERDATA
    
    %Delete figure
    delete(hObject)
    
end





%-----------------------------------------------------------
%%%%%%%%%%%%%%       PHYSIOLOGY FUNCTIONS     %%%%%%%%%%%%%%%
%------------------------------------------------------------
%REFERENCE PHYSIOLOGY
function ReferencePhys_Callback(hObject, eventdata, handles)
global AX
%The method we're using here to reference channels is the following:
%First, bad channels are removed.
%Second a single channel is selected and held aside.
%Third, all of the remaining (good, non-selected) channels are averaged.
%Fourth, this average is subtracted from the selected channel.
%This process is repeated for each good channel.
%
%The way this method is implemented in the RPVds circuit is as follows:
%
%From Brad Buran:
%
% This is implemented using matrix multiplication in the format D x C =
% R. C is a single time-slice of data in the shape [16 x 1]. In other
% words, it is the value from all 16 channels sampled at a single point
% in time. D is a 16 x 16 matrix. R is the referenced output in the
% shape [16 x 1]. Each row in the matrix defines the weights of the
% individual channels. So, if you were averaging together channels 2-16
% and subtracting the mean from the first channel, the first row would
% contain the weights:
%
% [1 -1/15 -1/15 ... -1/15]
%
% If you were averaging together channels 2-8 and subtracting the mean
% from the first channel:
%
% [1 -1/7 -1/7 ... -1/7 0 0 0 ... 0]
%
% If you were averaging together channels 3-8 (because channel 2 was
% bad) and subtracting the mean from the first channel:
%
% [1 0 -1/6 ... -1/6 0 0 0 ... 0]
%
% To average channels 1-4 and subtract the mean from the first channel:
%
% [3/4 -1/4 -1/4 -1/4 0 ... 0]
%
% To repeat the same process (average channels 1-4 and subtract the
% mean) for the second channel, the second row in the matrix would be:
%
% [-1/4 3/4 -1/4 -1/4 0 ... 0]




%Hard coded for a 16 channel array
numchannels = 16;

%Prompt user to identify bad channels
channelList = {'1','2','3','4','5','6','7','8',...
    '9','10','11','12','13','14','15','16'};

header = 'Select bad channels. Hold Cntrl to select multiple channels.';

bad_channels = listdlg('ListString',channelList,'InitialValue',8,...
    'Name','Channels','PromptString',header,...
    'SelectionMode','multiple','ListSize',[300,300])


if ~isempty(bad_channels)
    %Calculate weight for non-identical pairs
    weight = -1/(numchannels - numel(bad_channels) - 1);
    
    %Initialize weight matrix
    WeightMatrix = repmat(weight,numchannels,numchannels);
    
    %The weights of all bad channels are 0.
    WeightMatrix(:,bad_channels) = 0;
    
    %Do not perform averaging on bad channels: leave as is.
    WeightMatrix(bad_channels,:) = 0;
    
    %For each channel
    for i = 1:numchannels
        
        %Its own weight is 1
        WeightMatrix(i,i) = 1;
        
    end
    
    
    
    %Reshape matrix into single row for RPVds compatibility
    WeightMatrix =  reshape(WeightMatrix',[],1);
    WeightMatrix = WeightMatrix';
    
    
    %Send to RPVds
    AX.WriteTargetVEX('Phys.WeightMatrix',0,'F32',WeightMatrix);
    %verify = AX.ReadTargetVEX('Phys.WeightMatrix',0, 256,'F32','F64');
end






