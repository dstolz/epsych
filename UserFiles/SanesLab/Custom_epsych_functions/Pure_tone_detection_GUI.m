function varargout = Pure_tone_detection_GUI(varargin)
% GUI for pure tone detection task
%     
% Written by ML Caras Jun 10, 2015
% THIS IS ON THE REAL TIME PLOTTING BRANCH

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


%SET UP INITIAL GUI TEXT BEFORE GUI IS MADE VISIBLE
function Pure_tone_detection_GUI_OpeningFcn(hObject, ~, handles, varargin)
global ROVED_PARAMS GUI_HANDLES CONFIG

%Choose default command line output for Pure_tone_detection_GUI
handles.output = hObject;

%Setup Response History Table
cols = cell(1,numel(ROVED_PARAMS)+1);
cols(1:numel(ROVED_PARAMS)) = ROVED_PARAMS;
cols(end) = {'Response'};
datacell = cell(size(cols));
set(handles.DataTable,'Data',datacell,'RowName','0','ColumnName',cols);

%Setup Next Trial Table
empty_cell = cell(1,numel(ROVED_PARAMS));
set(handles.NextTrial,'Data',empty_cell,'ColumnName',ROVED_PARAMS);

%Setup Trial History Table
trial_history_cols = cols;
trial_history_cols(end) = {'# Trials'};
set(handles.TrialHistory,'Data',datacell,'ColumnName',trial_history_cols);

%Set up list of possible trial types (ignores reminder)
populateLoadedTrials(handles.TrialFilter,handles.ReminderParameters);

%Setup X-axis options for I/O plot
ind = ~strcmpi(ROVED_PARAMS,'TrialType');
xaxis_opts = ROVED_PARAMS(ind);
set(handles.Xaxis,'String',xaxis_opts)

%Establish predetermined yaxis options
yaxis_opts = {'Hit Rate', 'd'''};
set(handles.Yaxis,'String',yaxis_opts);

%Link x axes for realtime plotting
realtimeAx = [handles.trialAx,handles.pokeAx,handles.soundAx,...
    handles.spoutAx,handles.waterAx,handles.respWinAx];
linkaxes(realtimeAx,'x');

%Collect GUI parameters for selecting next trial
GUI_HANDLES.remind = 0;
GUI_HANDLES.go_prob = get(handles.GoProb);
GUI_HANDLES.Nogo_lim = get(handles.NOGOlimit);
GUI_HANDLES.trial_filter = get(handles.TrialFilter);
GUI_HANDLES.expected_prob = get(handles.ExpectedProb);
GUI_HANDLES.RepeatNOGO = get(handles.RepeatNOGO);
GUI_HANDLES.num_reminds = get(handles.num_reminds);

%Disable apply button
set(handles.apply,'enable','off');

%Disable frequency dropdown if it's a roved parameter
if cell2mat(strfind(ROVED_PARAMS,'Freq'))
    set(handles.freq,'enable','off');
end

%Disable level dropdown if it's a roved parameter
if cell2mat(strfind(ROVED_PARAMS,'dBSPL'))
    set(handles.level,'enable','off');
end

%Disable sound duration dropdown if it's a roved parameter
if cell2mat(strfind(ROVED_PARAMS,'Stim_duration'))
    set(handles.sound_dur,'enable','off');
end

%Disable silent delay dropdown if it's a roved parameter
if cell2mat(strfind(ROVED_PARAMS,'Silent_delay'))
    set(handles.silent_delay,'enable','off');
end

%Disable response window delay if it's a roved parameter
if cell2mat(strfind(ROVED_PARAMS,'RespWinDelay'))
    set(handles.respwin_delay,'enable','off');
end

%Load in calibration file
try
    calfile = CONFIG.PROTOCOL.MODULES.Stim.calibrations{2}.filename;
    fidx = 1;
catch
    [fn,pn,fidx] = uigetfile('C:\gits\epsych\UserFiles\SanesLab\SpeakerCalibrations\*.cal','Select speaker calibration file');
    calfile = fullfile(pn,fn);
end

if ~fidx
    error('Error: No calibration file was found')
else
    disp(['Calibration file is: ' calfile])
    handles.C = load(calfile,'-mat');
    updateSoundLevelandFreq(handles)
end


% Update handles structure
guidata(hObject, handles);


