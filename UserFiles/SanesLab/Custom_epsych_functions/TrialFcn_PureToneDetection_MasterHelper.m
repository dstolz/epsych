function NextTrialID = TrialFcn_PureToneDetection_MasterHelper(TRIALS)
% NextTrialID = TrialFcn_PureToneDetection_MasterHelper(TRIALS)
% 
% This is a custom epsych function for the Sanes Lab for use with 
% appetitive GO-NOGO tasks.
%   
% NextTrialID is the index of a row in TRIALS.trials. This row contains all
% of the information for the next trial.
% 
% Updated by ML Caras Jun 15 2015

global RUNTIME USERDATA ROVED_PARAMS GUI_HANDLES PUMPHANDLE 
global CONSEC_NOGOS CURRENT_FA_STATUS 
persistent repeat_flag

%Seed the random number generator based on the current time so that we
%don't end up with the same sequence of trials each session
rng('shuffle');


%Find reminder column and row
if RUNTIME.UseOpenEx
    remind_col = find(ismember(TRIALS.writeparams,'Behavior.Reminder'));
else
    remind_col = find(ismember(TRIALS.writeparams,'Reminder'));
end

remind_row = find([TRIALS.trials{:,remind_col}] == 1);


%If it's the very start of the experiment...
if TRIALS.TrialIndex == 1
    
    %Find open serial ports (indicating pump is already initialized)
    out = instrfind('Status','open');
    
    %If all serial ports are closed, open one and initialize pump
    if isempty(out)
        PUMPHANDLE = TrialFcn_PumpControl;
    end
  
    
    %Identify all roved parameters. Note: we discard the reminder trial row
    trials = TRIALS.trials;
    trials(remind_row,:) = [];
    
    %Set up an empty matrix for the roved parameter indices
    roved_inds = [];
    
    %For each column (parameter)...
    for i = 1:size(trials,2)
        
        %Find the number of unique variables
        num_param = numel(unique([trials{:,i}]));
        
        %If there is more than one unique variable for the column
        if num_param > 1
            
            %Add that index into our roved parameter index list
            roved_inds = [roved_inds;i];
        end
        
    end
    
    %Pull out the names of the roved parameters
    ROVED_PARAMS = TRIALS.writeparams(roved_inds);
    
    %Set repeated FA flag to 0
    repeat_flag = 0;
    CONSEC_NOGOS = 0;
    CURRENT_FA_STATUS = 0;
end


%Find some column indices
if RUNTIME.UseOpenEx
    trial_type_ind = find(ismember(TRIALS.writeparams,'Behavior.TrialType'));
    expected_ind = find(ismember(TRIALS.writeparams,'Behavior.Expected'));
else
    trial_type_ind = find(ismember(TRIALS.writeparams,'TrialType'));
    expected_ind = find(ismember(TRIALS.writeparams,'Expected'));
end





%-----------------------------------------------------------------
%%%%%%%%%%%%%%%%% TRIAL SELECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------------------------------------------------


%Set the first N trials to be reminder trials. (N determined by GUI).
%Default is 5.
try
    num_reminds_ind =  GUI_HANDLES.num_reminds.Value;
    num_reminds = str2num(GUI_HANDLES.num_reminds.String{num_reminds_ind});
catch
    num_reminds = 5;
end


if TRIALS.TrialIndex <= num_reminds

   NextTrialID = remind_row;
   
