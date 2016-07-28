function [go_indices,nogo_indices] = getIndices_SanesLab(TRIALS,remind_row,trial_type_ind)
%Custom function for SanesLab epsych
%Inputs are TRIALS structure, the index of the reminder trial row, and the
%index of the trial type column.
%
%Outputs are the row indices of the go and nogo trial types
%
%This function will update valid trial options based on the user's
%selections in the GUI
%
%Written by ML Caras 7.22.2016



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