%GUI OUTPUT FUNCTION AND INITIALIZING OF TIMER
function varargout = Pure_tone_detection_GUI_OutputFcn(hObject, ~, handles) 

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
T = timerfind('Name','GUITimer');
if ~isempty(T)
    stop(T);
    delete(T);
end

%All values in seconds
T = timer('BusyMode','drop', ...
    'ExecutionMode','fixedSpacing', ...
    'Name','BoxTimer', ...
    'Period',0.010, ...
    'StartFcn',{@BoxTimerSetup,f}, ...
    'TimerFcn',{@BoxTimerRunTime,f}, ...
    'ErrorFcn',{@BoxTimerError}, ...
    'StopFcn', {@BoxTimerStop}, ...
    'TasksToExecute',inf, ...
    'StartDelay',2); 

%TIMER RUNTIME FUNCTION
function BoxTimerRunTime(~,event,f)
global RUNTIME ROVED_PARAMS CONSEC_NOGOS CURRENT_FA_STATUS
persistent lastupdate starttime

%Start the clock
if isempty(starttime) 
    starttime = clock; 
end

h = guidata(f);

%Update Realtime Plot
UpdateAxHistory(h,starttime,event)

%DATA structure
DATA = RUNTIME.TRIALS.DATA; 
ntrials = length(DATA);

%Check if a new trial has been completed
if (RUNTIME.UseOpenEx && isempty(DATA(1).Behavior_TrialType)) ...
        | (~RUNTIME.UseOpenEx && isempty(DATA(1).TrialType)) ...
        | ntrials == lastupdate
    return
end

%Update roved parameter variables
for i = 1:numel(ROVED_PARAMS)
   
    if RUNTIME.UseOpenEx
            eval(['variables(:,i) = [DATA.Behavior_' ROVED_PARAMS{i} ']'';'])
    else
            eval(['variables(:,i) = [DATA.' ROVED_PARAMS{i} ']'';'])
    end
    
end

%Update reminder status
try
    if RUNTIME.UseOpenEx
        reminders = [DATA.Behavior_Reminder]';
    else
        reminders = [DATA.Reminder]';
    end
catch me
    errordlg('Error: No reminder trial specified. Edit protocol.')
    rethrow(me)
end


%Update response codes
bitmask = [DATA.ResponseCode]';
HITind  = logical(bitget(bitmask,1));
MISSind = logical(bitget(bitmask,2));
FAind   = logical(bitget(bitmask,4));
CRind   = logical(bitget(bitmask,3));

TrialTypeInd = find(strcmpi('TrialType',ROVED_PARAMS));
TrialType = variables(:,TrialTypeInd);

expectInd = find(strcmpi('Expected',ROVED_PARAMS));
expected = variables(:,expectInd);

GOind = find(TrialType == 0);
NOGOind = find(TrialType == 1);
REMINDind = find(reminders == 1);
YESind = find(expected == 1);
NOind = find(expected == 0);

%Update next trial table in gui
updateNextTrial(h.NextTrial);

%Update response history table
updateResponseHistory(h.DataTable,HITind,MISSind,...
     FAind,CRind,GOind,NOGOind,variables,...
     ntrials,TrialTypeInd,TrialType,...
     REMINDind,YESind,NOind,expectInd)
 
%Update FA rate
FArate = updateFArate(h.FArate,variables,FAind,NOGOind); 
 
%Calculate hit rates and update plot
updateIOPlot(h,variables,HITind,GOind,FArate,REMINDind);

%Update trial history table
updateTrialHistory(h.TrialHistory,variables,reminders)

%Update number of consecutive nogos
trial_list = [DATA(:).TrialType]';

switch trial_list(end)
    case 1
        CONSEC_NOGOS = CONSEC_NOGOS +1;
    case 0
        CONSEC_NOGOS = 0;
end

