function handles = updateTrialHistoryPassive_SanesLab(handles,variables)
%handles = updateTrialHistory_SanesLab(handles,variables)
%
%Custom function for SanesLab epsych
%
%This function updates the GUI Trial History Table. 
%
%Inputs:
%   handles: GUI handles structure
%   variables: matrix of trial information
%
%
%
%Written by ML Caras 7.28.2016, KP 11-2016.

global ROVED_PARAMS RUNTIME


%Find unique trials
data = variables;

%Remove TrialType and Reminder data
if RUNTIME.UseOpenEx
    data(:,strcmpi(ROVED_PARAMS,[handles.module,'.TrialType'])) = [];
    data(:,strcmpi(ROVED_PARAMS,[handles.module,'.Reminder']))  = [];
else
    data(:,strcmpi(ROVED_PARAMS,'TrialType')) = [];
    data(:,strcmpi(ROVED_PARAMS,'Reminder'))  = [];
end


unique_trials = unique(data,'rows');

%Determine the total number of presentations and hits for each go stim
numTrials = zeros(size(unique_trials,1),1);
for i = 1:size(unique_trials,1)
    numTrials(i) = sum(ismember(data,unique_trials(i,:),'rows'));
end

all_trials = [unique_trials numTrials];


%Sort based on AM depth (!!not sufficiently generalized code!)
colnames = get(handles.TrialHistory,'ColumnName');
if any(strcmpi(colnames,'AMdepth'))
    all_trials_sorted = sortrows(all_trials,find(strcmpi(colnames,'AMdepth')));
else
    all_trials_sorted = sortrows(all_trials,1);
end


%Add total trial count at bottom
all_trials_sorted(end+1,end) = sum(numTrials);


%Create cell array
D =  num2cell(all_trials_sorted);
D(end,end-1)   = {'Total trials'};
D(end,1:end-2) = {' '};


set(handles.TrialHistory,'Data',D)

