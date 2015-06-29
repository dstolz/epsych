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
function Pure_tone_detection_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
global ROVED_PARAMS GUI_HANDLES


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

%Setup X-axis options
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
GUI_HANDLES.trial_filter = get(handles.TrialFilter,'Data');
GUI_HANDLES.expected_prob = get(handles.ExpectedProb);
GUI_HANDLES.RepeatNOGO = get(handles.RepeatNOGO);


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

%TIMER CALLBACK FUNCTION
function BoxTimerRunTime(~,event,f)
global RUNTIME ROVED_PARAMS GUI_HANDLES
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
if RUNTIME.UseOpenEx
    reminders = [DATA.Behavior_Reminder]';
else
    reminders = [DATA.Reminder]';
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

%Collect GUI parameters for selecting next trial
GUI_HANDLES.go_prob = get(h.GoProb);
GUI_HANDLES.Nogo_lim = get(h.NOGOlimit);
GUI_HANDLES.trial_filter = get(h.TrialFilter);
GUI_HANDLES.expected_prob = get(h.ExpectedProb);
GUI_HANDLES.RepeatNOGO = get(h.RepeatNOGO);

%Update Next trial information 
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

%Update time out duration
updateTimeOut(h)

%Update minimumpoke duration
updateMinPoke(h)

%Update pump control
pumpcontrol(h)


lastupdate = ntrials;

%TIMER ERROR FUNCTION
function BoxTimerError(~,~)

%TIMER STOP FUNCTION
function BoxTimerStop(~,~)

%TIMER START FUNCTION
function BoxTimerSetup(~,~,~)




%----------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%    GUI FUNCTIONS   %%%%%%%%%%%%%%%%%%%%%%%%
%----------------------------------------------------------------------

%APPLY CHANGES BUTTON
function apply_Callback(h)
global GUI_HANDLES

%Collect GUI parameters for selecting next trial
GUI_HANDLES.go_prob = get(h.GoProb);
GUI_HANDLES.Nogo_lim = get(h.NOGOlimit);
GUI_HANDLES.trial_filter = get(h.TrialFilter);
GUI_HANDLES.expected_prob = get(h.ExpectedProb);
GUI_HANDLES.RepeatNOGO = get(h.RepeatNOGO);


%Update time out duration
updateTimeOut(h)

%Update minimumpoke duration
updateMinPoke(h)

%Update pump control
pumpcontrol(h)



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


%NEXT TRIAL UPDATE FUNCTION
function updateNextTrial(handle)
global USERDATA

%Create a cell array containing the information for the next trial
colnames = get(handle,'ColumnName');
expect_col =  find(strcmpi(colnames,'Expected'));

NextTrialData = struct2cell(USERDATA)';

if NextTrialData{expect_col} == 1
    NextTrialData(expect_col) = {'Yes'};
else
    NextTrialData(expect_col) = {'No'};
end

%Update the table handle
set(handle,'Data',NextTrialData);


%RESPONSE HISTORY FUNCTION
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
ExpectedArray = cell(size(TrialTypeArray));
ExpectedArray(YESind) = {'Yes'};
ExpectedArray(NOind) = {'No'};
D(:,expectInd) = ExpectedArray;

%Flip so the recent trials are on top
D = flipud(D); 

%Number the rows with the correct trial number (i.e. reverse order)
r = length(Responses):-1:1;
r = cellstr(num2str(r'));

set(handle,'Data',D,'RowName',r)


%FALSE ALARM RATE FUNCTION
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


%INPUT-OUTPUT PLOTTING FUNCTION
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
    if strcmpi(x_strings(x_ind),'Silent_delay')
        xtext = 'Silent Delay (msec)';
    elseif strcmpi(x_strings(x_ind),'dBSPL')
        xtext = 'Sound Level (dB SPL)';
    elseif strcmpi(x_strings(x_ind),'Freq')
        xtext = 'Sound Frequency (Hz)';
    elseif strcmpi(x_strings(x_ind),'Expected')
        xtext = 'Expected';
    else
        xtext = '';
    end
    
    
    %Determine if we need to plot hit rate or d prime
    y_ind = get(h.Yaxis,'Value');
    y_strings = get(h.Yaxis,'String');
    
    %If we want to plot hit rate, we just need to format the plot
    if strcmpi(y_strings(y_ind),'Hit Rate')
        ylimits = [0 100];
        ytext = 'Hit rate (%)';
        
    %If we want to plot d', we need to do some calculations and format the plot
    elseif strcmpi(y_strings(y_ind), 'd''')
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
    end
end


%TRIAL HISTORY FUNCTION
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
D(YESind,expectind) = {'YES'};
D(NOind,expectind) = {'NO'};

D(:,end) = num2cell(numTrials);

set(handle,'Data',D)


%TRIAL FILTER SELECTION FUNCTIONS
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
    guidata(hObject,handles)
end
function TrialFilter_CellEditCallback(hObject, eventdata, handles)


%REMIND FUNCTION
function Remind_Callback(hObject, eventdata, handles)
global GUI_HANDLES

GUI_HANDLES.remind = 1;

guidata(hObject,handles)


%REALTIME HISTORY FUNCTION
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
        plotTriggered(timestamps,trial_hist,trial_hist,h.trialAx,[0.5 0.5 0.5]);
        plotTriggered(timestamps,poke_hist,trial_hist,h.pokeAx,'g');
        plotTriggered(timestamps,sound_hist,trial_hist,h.soundAx,'r');
        plotTriggered(timestamps,spout_hist,trial_hist,h.spoutAx,'k');
        plotTriggered(timestamps,water_hist,trial_hist,h.waterAx,'b','Time (sec)');
        plotTriggered(timestamps,response_hist,trial_hist,h.respWinAx,[1 0.5 0],xmin,xmax);
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

if nargin == 8
    xlabel(ax,varargin{1},'Fontname','Arial','FontSize',12)
else
    set(ax,'XTickLabel','');
end


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
    xmin = timestamps(1) - 2;
    xmax = timestamps(end) + 2;
    set(ax,'xlim',[xmin xmax]);
    set(ax,'ylim',[0.9 1.1]);
    set(ax,'YTickLabel','');
    set(ax,'XGrid','on');
    set(ax,'XMinorGrid','on');
end



if nargin == 6
    xlabel(ax,varargin{1},'Fontname','Arial','FontSize',12)
else
    set(ax,'XTickLabel','');
end


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











% --- Executes on slider movement.
function realtime_xscale_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function realtime_xscale_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end




























% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over TOduration.
function TOduration_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to TOduration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function TOduration_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TOduration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function MinPokeDur_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MinPokeDur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
