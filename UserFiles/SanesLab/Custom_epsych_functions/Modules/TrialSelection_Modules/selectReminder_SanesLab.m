function [ok,remind_row] = selectReminder_SanesLab(TRIALS,remind_row) 
%[ok,remind_row] = selectReminder_SanesLab(TRIALS,remind_row) 
%
%Custom function for SanesLab epsych
%
%This function is for instances when more than one reminder trial is
%specified.  In these cases, the user is prompted to select one of the
%reminder trials as the actual, functional reminder trial.
%
%Inputs: 
%   TRIALS: RUNTIME.TRIALS structure 
%   remind_row: the row(s) in TRIALS.trials specifying the reminder trials
%
%Outputs:
%   ok: ok status for the TrialFcn (indicates we're ready to proceed)
%   remind_row: the user-selected index of the reminder trial row
%
%Written by ML Caras 7.22.2016.
%Updated by KP 11.4.2016. (param WAV/MAT compatibility)


%Pull out parameter names and options.
parameter_names = TRIALS.writeparams;
options = cell(numel(remind_row),1);

%Find and ignore any params that are structures (WAV or MAT file info). 
%The FileID will remain, so this param will be included.
buf_col = find(sum(cellfun(@isstruct,TRIALS.trials))>0);
TRS = TRIALS.trials;
TRS(:,buf_col) = [];
parameter_names(buf_col) = [];

for i = 1:numel(remind_row)
    options{i} = num2str([TRS{remind_row(i),:}]);
end

%Create prompt string
promptstr = {'More than one reminder trial specified.';...
    'Pick one. Parameters are: '};

for i = 1:numel(parameter_names)
    promptstr{end+1,1} = parameter_names{i};
end

%Force user to make a selection
ok = 0;
while ok == 0
    beep
    [selection, ok] = listdlg('PromptString',...
        promptstr,'SelectionMode','single',...
        'ListSize',[300 300],'ListString',options);
    
end

%Update the remind_row with the user's choice
remind_row = remind_row(selection);



end
