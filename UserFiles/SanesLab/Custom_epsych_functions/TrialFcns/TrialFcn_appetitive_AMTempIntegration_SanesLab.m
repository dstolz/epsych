function NextTrialID = TrialFcn_appetitive_AMTempIntegration_SanesLab(TRIALS)
% NextTrialID = TrialFcn_PureToneDetection_MasterHelper(TRIALS)
%
% This is a custom epsych function for the Sanes Lab for use with
% appetitive GO-NOGO tasks.
%
% NextTrialID is the index of a row in TRIALS.trials. This row contains all
% of the information for the next trial.
%
% Updated by ML Caras Jun 15 2015
%warning('off','MATLAB:hg:uicontrol:ParameterValuesMustBeValid');

global RUNTIME USERDATA ROVED_PARAMS GUI_HANDLES PUMPHANDLE
global CONSEC_NOGOS CURRENT_FA_STATUS CURRENT_EXPEC_STATUS
persistent repeat_flag ok remind_row

%Seed the random number generator based on the current time so that we
%don't end up with the same sequence of trials each session
rng('shuffle');

%Find reminder column and row
if isempty(ok)
    try
        if RUNTIME.UseOpenEx
            remind_col = find(ismember(TRIALS.writeparams,'Behavior.Reminder'));
        else
            remind_col = find(ismember(TRIALS.writeparams,'Reminder'));
        end
        
        remind_row = find([TRIALS.trials{:,remind_col}] == 1);
    catch me
        errordlg('Error: No reminder trial specified. Edit protocol.')
        rethrow(me)
    end
end


%If there is more than one reminder trial, prompt user to select which
%reminder trial he/she would like to use.
if numel(remind_row) > 1 && isempty(ok)
    
    %Pull out parameter names and options.
    parameter_names = TRIALS.writeparams;
    options = cell(numel(remind_row),1);
    
    for i = 1:numel(remind_row)
        options{i} = num2str([TRIALS.trials{remind_row(i),:}]);
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





