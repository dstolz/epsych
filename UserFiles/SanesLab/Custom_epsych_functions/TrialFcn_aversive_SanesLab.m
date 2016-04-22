function NextTrialID = TrialFcn_aversive_SanesLab(TRIALS)
% NextTrialID = TrialFcn_PureToneDetection_MasterHelper(TRIALS)
%
% This is a custom epsych function for the Sanes Lab for use with
% aversive GO-NOGO tasks.
%
% NextTrialID is the index of a row in TRIALS.trials. This row contains all
% of the information for the next trial.
%
% Updated by ML Caras Apr 20 2016
%warning('off','MATLAB:hg:uicontrol:ParameterValuesMustBeValid');

global RUNTIME USERDATA ROVED_PARAMS GUI_HANDLES PUMPHANDLE
global CONSEC_NOGOS 
persistent LastTrialID


%Seed the random number generator based on the current time so that we
%don't end up with the same sequence of trials each session
rng('shuffle');


%Find reminder column and row
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



%If it's the very start of the experiment...
if TRIALS.TrialIndex == 1
    
    %Start fresh
    USERDATA = [];
    ROVED_PARAMS = [];
    CONSEC_NOGOS = [];
    LastTrialID = [];

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

    roved_inds = unique(roved_inds);
    sel = roved_inds == 1;
    if( sum(sel) == 0 )
        roved_inds = [1;roved_inds];
    end
    
    %Pull out the names of the roved parameters
    ROVED_PARAMS = TRIALS.writeparams(roved_inds);
    
    %Initialize consecutive nogo flag to zero
    CONSEC_NOGOS = 0;
end


%Find the column index for Trial Type
if RUNTIME.UseOpenEx
    trial_type_ind = find(ismember(TRIALS.writeparams,'Behavior.TrialType'));
else
    trial_type_ind = find(ismember(TRIALS.writeparams,'TrialType'));
end


%-----------------------------------------------------------------
%%%%%%%%%%%%%%%%% TRIAL SELECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-----------------------------------------------------------------


%Probabilistic delivery
try
    %Get indices for different trials and determine some probabilities
    [go_indices,nogo_indices] = getIndices(TRIALS,remind_row,trial_type_ind);
    
    %Determine our NOGOlimit (drawn from a uniform distribution)
    if ~isempty(GUI_HANDLES)
    lowerbound =  str2num(GUI_HANDLES.Nogo_min.String{GUI_HANDLES.Nogo_min.Value});
    upperbound =  str2num(GUI_HANDLES.Nogo_lim.String{GUI_HANDLES.Nogo_lim.Value});
    Nogo_lim = randi([lowerbound upperbound],1);
    else
        Nogo_lim = randi([3 5],1); %default
    end
    
    
    %Always make our initial pick a NOGO (1)
    initial_random_pick = 1;
    
    %-----------------------------------------------------------------
    %Special case overrides
    %-----------------------------------------------------------------
    
    %Override initial pick and force a GO trial
    %if we've reached our consecutive nogo limit
    if CONSEC_NOGOS >= Nogo_lim
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
            NextTrialID = go_indices;
    end
    
    
    
    %If multiple indices are valid (i.e. there are two GO
    %indices, for instance), then we need to know the desired trial order
    if ~isempty(GUI_HANDLES) && numel(NextTrialID) > 1
        
        switch GUI_HANDLES.trial_order
            
            case 'Shuffled'
                r = randi(numel(NextTrialID),1);
                NextTrialID = NextTrialID(r);
                
            case 'Ascending'
                
                %If this is the first GO trial, or we've cycled through all
                %trials, start from the beginning
                if isempty(LastTrialID) || LastTrialID == NextTrialID(end)
                    NextTrialID = NextTrialID(1);
                 
                %Otherwise, present the next GO trial
                elseif LastTrialID < NextTrialID(end)
                    ind =  find(NextTrialID == LastTrialID) + 1;
                    NextTrialID = NextTrialID(ind);
                    
                end

                
            case 'Descending'
                
                %If this is the first GO trial, or we've cycled through all
                %trials, start from the beginning
                if isempty(LastTrialID) || LastTrialID == NextTrialID(1)
                    NextTrialID = NextTrialID(end);
                    
                elseif LastTrialID > NextTrialID(1)
                    ind =  find(NextTrialID == LastTrialID) - 1;
                    NextTrialID = NextTrialID(ind);
                end
                
        end
        
    %Update last trial ID
    LastTrialID = NextTrialID;
        
    end
    
    
    %--------------------------------------------------------------------
    %Reminder Override
    %--------------------------------------------------------------------
    %Override initial pick and force a reminder trial if the remind buttom
    %was pressed by the end user
    if ~isempty(GUI_HANDLES)
        if GUI_HANDLES.remind == 1;
            NextTrialID = remind_row;
            GUI_HANDLES.remind = 0;
        end
    end
    %--------------------------------------------------------------------
    

    
    
    
    
catch
    disp('Help!')
    keyboard
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
%-------------------------------------------------------------------
function [go_indices,nogo_indices] = getIndices(TRIALS,remind_row,trial_type_ind)

global GUI_HANDLES RUNTIME

if ~isempty(GUI_HANDLES)
    %First, identify the filter list from the GUI
    filterdata = GUI_HANDLES.trial_filter.Data;
    filter_cols = GUI_HANDLES.trial_filter.ColumnName';
end

%Next, identify all possible trials from the TRIALS structure
all_trials = TRIALS.trials;

if RUNTIME.UseOpenEx
    all_cols = cellfun(@(x) x(10:end), TRIALS.writeparams, 'UniformOutput',false);
else
    all_cols = TRIALS.writeparams;
end

%Then, restrict the cell array of all possible trials to include only those
%parameters (columns) that are roved, and convert to a matrix
if ~isempty(GUI_HANDLES)
    col_ind = ismember(all_cols,filter_cols);
    all_trials = all_trials(:,col_ind);
    all_trials = cell2mat(all_trials);
    
    %For each roved column of the filter list
    for i = 1:numel(filter_cols)
        
        %If the column contains strings
        if iscellstr(filterdata(:,i))
            
            %Find the rows that contain GOs or NOGOs
            Goind = ismember(filterdata(:,i),'GO');
            Nogoind = ismember(filterdata(:,i),'NOGO');
            
            %Convert to numerics.
            filterdata(Goind,i) = {0};
            filterdata(Nogoind,i) = {1};
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
    
else
    go_indices = find([TRIALS.trials{:,trial_type_ind}]' == 0);
    nogo_indices = find([TRIALS.trials{:,trial_type_ind}]' == 1);
   
end









