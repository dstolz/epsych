function NextTrialID = TrialFcn_PureToneDetection_MasterHelper(TRIALS)
% NextTrialID = TrialFcn_PureToneDetection_MasterHelper(TRIALS)
% 
% This is default function for selecting the next trial in the pure tone
% detection task. 
%   
% NextTrialID is the next schedule index, that is the row selected 
%             from the TRIALS.trials matrix
% 
% Updated by ML Caras Jun 15 2015

global RUNTIME USERDATA ROVED_PARAMS GUI_HANDLES
persistent consec_nogos FA_flag


%Find reminder column and row
if RUNTIME.UseOpenEx
    remind_col = find(ismember(TRIALS.writeparams,'Behavior.Reminder'));
else
    remind_col = find(ismember(TRIALS.writeparams,'Reminder'));
end

remind_row = find([TRIALS.trials{:,remind_col}] == 1);


%If it's the very start of the experiment...
if TRIALS.TrialIndex == 1
    
    %Initialize the pump
    TrialFcn_PumpControl
    
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
    
    %Set consecutive nogo count to zero
    consec_nogos = 0;
    
    %Set FA flag to zero
    FA_flag = 0;
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


%Automatically set the first 10 trials to be reminder trials.  
if TRIALS.TrialIndex < 3

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
    
    
    %Override initial pick and force a NOGOtrial if the last trial was a
    %FA, and if the "Repeat if FA" checkbox is activated
    if GUI_HANDLES.RepeatNOGO.Value == 1 &&...
            bitget(TRIALS.DATA(1,end).ResponseCode,4)
        initial_random_pick = 1;
        FA_flag = 1;
    end
    

    %Override initial pick or NOGO repeat and force a GO trial 
    %if we've reached our consecutive nogo limit
    if consec_nogos >= Nogo_lim && Go_prob > 0
        initial_random_pick = 2;
        consec_nogos = 0;
    end
    
    %Override initial pick and force a GO trial if the animal got a
    %repeated FA trial correct
    if FA_flag == 1 && bitget(TRIALS.DATA(1,end).ResponseCode,3)...
            && Go_prob > 0
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
        
        %Reset FA flag
        FA_flag = 0;
        
    %If the initial randomly picked number is 1, we picked a NOGO trial
    elseif initial_random_pick == 1
        
        NextTrialID = nogo_indices;
        consec_nogos = consec_nogos + 1;
         
        
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













