function handles = populateLoadedTrials_SanesLab(handles)
%Custom function for SanesLab epsych
%
%This function populates the trial filter table, and the reminder trial
%info table.
%Inputs:
%   handles: handles structure for GUI
%
%
%Written by ML Caras 7.24.2016

global RUNTIME ROVED_PARAMS


%Pull trial list
trialList = RUNTIME.TRIALS.trials;
colnames = RUNTIME.TRIALS.writeparams;

%Find the index with the reminder info
remind_row = findReminderRow_SanesLab(colnames,trialList);
reminder_trial = trialList(remind_row,:);


%Set trial filter column names and find column with trial type
if RUNTIME.UseOpenEx
    rp =  cellfun(@(x) x(10:end), ROVED_PARAMS, 'UniformOutput',false);
    set(handles.ReminderParameters,'ColumnName',rp);
    set(handles.TrialFilter,'ColumnName',[rp,'Present']);
else
    set(handles.ReminderParameters,'ColumnName',ROVED_PARAMS);
    set(handles.TrialFilter,'ColumnName',[ROVED_PARAMS,'Present']);
end

colind =  findTrialTypeColumn_SanesLab(ROVED_PARAMS);

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

D(GOind,colind) = {'GO'};
D(NOGOind,colind) = {'NOGO'};

D_remind(1,colind) = {'REMIND'};
D(:,end) = {'true'};

%Populate roved trial list box
set(handles.TrialFilter,'Data',D)
set(handles.ReminderParameters,'Data',D_remind);


%Set formatting parameters
formats = cell(1,size(D,2));
formats(1,:) = {'numeric'};
formats(1,colind) = {'char'};
formats(1,end) = {'logical'};

set(handles.TrialFilter,'ColumnFormat',formats);

editable = zeros(1,size(D,2));
editable(1,end) = 1;
editable = logical(editable);
set(handles.TrialFilter,'ColumnEditable',editable)