%If it's the very start of the experiment...
if TRIALS.TrialIndex == 1
    
    %Start fresh
    USERDATA = [];
    ROVED_PARAMS = [];
    CONSEC_NOGOS = [];
    CURRENT_FA_STATUS = [];
    CURRENT_EXPEC_STATUS = [];

    %If the pump has not yet been initialized
    if isempty(PUMPHANDLE)
       
        %Close and delete all open serial ports
        out = instrfind('Status','open');
        if ~isempty(out)
            fclose(out);
            delete(out);
        end
        
        %Once all serial ports are closed, open one and initialize pump
        PUMPHANDLE = TrialFcn_PumpControl;
        
    end
    
    
    %Identify all roved parameters. Note: we discard the reminder trial row
    trials = TRIALS.trials;
    trials(remind_row,:) = [];
    
    %Set up an empty matrix for the roved parameter indices
    roved_inds = [];
    
    %Identify columns in the trial matrix that contain parameters that we
    %want to ignore (i.e. ~Freq.Amp and ~Freq.Norm values for calibrations)
    ignore = find(~cellfun(@isempty,strfind(TRIALS.writeparams,'~')));
    
    %For each column (parameter)...
    for i = 1:size(trials,2)
        
        %Find the number of unique variables
        num_param = numel(unique([trials{:,i}]));
        
        %If there is more than one unique variable for the column
        if num_param > 1
            
            %If the index of the parameter is one that we want to include
            %(i.e., we don't want to ignore it)
            if ~ismember(i,ignore)
                
                %Add that index into our roved parameter index list
                roved_inds = [roved_inds;i];
                
            end
        end
        
    end

% % %     roved_inds = unique(roved_inds);
% % %     sel = roved_inds == 1;
% % %     if( sum(sel) == 0 )
% % %         roved_inds = [1;roved_inds];
% % %     end
    
    %---HARD CODE variable for interim---%
    roved_inds = [1;2;4];
    
    %Pull out the names of the roved parameters
    ROVED_PARAMS = TRIALS.writeparams(roved_inds);
    
    %Initialize some flags to zero
    repeat_flag = 0;
    CONSEC_NOGOS = 0;
    CURRENT_FA_STATUS = 0;
    CURRENT_EXPEC_STATUS = 0;
end


%Determine if expectation is a roved parameter
if RUNTIME.UseOpenEx
    expectation_roved = cell2mat(strfind(ROVED_PARAMS,'Behavior.Expected'));
else
    expectation_roved = cell2mat(strfind(ROVED_PARAMS,'Expected'));
end

%Find the column indices for Trial Type and Expected times
if RUNTIME.UseOpenEx
    trial_type_ind = find(ismember(TRIALS.writeparams,'Behavior.TrialType'));
    
    if expectation_roved
        expected_ind = find(ismember(TRIALS.writeparams,'Behavior.Expected'));
    else
        expected_ind = [];
    end
else
    trial_type_ind = find(ismember(TRIALS.writeparams,'TrialType'));
    
    if expectation_roved
        expected_ind = find(ismember(TRIALS.writeparams,'Expected'));
    else
        expected_ind = [];
    end
    
end



%-----------------------------------------------------------------
%%%%%%%%%%%%%%%%% TRIAL SELECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------------------------------------------------


%Set the first N trials to be reminder trials.
%N is determined by GUI; default is 5.
if ~isempty(GUI_HANDLES)
    num_reminds_ind =  GUI_HANDLES.num_reminds.Value;
    num_reminds = str2num(GUI_HANDLES.num_reminds.String{num_reminds_ind});
else
    num_reminds = 5;
end


%If we haven't yet presented the required number of reminder trials
if TRIALS.TrialIndex <= num_reminds
    
    NextTrialID = remind_row;
    
%Otherwise, switch to probabilistic delivery
else
    
    try
        %Get indices for different trials and determine some probabilities
        [Nogo_lim,repeat_checkbox,Go_prob,go_indices,nogo_indices,...
            Expected_prob,expect_indices,unexpect_indices] = ...
            getIndices(TRIALS,remind_row,trial_type_ind,expected_ind);
        
        
        %Make our initial random pick (for GO or NOGO trial type)
        initial_random_pick = sum(rand >= cumsum([0, 1-Go_prob, Go_prob]));
        
        %-----------------------------------------------------------------
        %Special case overrides
        %-----------------------------------------------------------------
        %Override initial pick and force a NOGOtrial if the last trial was a
        %FA, and if the "Repeat if FA" checkbox is activated
        if CURRENT_FA_STATUS == 1 && repeat_checkbox == 1
            initial_random_pick = 1;
            repeat_flag = 1;
        end
        
        %Override initial pick or NOGO repeat and force a GO trial
        %if we've reached our consecutive nogo limit
        if CONSEC_NOGOS >= Nogo_lim && Go_prob > 0
            initial_random_pick = 2;
        end
        
        %Override initial pick and force a GO trial if the animal got a
        %repeated FA trial correct
        if repeat_flag == 1 && CURRENT_FA_STATUS == 0 && Go_prob > 0
            initial_random_pick = 2;
        end
        %-----------------------------------------------------------------
        %-----------------------------------------------------------------
        
        %Which trial type did we pick?
        switch initial_random_pick
            
            %NOGO selected
            case 1
                NextTrialID = nogo_indices;
                
                %GO selected
            case 2
                
                %If we're roving expectation, let's make the next random pick
                if expectation_roved == 1
                    next_random_pick = sum(rand >= cumsum([0, 1-Expected_prob, Expected_prob]));
                    
                    %------------------------------
                    %Special case override
                    %------------------------------
                    
                    %Override initial pick and force an expected GO value if
                    %the last trial was unexpected
                    if  CURRENT_EXPEC_STATUS == 1
                        next_random_pick = 2;
                    end
                    
                    %If the next randomly picked number is 2, we picked an expected GO trial
                    if next_random_pick == 2
                        NextTrialID = expect_indices;
                        
                        %If the next randomly picked number is 1, we picked an unexpected GO trial
                    elseif next_random_pick == 1
                        NextTrialID = unexpect_indices;
                    end
                    
                elseif isempty(expectation_roved)
                    
                    NextTrialID = go_indices;
                    
                end
                
                %Reset repeat NOGO flag
                repeat_flag = 0;
                
        end
        
        
        
        %If multiple indices are valid (i.e. there are two GO
        %indices, for instance), then we randomly select one of them
        if numel(NextTrialID) > 1
            r = randi(numel(NextTrialID),1);
            NextTrialID = NextTrialID(r);
        end
        
        
        %--------------------------------------------------------------------
        %Reminder Override
        %--------------------------------------------------------------------
        %Override initial pick and force a reminder trial if the remind buttom
        %was pressed by the end user
        if GUI_HANDLES.remind == 1;
            NextTrialID = remind_row;
            GUI_HANDLES.remind = 0;
            repeat_flag = 0;
        end
        %--------------------------------------------------------------------
    catch
        disp('Help!')
        
    end
    
    
end


try
    %Determine the next trial type for display
    if NextTrialID == remind_row;
        Next_trial_type = 'REMIND';
    elseif TRIALS.trials{NextTrialID,trial_type_ind} == 0
        Next_trial_type = 'GO';
    elseif TRIALS.trials{NextTrialID,trial_type_ind} == 1;
        Next_trial_type = 'NOGO';
    end
    
    
    
    %Update USERDATA Structure
    for i = 1:numel(ROVED_PARAMS)
        
        variable = ROVED_PARAMS{i};
        
        
        switch variable
            case {'TrialType','Behavior.TrialType'}
                USERDATA.TrialType = Next_trial_type;
                
            case {'Reminder','Behavior.Reminder'}
                if RUNTIME.UseOpenEx
                    ind = find(ismember(TRIALS.writeparams,'Behavior.Reminder'));
                else
                    ind = find(ismember(TRIALS.writeparams,'Reminder'));
                end
                
                USERDATA.Reminder = TRIALS.trials{NextTrialID,ind};
                
            case {'Expected','Behavior.Expected'}
                if RUNTIME.UseOpenEx
                    ind = find(ismember(TRIALS.writeparams,'Behavior.Expected'));
                else
                    ind = find(ismember(TRIALS.writeparams,'Expected'));
                end
                
                USERDATA.Expected = TRIALS.trials{NextTrialID,ind};
                
            otherwise
                ind = find(ismember(TRIALS.writeparams,variable));
                
                %Update USERDATA
                if RUNTIME.UseOpenEx
                    eval(['USERDATA.' variable(10:end) '= TRIALS.trials{NextTrialID,ind};'])
                else
                    eval(['USERDATA.' variable '= TRIALS.trials{NextTrialID,ind};'])
                end
        end
        
    end
    
catch
     disp('Help2!')
end


%-------------------------------------------------------------------

%GET INDICES FUCNTION
function [Nogo_lim,repeat_checkbox,Go_prob,go_indices,nogo_indices,...
    Expected_prob,expect_indices,unexpect_indices] = ...
    getIndices(TRIALS,remind_row,trial_type_ind,expected_ind)

global GUI_HANDLES RUNTIME

%First, identify the filter list from the GUI
filterdata = GUI_HANDLES.trial_filter.Data;
filter_cols = GUI_HANDLES.trial_filter.ColumnName';

%Next, identify all possible trials from the TRIALS structure
all_trials = TRIALS.trials;

if RUNTIME.UseOpenEx
    all_cols = cellfun(@(x) x(10:end), TRIALS.writeparams, 'UniformOutput',false);
else
    all_cols = TRIALS.writeparams;
end

%Then, restrict the cell array of all possible trials to include only those
%parameters (columns) that are roved, and convert to a matrix
col_ind = ismember(all_cols,filter_cols);
all_trials = all_trials(:,col_ind);
all_trials = cell2mat(all_trials);

%For each roved column of the filter list
for i = 1:numel(filter_cols)
    
    %If the column contains strings
    if iscellstr(filterdata(:,i))
        
        %Find the rows that contain GOs or NOGOs and  Expected (Yes)
        %or Unexpected (No)valsconvert to numerics
        Goind = ismember(filterdata(:,i),'GO');
        Nogoind = ismember(filterdata(:,i),'NOGO');
        Yesind = ismember(filterdata(:,i),'Yes');
        Noind = ismember(filterdata(:,i),'No');
        
        %Convert to numerics.
        filterdata(Goind,i) = {0};
        filterdata(Nogoind,i) = {1};
        filterdata(Yesind,i) = {1};
        filterdata(Noind,i) = {0};
    end
    
end

%Next, pull out just the trials that were selected by the user
selected_col = find(strcmpi(filter_cols,'Present'));
selected_rows = strcmpi(filterdata(:,selected_col),'true');
selected_data = filterdata(selected_rows,:);
selected_data(:,selected_col) = []; %(Remove the logical column)
selected_data = cell2mat(selected_data);

%Now, define the row indices for all valid possible trials
trial_indices = find(ismember(all_trials,selected_data,'rows'));

%Remove the reminder index from this array
trial_indices(trial_indices == remind_row) = [];


%Separate valid indices for GO and NOGO trials,
gos = find([TRIALS.trials{trial_indices,trial_type_ind}]' == 0);
go_indices = trial_indices(gos);

nogos = find([TRIALS.trials{trial_indices,trial_type_ind}]' == 1);
nogo_indices = trial_indices(nogos);


%Separate valid indices for expected and unexpected trials (GOs only)
expected = find([TRIALS.trials{go_indices,expected_ind}]' == 1);
expect_indices = go_indices(expected);

unexpected = find([TRIALS.trials{go_indices,expected_ind}]' == 0);
unexpect_indices = go_indices(unexpected);

%Determine whether repeat if FA checkbox is activated
repeat_checkbox = GUI_HANDLES.RepeatNOGO.Value;

%Define Go probability
Go_prob_ind =  GUI_HANDLES.go_prob.Value;
Go_prob = str2num(GUI_HANDLES.go_prob.String{Go_prob_ind});

%Define limit for consecutive nogos
Nogo_lim_ind  =  GUI_HANDLES.Nogo_lim.Value;
Nogo_lim = str2num(GUI_HANDLES.Nogo_lim.String{Nogo_lim_ind});

%Define probability of expected trials
Expected_prob_ind = GUI_HANDLES.expected_prob.Value;
Expected_prob = str2num(GUI_HANDLES.expected_prob.String{Expected_prob_ind});