%Otherwise, probabilistic delivery
else
    
    %First, define the trials and their parameters
    filterdata = GUI_HANDLES.trial_filter.Data;
    filter_cols = GUI_HANDLES.trial_filter.ColumnName';
    
    all_trials = TRIALS.trials;
    all_cols = TRIALS.writeparams;
    
    col_ind = ismember(all_cols,filter_cols);
    all_trials = all_trials(:,col_ind);
    all_cols = all_cols(col_ind);
    all_trials = cell2mat(all_trials);
    
    %Then, convert strings into numbers
    for i = 1:numel(filter_cols)
        
        if iscellstr(filterdata(:,i))
            Goind = ismember(filterdata(:,i),'GO');
            Nogoind = ismember(filterdata(:,i),'NOGO');
            Yesind = ismember(filterdata(:,i),'Yes');
            Noind = ismember(filterdata(:,i),'No');
            
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
     selected_data(:,selected_col) = [];
     selected_data = cell2mat(selected_data);
    
    
    %Now, define the row indices for all valid possible trials
    trial_indices = find(ismember(all_trials,selected_data,'rows'));
     
    %Remove the reminder indexn from this array
    trial_indices(trial_indices == remind_row) = [];
    
    %Separate valid indices for GO and NOGO trials,and expected vs.
    %unexpected trials (GOs only)
    gos = find([TRIALS.trials{trial_indices,trial_type_ind}]' == 0);
    go_indices = trial_indices(gos);
    
    expected = find([TRIALS.trials{go_indices,expected_ind}]' == 1);
    expect_indices = go_indices(expected);
    
    unexpected = find([TRIALS.trials{go_indices,expected_ind}]' == 0);
    unexpect_indices = go_indices(unexpected);
    
    nogos = find([TRIALS.trials{trial_indices,trial_type_ind}]' == 1);
    nogo_indices = trial_indices(nogos);
    
    %Define Go probability
    Go_prob_ind =  GUI_HANDLES.go_prob.Value;
    Go_prob = str2num(GUI_HANDLES.go_prob.String{Go_prob_ind});

    %Define limit for consecutive nogos
    Nogo_lim_ind  =  GUI_HANDLES.Nogo_lim.Value;
    Nogo_lim = str2num(GUI_HANDLES.Nogo_lim.String{Nogo_lim_ind});
    
    
    
    %--------------------------------------------------------------------
    %HERE IS WHERE WE PICK THE NEXT TRIAL
    %--------------------------------------------------------------------
    
    %Make our initial pick (for trial type)
    initial_random_pick = sum(rand >= cumsum([0, 1-Go_prob, Go_prob]));
    
    repeat_checkbox = GUI_HANDLES.RepeatNOGO.Value;
    
    %Override initial pick and force a NOGOtrial if the last trial was a
    %FA, and if the "Repeat if FA" checkbox is activated
    if CURRENT_FA_STATUS == 1 && repeat_checkbox == 1 
        initial_random_pick = 1;
        repeat_flag = 1;
    end
    

    %Override initial pick or NOGO repeat and force a GO trial 
    %if we've reached our consecutive nogo limit
    if CONSEC_NOGOS+1 >= Nogo_lim && Go_prob > 0
        initial_random_pick = 2;
    end
    
    %Override initial pick and force a GO trial if the animal got a
    %repeated FA trial correct
    if repeat_flag == 1 && CURRENT_FA_STATUS == 0 && Go_prob > 0
        initial_random_pick = 2;
    end
    
    
    %If the initial randomly picked number is 2, we picked a GO trial
    if initial_random_pick == 2
        
        %Define probability of expected trials
        Expected_prob_ind = GUI_HANDLES.expected_prob.Value;
        Expected_prob = str2num(GUI_HANDLES.expected_prob.String{Expected_prob_ind});
        
        next_random_pick = sum(rand >= cumsum([0, 1-Expected_prob, Expected_prob]));
        
        
        %If the next randomly picked number is 2, we picked an expected GO trial
        if next_random_pick == 2
            NextTrialID = expect_indices;
    
        %If the next randomly picked number is 1, we picked an unexpected GO trial    
        elseif next_random_pick == 1
            NextTrialID = unexpect_indices;
        end
        
        %Reset repeat NOGO flag
        repeat_flag = 0;
        
    %If the initial randomly picked number is 1, we picked a NOGO trial
    elseif initial_random_pick == 1
        NextTrialID = nogo_indices;
    end
    
    %If multiple indices are valid (i.e. there are two unexpected GO
    %values, for instance), then we randomly select one of them
    if numel(NextTrialID) > 1
        r = randi(numel(NextTrialID),1);
        NextTrialID = NextTrialID(r);
    end
    
    
    %Override initial pick and force a reminder trial if the remind buttom
    %was pressed by the end user
    if GUI_HANDLES.remind == 1;
        NextTrialID = remind_row;
        GUI_HANDLES.remind = 0;
        
        repeat_flag = 0;
    end
    
    %--------------------------------------------------------------------
    
    %--------------------------------------------------------------------
  
end


%Determine the next trial type for display
if NextTrialID == remind_row;
    Next_trial_type = 'REMIND';
elseif TRIALS.trials{NextTrialID,trial_type_ind} == 0
    Next_trial_type = 'GO';
elseif TRIALS.trials{NextTrialID,trial_type_ind} == 1;
    Next_trial_type = 'NOGO';
end



%For each roved parameter...
for i = 1:numel(ROVED_PARAMS)
    
    variable = ROVED_PARAMS{i};
    
    if strcmpi(variable,'TrialType')
        USERDATA.TrialType = Next_trial_type;
        
    elseif strcmpi(variable,'Reminder')
        if RUNTIME.UseOpenEx
            ind = find(ismember(TRIALS.writeparams,'Behavior.Reminder'));
        else
            ind = find(ismember(TRIALS.writeparams,'Reminder'));
        end
        
        USERDATA.Reminder = TRIALS.trials{NextTrialID,ind};
        
    elseif strcmpi(variable,'Expected')
        
        if RUNTIME.UseOpenEx
            ind = find(ismember(TRIALS.writeparams,'Behavior.Expected'));
        else
            ind = find(ismember(TRIALS.writeparams,'Expected'));
        end
        
        USERDATA.Expected = TRIALS.trials{NextTrialID,ind};
        
    else
        if RUNTIME.UseOpenEx
            ind = find(ismember(TRIALS.writeparams,['Behavior.',variable]));
        else
            ind = find(ismember(TRIALS.writeparams,variable));
        end
        
        %Update USERDATA
        eval(['USERDATA.' variable '= TRIALS.trials{NextTrialID,ind};'])
        
    end
    
end