%Determine if the last response was a FA
response_list = bitget([DATA(:).ResponseCode]',4);

switch response_list(end)
    case 1
        CURRENT_FA_STATUS = 1; 
    case 0
        CURRENT_FA_STATUS = 0;
end


%Update RUNTIME via trial selection function
updateRUNTIME

%Update Next trial information in gui
updateNextTrial(h.NextTrial);

lastupdate = ntrials;

%TIMER ERROR FUNCTION
function BoxTimerError(~,~)

%TIMER STOP FUNCTION
function BoxTimerStop(~,~)

%TIMER START FUNCTION
function BoxTimerSetup(~,~,~)




%----------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%   TRIAL SELECTION FUNCTIONS   %%%%%%%%%%%%%%%%%%
%----------------------------------------------------------------------

%APPLY CHANGES BUTTON
function apply_Callback(hObject,~,handles)
global GUI_HANDLES AX


%Determine if we're currently in the middle of a trial
trial_TTL = AX.GetTagVal('InTrial_TTL');

%If we're not in the middle of a trial
if trial_TTL == 0
    
    
    %Collect GUI parameters for selecting next trial
    GUI_HANDLES.go_prob = get(handles.GoProb);
    GUI_HANDLES.Nogo_lim = get(handles.NOGOlimit);
    GUI_HANDLES.trial_filter = get(handles.TrialFilter);
    GUI_HANDLES.expected_prob = get(handles.ExpectedProb);
    GUI_HANDLES.RepeatNOGO = get(handles.RepeatNOGO);
    GUI_HANDLES.num_reminds = get(handles.num_reminds);
    
    %Update RUNTIME structure and parameters for next trial delivery
    updateRUNTIME
    
    %Update Next trial information in gui
    updateNextTrial(handles.NextTrial);
    
    %Update time out duration
    updateTimeOut(handles)
    set(handles.TOduration,'ForegroundColor',[0 0 1]);
    
    %Update minimumpoke duration
    updateMinPoke(handles)
    set(handles.MinPokeDur,'ForegroundColor',[0 0 1]);
    
    %Update pump control
    pumpcontrol(handles)
    set(handles.reward_vol,'ForegroundColor',[0 0 1]);
    set(handles.Pumprate,'ForegroundColor',[0 0 1]);
    
    %Update Response Window Duration
    updateResponseWinDur(handles)
    set(handles.respwin_dur,'ForegroundColor',[0 0 1]);
    
    %Update sound duration
    switch get(handles.sound_dur,'enable')
        case 'on'
            updateSoundDur(handles)
            set(handles.sound_dur,'ForegroundColor',[0 0 1]);
    end
    
    %Update sound frequency and level
    updateSoundLevelandFreq(handles)
   
            
    
    %Update Response Window Delay
    switch get(handles.respwin_delay,'enable')
        case 'on'
            updateResponseWinDelay(handles)
            set(handles.respwin_delay,'ForegroundColor',[0 0 1]);
    end
    
    %Update Silent Delay
    switch get(handles.silent_delay,'enable')
        case 'on'
            updateSilentDelay(handles)
            set(handles.silent_delay,'ForegroundColor',[0 0 1]);
    end
    
    %Reset foreground colors of remaining drop down menus to blue
    set(handles.num_reminds,'ForegroundColor',[0 0 1]);
    set(handles.GoProb,'ForegroundColor',[0 0 1]);
    set(handles.ExpectedProb,'ForegroundColor',[0 0 1]);
    set(handles.NOGOlimit,'ForegroundColor',[0 0 1]);
    set(handles.RepeatNOGO,'ForegroundColor',[0 0 1]);
    set(handles.TrialFilter,'ForegroundColor',[0 0 1]);
    
    %Disable apply button
    set(handles.apply,'enable','off')
    
end

guidata(hObject,handles)

%REMIND BUTTON
function Remind_Callback(hObject, ~, handles)
global GUI_HANDLES AX

%Determine if we're currently in the middle of a trial
trial_TTL = AX.GetTagVal('InTrial_TTL');

%If we're not in the middle of a trial
if trial_TTL == 0
    
    %Force a reminder for the next trial
    GUI_HANDLES.remind = 1;
    
    %Update RUNTIME structure and parameters for next trial delivery
    updateRUNTIME
    
    %Update Next trial information in gui
    updateNextTrial(handles.NextTrial);
end

guidata(hObject,handles)

%TRIAL FILTER SELECTION 
function TrialFilter_CellSelectionCallback(hObject, eventdata, handles)

if ~isempty(eventdata.Indices)
    r = eventdata.Indices(1);
    c = eventdata.Indices(2);
    
    table_data = get(hObject,'Data');
    
    if strcmpi(table_data{r,c},'true')
        table_data(r,c) = {'false'};
    else
        table_data(r,c) = {'true'};
    end
    
    set(hObject,'Data',table_data);
    set(hObject,'ForegroundColor',[1 0 0]);
    
    %Enable apply button
    set(handles.apply,'enable','on');


    guidata(hObject,handles)
end
function TrialFilter_CellEditCallback(~, ~, ~)

%DROPDOWN CHANGE SELECTION
function selection_change_callback(hObject, ~, handles)

set(hObject,'ForegroundColor','r');
set(handles.apply,'enable','on');

guidata(hObject,handles)

%REPEAT NOGO IF FA CHECKBOX 
function RepeatNOGO_Callback(hObject, ~, handles)
set(hObject,'ForegroundColor','r');
set(handles.apply,'enable','on');

guidata(hObject,handles);

%UPDATE RUNTIME STRUCTURE
function updateRUNTIME
global RUNTIME AX


% Reduce TRIALS.TrialCount for the currently selected trial index
RUNTIME.TRIALS.TrialCount(RUNTIME.TRIALS.NextTrialID) = ...
    RUNTIME.TRIALS.TrialCount(RUNTIME.TRIALS.NextTrialID) - 1;

%Re-select the next trial using trial selection function
RUNTIME.TRIALS.NextTrialID = TrialFcn_PureToneDetection_MasterHelper(RUNTIME.TRIALS);

% Increment TRIALS.TrialCount for the selected trial index
RUNTIME.TRIALS.TrialCount(RUNTIME.TRIALS.NextTrialID) = ...
    RUNTIME.TRIALS.TrialCount(RUNTIME.TRIALS.NextTrialID) + 1;

% Send trigger to reset components before updating parameters
if RUNTIME.UseOpenEx
    TrigDATrial(AX,RUNTIME.ResetTrigStr{1});
else
    TrigRPTrial(AX(RUNTIME.ResetTrigIdx),RUNTIME.ResetTrigStr{1});
end

% Update parameters for next trial
feval(sprintf('Update%stags',RUNTIME.TYPE),AX,RUNTIME.TRIALS);

% Send trigger to indicate ready for a new trial
if RUNTIME.UseOpenEx
    TrigDATrial(AX,RUNTIME.NewTrialStr{1});
else
    TrigRPTrial(AX(RUNTIME.NewTrialIdx),RUNTIME.NewTrialStr{1});
end




%----------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%   HARDWARE CONTROL FUNCTIONS   %%%%%%%%%%%%%%%%%
%----------------------------------------------------------------------

%UPDATE SOUND DURATION
function updateSoundDur(h)
global AX

%Get sound duration from GUI
soundstr = get(h.sound_dur,'String');
soundval = get(h.sound_dur,'Value');
sound_dur = str2num(soundstr{soundval})*1000; %msec

%Use Active X controls to set duration directly in RPVds circuit
AX.SetTagVal('Stim_Duration',sound_dur);

%UPDATE SOUND LEVEL AND FREQUENCY
function updateSoundLevelandFreq(h)
global AX

%If the user has GUI control over the sound frequency, set the frequency in
%the RPVds circuit to the desired value. Otherwise, simply read the
%frequency from the circuit directly.
switch get(h.freq,'enable')
    case 'on'
        %Get sound frequency from GUI
        soundstr = get(h.freq,'String');
        soundval = get(h.freq,'Value');
        sound_freq = str2num(soundstr{soundval}); %Hz
        AX.SetTagVal('Freq',sound_freq);
        set(h.freq,'ForegroundColor',[0 0 1]);
    otherwise
        sound_freq = AX.GetTagVal('Freq');
end


%Set the voltage adjustment for calibration in RPVds circuit
CalAmp = Calibrate(sound_freq,h.C);
AX.SetTagVal('~Freq_Amp',CalAmp);


%If the user has GUI control over the sound level, set the level in
%the RPVds circuit to the desired value. Otherwise, do nothing.
switch get(h.level,'enable')
    case 'on'
        soundstr = get(h.level,'String');
        soundval = get(h.level,'Value');
        sound_level = str2num(soundstr{soundval}); %dB SPL
        
        %Use Active X controls to set duration directly in RPVds circuit
        AX.SetTagVal('dBSPL',sound_level);
        
        set(h.level,'ForegroundColor',[0 0 1]);
end

%UPDATE RESPONSE WINDOW DURATION
function updateResponseWinDur(h)
global AX

%Get time out duration from GUI
str = get(h.respwin_dur,'String');
val = get(h.respwin_dur,'Value');
dur = str2num(str{val})*1000; %msec

%Use Active X controls to set duration directly in RPVds circuit
AX.SetTagVal('RespWinDur',dur);

%UPDATE RESPONSE WINDOW DELAY
function updateResponseWinDelay(h)
global AX

%Get time out duration from GUI
str = get(h.respwin_delay,'String');
val = get(h.respwin_delay,'Value');
delay = str2num(str{val})*1000; %msec

%Use Active X controls to set duration directly in RPVds circuit
AX.SetTagVal('RespWinDelay',delay);

%UPDATE RESPONSE WINDOW DELAY
function updateSilentDelay(h)
global AX

%Get time out duration from GUI
str = get(h.silent_delay,'String');
val = get(h.silent_delay,'Value');
delay = str2num(str{val})*1000; %msec

%Use Active X controls to set duration directly in RPVds circuit
AX.SetTagVal('Silent_delay',delay);

%UPDATE TIME OUT DURATION
function updateTimeOut(h)
global AX

%Get time out duration from GUI
TOstr = get(h.TOduration,'String');
TOval = get(h.TOduration,'Value');
TOdur = str2num(TOstr{TOval})*1000; %msec

%Use Active X controls to set duration directly in RPVds circuit
AX.SetTagVal('to_duration',TOdur);

%UPDATE MINIMUM POKE DURATION
function updateMinPoke(h)
global AX

%Get minimum poke duration from GUI
Pokestr = get(h.MinPokeDur,'String');
Pokeval = get(h.MinPokeDur,'Value');
Pokedur = str2num(Pokestr{Pokeval})*1000; %msec

%Use Active X controls to set duration directly in RPVds circuit
AX.SetTagVal('MinPokeDur',Pokedur);

%PUMP CONTROL FUNCTION
function pumpcontrol(h)
global AX PUMPHANDLE

%Get reward volume from GUI
rewardstr = get(h.reward_vol,'String');
rewardval = get(h.reward_vol,'Value');
vol = str2num(rewardstr{rewardval})/1000; %ml

%Get reward rate from GUI
ratestr = get(h.Pumprate,'String');
rateval = get(h.Pumprate,'Value');
rate = str2num(ratestr{rateval}); %ml/min
rate_in_msec = rate*(1/60)*(1/1000); %ml/msec

%Calculate reward duration for RPVds circuit
reward_dur = vol/rate_in_msec;

%Use Active X controls to set parameters directly in RPVds circuit.
%Circuit will automatically calculate the duration needed to obtain the
%desired reward volume at the given pump rate.
 AX.SetTagVal('reward_dur',reward_dur);
 
%Set pump rate directly (ml/min)
fprintf(PUMPHANDLE,'RAT%0.1f\n',rate) 





%----------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%    TEXT UPDATE FUNCTIONS   %%%%%%%%%%%%%%%%%%%%%%
%----------------------------------------------------------------------

%UPDATE NEXT TRIAL IN GUI TEXT
function updateNextTrial(handle)
global USERDATA

%Create a cell array containing the information for the next trial
colnames = get(handle,'ColumnName');
expect_col =  find(strcmpi(colnames,'Expected'));

NextTrialData = struct2cell(USERDATA)';

if ~isempty(expect_col)
    if NextTrialData{expect_col} == 1
        NextTrialData(expect_col) = {'Yes'};
    else
        NextTrialData(expect_col) = {'No'};
    end
end

%Update the table handle
set(handle,'Data',NextTrialData);


%POPULATE TRIAL FILTER TABLE AND REMINDER TRIAL INFO
function populateLoadedTrials(handle,remindhandle)
global RUNTIME ROVED_PARAMS


%Pull trial list
trialList = RUNTIME.TRIALS.trials;

%Find the index with the reminder info
remind_col = find(ismember(RUNTIME.TRIALS.writeparams,'Reminder'));
remind_row = find([trialList{:,remind_col}] == 1);
reminder_trial = trialList(remind_row,:);

%Set trial filter column names and find column with trial type
set(remindhandle,'ColumnName',ROVED_PARAMS);
set(handle,'ColumnName',[ROVED_PARAMS,'Present']);
colind = find(strcmpi(ROVED_PARAMS,'TrialType'));
expect_ind = find(strcmpi(ROVED_PARAMS,'Expected'));

%Remove reminder trial from trial list
trialList(remind_row,:) = [];

%Set up two datatables
D_remind = cell(1,numel(ROVED_PARAMS));
D = cell(size(trialList,1),numel(ROVED_PARAMS)+1);

%For each roved parameter
for i = 1:numel(ROVED_PARAMS)
    
   %Find the appropriate index
   ind = find(strcmpi(ROVED_PARAMS(i),RUNTIME.TRIALS.writeparams));
 
   if isempty(ind)
       ind = find(strcmpi(['*', ROVED_PARAMS{i}],RUNTIME.TRIALS.writeparams));
   end
   
   %Add parameter each datatable
   D(:,i) = trialList(:,ind);
   D_remind(1,i) = reminder_trial(1,ind);
end

GOind = find([D{:,colind}] == 0);
NOGOind = find([D{:,colind}] == 1);
YESind = find([D{:,expect_ind}] == 1);
NOind = find([D{:,expect_ind}] == 0);

D(GOind,colind) = {'GO'};
D(NOGOind,colind) = {'NOGO'};
D(YESind,expect_ind) = {'Yes'};
D(NOind,expect_ind) = {'No'};

D_remind(1,colind) = {'REMIND'};
D_remind(1,expect_ind) = {'Yes'};
D(:,end) = {'true'};

%Populate roved trial list box
set(handle,'Data',D)
set(remindhandle,'Data',D_remind);


%Set formatting parameters
formats = cell(1,size(D,2));
formats(1,:) = {'numeric'};
formats(1,colind) = {'char'};
formats(1,end) = {'logical'};

set(handle,'ColumnFormat',formats);

editable = zeros(1,size(D,2));
editable(1,end) = 1;
editable = logical(editable);
set(handle,'ColumnEditable',editable)


%UPDATE RESPONSE HISTORY TABLE
function updateResponseHistory(handle,HITind,MISSind,...
    FAind,CRind,GOind,NOGOind,variables,...
    ntrials,TrialTypeInd,TrialType,...
    REMINDind,YESind,NOind,expectInd)
%Establish data table
numvars = size(variables,2);
D = cell(ntrials,numvars+1);

%Set up roved parameter arrays
D(:,1:numvars) = num2cell(variables);

%Set up response cell array
Responses = cell(size(HITind));
Responses(HITind)  = {'Hit'};
Responses(MISSind) = {'Miss'};
Responses(FAind)   = {'FA'};
Responses(CRind)   = {'CR'};
D(:,end) = Responses;

%Set up trial type cell array
TrialTypeArray = cell(size(TrialType));
TrialTypeArray(GOind) = {'GO'};
TrialTypeArray(NOGOind) = {'NOGO'};
TrialTypeArray(REMINDind) = {'REMIND'};
D(:,TrialTypeInd) = TrialTypeArray;

%Set up expected array
if ~isempty(expectInd)
    ExpectedArray = cell(size(TrialTypeArray));
    ExpectedArray(YESind) = {'Yes'};
    ExpectedArray(NOind) = {'No'};
    D(:,expectInd) = ExpectedArray;
end

%Flip so the recent trials are on top
D = flipud(D); 

%Number the rows with the correct trial number (i.e. reverse order)
r = length(Responses):-1:1;
r = cellstr(num2str(r'));

set(handle,'Data',D,'RowName',r)


%UPDATE FALSE ALARM RATE
function FArate = updateFArate(handle,variables,FAind,NOGOind)

%Compile data into a matrix 
currentdata = [variables,FAind];

%Select out just the NOGO trials
NOGOtrials = currentdata(NOGOind,:);

%Calculate the FA rate and update handle
if ~isempty(NOGOtrials)
    FArate = 100*(sum(NOGOtrials(:,end))/numel(NOGOtrials(:,end)));
    set(handle,'String', sprintf( '%0.2f',FArate));
else
    FArate = str2num(get(handle,'String'));
end


%UPDATE TRIAL HISTORY
function updateTrialHistory(handle,variables,reminders)
global RUNTIME

%Find unique trials
data = [variables,reminders];
unique_trials = unique(data,'rows');

%Determine column indices
colnames = get(handle,'ColumnName');
colind = find(strcmpi(colnames,'TrialType'));
expectind = find(strcmpi(colnames,'Expected'));

%Determine the total number of presentations for each trial
numTrials = zeros(size(unique_trials,1),1);
for i = 1:size(unique_trials,1)
    numTrials(i) = sum(ismember(data,unique_trials(i,:),'rows'));
end

%Create cell array
D =  num2cell(unique_trials);

%Update the text of the datatable
GOind = find([D{:,colind}] == 0);
NOGOind = find([D{:,colind}] == 1);
REMINDind = find([D{:,end}] == 1);
YESind = find([D{:,expectind}] == 1);
NOind = find([D{:,expectind}] == 0);

D(GOind,colind) = {'GO'};
D(NOGOind,colind) = {'NOGO'};
D(REMINDind,colind) = {'REMIND'};

if ~isempty(expectind)
    D(YESind,expectind) = {'YES'};
    D(NOind,expectind) = {'NO'};
end

D(:,end) = num2cell(numTrials);

set(handle,'Data',D)




%-----------------------------------------------------------
%%%%%%%%%%%%%% PLOTTING FUNCTIONS %%%%%%%%%%%%%%%
%------------------------------------------------------------

%PLOT REALTIME HISTORY
function UpdateAxHistory(h,starttime,event)
global AX
persistent timestamps poke_hist spout_hist sound_hist water_hist trial_hist response_hist
%light_hist


%Determine current time
currenttime = etime(event.Data.time,starttime);

%Update timetamp
timestamps = [timestamps;currenttime];

%Update poke history
poke_TTL = AX.GetTagVal('Poke_TTL');
poke_hist = [poke_hist;poke_TTL];

%Update Spout History
spout_TTL = AX.GetTagVal('Spout_TTL');
spout_hist = [spout_hist;spout_TTL];

%Update Water History
water_TTL = AX.GetTagVal('Water_TTL');
water_hist = [water_hist; water_TTL];

%Update Sound history
sound_TTL = AX.GetTagVal('Sound_TTL');
sound_hist = [sound_hist;sound_TTL];

%Update trial status
trial_TTL = AX.GetTagVal('InTrial_TTL');
trial_hist = [trial_hist;trial_TTL];

%Update response window status
response_TTL = AX.GetTagVal('RespWin_TTL');
response_hist = [response_hist;response_TTL];

% %Update Room Light history
% light_TTL = AX.GetTagVal('Light_TTL');
% light_hist = [light_hist;light_TTL];

%Limit matrix size
xmin = timestamps(end)- 10;
xmax = timestamps(end)+ 10;
ind = find(timestamps > xmin+1 & timestamps < xmax-1);

timestamps = timestamps(ind);
poke_hist = poke_hist(ind);
spout_hist = spout_hist(ind);
water_hist = water_hist(ind);
sound_hist = sound_hist(ind);
trial_hist = trial_hist(ind);
response_hist = response_hist(ind);
%light_hist = light_hist(ind);

%Update realtime displays
str = get(h.realtime_display,'String');
val = get(h.realtime_display,'Value');

switch str{val}
    case {'Continuous'}
        plotContinuous(timestamps,trial_hist,h.trialAx,[0.5 0.5 0.5],xmin,xmax);
        plotContinuous(timestamps,poke_hist,h.pokeAx,'g',xmin,xmax)
        plotContinuous(timestamps,sound_hist,h.soundAx,'r',xmin,xmax)
        plotContinuous(timestamps,spout_hist,h.spoutAx,'k',xmin,xmax)
        plotContinuous(timestamps,water_hist,h.waterAx,'b',xmin,xmax,'Time (sec)')
        plotContinuous(timestamps,response_hist,h.respWinAx,[1 0.5 0],xmin,xmax);
    case {'Triggered'}
        plotTriggered(timestamps,trial_hist,poke_hist,h.trialAx,[0.5 0.5 0.5]);
        plotTriggered(timestamps,poke_hist,poke_hist,h.pokeAx,'g');
        plotTriggered(timestamps,sound_hist,poke_hist,h.soundAx,'r');
        plotTriggered(timestamps,spout_hist,poke_hist,h.spoutAx,'k');
        plotTriggered(timestamps,water_hist,poke_hist,h.waterAx,'b','Time (sec)');
        plotTriggered(timestamps,response_hist,poke_hist,h.respWinAx,[1 0.5 0],xmin,xmax);
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


%PLOT INPUT-OUTPUT FUNCTION
function updateIOPlot(h,variables,HITind,GOind,FArate,REMINDind)
global ROVED_PARAMS

%Compile data into a matrix. 
currentdata = [variables,HITind];

%If user wants to exclude reminder trials...    
if get(h.PlotRemind,'Value') == 0
    currentdata(REMINDind,:) = [];
    TrialTypeInd = find(strcmpi('TrialType',ROVED_PARAMS));
    TrialType = currentdata(:,TrialTypeInd);
    GOind = find(TrialType == 0);
end

if ~isempty(currentdata)
    
    %Select out just the GO trials
    GOtrials = currentdata(GOind,:);
    
    %Determine the variable to plot on the x axis
    x_ind = get(h.Xaxis,'Value');
    x_strings = get(h.Xaxis,'String');
    
    
    %Find the column index for the xaxis variable of interest
    col_ind = find(strcmpi(x_strings(x_ind),ROVED_PARAMS));
    
    %Calculate hit rate for each value of the roved parameter of interest
    vals = unique(GOtrials(:,col_ind));
    plotting_data = [];
    
    for i = 1: numel(vals)
        val_data = GOtrials(GOtrials(:,col_ind) == vals(i),:);
        hit_rate = 100*(sum(val_data(:,end))/numel(val_data(:,end)));
        plotting_data = [plotting_data;vals(i),hit_rate];
    end
    
    %Set up the x text
    switch x_strings{x_ind}
        case 'Silent_delay'
            xtext = 'Silent Delay (msec)';
        case 'dB SPL'
            xtext = 'Sound Level (dB SPL)';
        case 'Freq'
            xtext = 'Sound Frequency (Hz)';
        case 'RespWinDelay'
            xtext = 'Response Window Delay (s)';
        case 'Stim_duration'
            xtext = 'Sound duration (s)';
        otherwise
            xtext = '';
    end
    
    
    %Determine if we need to plot hit rate or d prime
    y_ind = get(h.Yaxis,'Value');
    y_strings = get(h.Yaxis,'String');
    
    switch y_strings{y_ind}
        
        %If we want to plot hit rate, we just need to format the plot
        case 'Hit Rate'
            
            ylimits = [0 100];
            ytext = 'Hit rate (%)';
            
        %If we want to plot d', we need to do some calculations and format the plot
        case 'd'''
            
            ylimits = [0 3.5];
            ytext = 'd''';
            
            %Convert back to proportions
            plotting_data(:,2) = plotting_data(:,2)/100;
            FArate = FArate/100;
            
            %Set bounds for hit rate and FA rate (5-95%)
            %Setting bounds prevents d' values of -Inf and Inf from occurring
            plotting_data(plotting_data(:,2) < 0.05,2) = 0.05;
            plotting_data(plotting_data(:,2) > 0.95,2) = 0.95;
            
            if FArate < 0.05
                FArate = 0.05;
            elseif FArate > 0.95
                FArate = 0.95;
            end
            
            %Covert proportions into z scores
            z_fa = sqrt(2)*erfinv(2*FArate-1);
            z_hit = sqrt(2)*erfinv(2*plotting_data(:,2)- 1);
            
            %Calculate d prime
            plotting_data(:,2) = z_hit - z_fa;
            
    end
    
    
    %Update plot
    if ~isempty(plotting_data)
        ax = h.IOPlot;
        cla(ax)
        xmin = min(vals)-10;
        xmax = max(vals)+10;
        plot(ax,plotting_data(:,1),plotting_data(:,2),'bs-','linewidth',2,...
            'markerfacecolor','b')
        set(ax,'ylim',ylimits,'xlim',[xmin xmax],'xgrid','on','ygrid','on');
        xlabel(ax,xtext,'FontSize',12,'FontName','Arial','FontWeight','Bold')
        ylabel(ax,ytext,'FontSize',12,'FontName','Arial','FontWeight','Bold')
        
        %Adjust plot formatting if selected variable is Expected
        switch x_strings{x_ind}
            case 'Expected'
                set(ax,'XLim',[-1 2])
                set(ax,'XTick',[0 1]);
                set(ax,'XTickLabel',{'Unexpected' 'Expected'})
                set(ax,'FontSize',12,'FontWeight','Bold')
        end
        
    end
    
end





%-----------------------------------------------------------
%%%%%%%%%%%%%%        GUI FUNCTIONS           %%%%%%%%%%%%%%%
%------------------------------------------------------------

%CLOSE GUI WINDOW 
function figure1_CloseRequestFcn(hObject, eventdata, handles)
global PUMPHANDLE

%Prompt user
selection = questdlg('Do you wish to end the experiment?',...
      '','Yes','No','No'); 
  
   switch selection, 
      case 'Yes',
         %Close COM port to PUMP and delete figure
         fclose(PUMPHANDLE);
         delete(PUMPHANDLE);
         delete(hObject);
      case 'No'
      return 
   end
   

















