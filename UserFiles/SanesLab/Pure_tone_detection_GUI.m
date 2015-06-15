function varargout = Pure_tone_detection_GUI(varargin)
% GUI for pure tone detection task
%     
% Written by ML Caras Jun 10, 2015
%
% Last Modified by GUIDE v2.5 15-Jun-2015 12:15:32

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
    'Period',1, ...
    'StartFcn',{@BoxTimerSetup,f}, ...
    'TimerFcn',{@BoxTimerRunTime,f}, ...
    'ErrorFcn',{@BoxTimerError}, ...
    'StopFcn', {@BoxTimerStop}, ...
    'TasksToExecute',inf, ...
    'StartDelay',2); 


%TIMER START FUNCTION: SETS UP INITIAL GUI TEXT
function BoxTimerSetup(hObj,~,f);
global ROVED_PARAMS GUI_HANDLES
h = guidata(f);

%Setup Response History Table
cols = cell(1,numel(ROVED_PARAMS)+1);
cols(1:numel(ROVED_PARAMS)) = ROVED_PARAMS;
cols(end) = {'Response'};
datacell = cell(size(cols));
set(h.DataTable,'Data',datacell,'RowName','0','ColumnName',cols);


%Setup Next Trial Table
empty_cell = cell(1,numel(ROVED_PARAMS));
set(h.NextTrial,'Data',empty_cell,'ColumnName',ROVED_PARAMS);


%Setup Trial History Table
trial_history_cols = cols;
trial_history_cols(end) = {'# Trials'};
set(h.TrialHistory,'Data',datacell,'ColumnName',trial_history_cols);


%Set up list of possible trial types (ignores reminder)
populateLoadedTrials(h.TrialFilter,h.ReminderParameters);

%Setup X-axis options
ind = ~strcmpi(ROVED_PARAMS,'TrialType');
xaxis_opts = ROVED_PARAMS(ind);
set(h.Xaxis,'String',xaxis_opts)

%Establish predetermined yaxis options
yaxis_opts = {'Hit Rate', 'd'''};
set(h.Yaxis,'String',yaxis_opts);

%Collect GUI parameters for selecting next trial
GUI_HANDLES.go_prob = get(h.GoProb);
GUI_HANDLES.Nogo_lim = get(h.NOGOlimit);
GUI_HANDLES.trial_filter = get(h.TrialFilter,'Data');
GUI_HANDLES.expected_prob = get(h.ExpectedProb);
% GUI_HANDLES.reminder_selected = get(h.Remind,'Value');


%TIMER CALLBACK FUNCTION
function BoxTimerRunTime(hObj,~,f)
global RUNTIME ROVED_PARAMS GUI_HANDLES
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
GUI_HANDLES.trial_filter = get(h.TrialFilter,'Data');
GUI_HANDLES.expected_prob = get(h.ExpectedProb);
% GUI_HANDLES.reminder_selected = get(h.Remind,'Value');

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


%Update Realtime Plot
%UpdateAxHistory(h.axHistory,TS,HITind,MISSind,FAind,CRind);
lastupdate = ntrials;

%TIMER ERROR FUNCTION
function BoxTimerError(~,~)

%TIMER STOP FUNCTION
function BoxTimerStop(~,~)




%----------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%    GUI FUNCTIONS   %%%%%%%%%%%%%%%%%%%%%%%%
%----------------------------------------------------------------------
%POPULATE TRIAL FILTER TABLE AND REMINDER TRIAL INFO
function populateLoadedTrials(handle,remindhandle)
global RUNTIME ROVED_PARAMS


%Pull trial list
trialList = RUNTIME.TRIALS.trials;

%Find the index with the reminder info
remind_col = find(ismember(RUNTIME.TRIALS.readparams,'Reminder'));
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
   ind = find(strcmpi(ROVED_PARAMS(i),RUNTIME.TRIALS.readparams));
 
   if isempty(ind)
       ind = find(strcmpi(['*', ROVED_PARAMS{i}],RUNTIME.TRIALS.readparams));
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

global RUNTIME USERDATA


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
%currentdata = [SilentDelay,FAind];
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
global ROVED_PARAMS RUNTIME

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

%REMIND FUNCTION
function Remind_Callback(hObject, eventdata, handles)







