function [go_indices,nogo_indices,varargout] = ...
    getIndices_SanesLab(TRIALS,remind_row,trial_type_ind,varargin)
%Custom function for SanesLab epsych
%
%This function will update valid trial options based on the user's
%selections in the GUI
%
%Inputs:
%   TRIALS structure
%   remind_row: index of the reminder trial row
%   trial_type_ind: index of the trial type column
%
%   varargin{1}: index of the "expected" trial row
%
%
%Outputs: 
%   go_indices: row indices of the go trial types
%   nogo_indices: row indices of the nogo trial types
%
%
%   varargout{1}: repeat_checkbox
%   varargout{2}: Go probability
%   varargout{3}: Nogo_lim
%   varargout{4}: expected indices
%   varargout{5}: unexpected indices   
%   varargout{6}: Expected probability
%
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

h = findModuleIndex_SanesLab('RZ6',[]);
strstart = length(h.module)+2;

if RUNTIME.UseOpenEx
    all_cols = cellfun(@(x) x(strstart:end), TRIALS.writeparams, 'UniformOutput',false);
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
        
            
            %Special case: expected values
            if nargin>3
                if iscellstr(filterdata(:,i))
                    Yesind = ismember(filterdata(:,i),'Yes');
                    Noind = ismember(filterdata(:,i),'No');
                    filterdata(Yesind,i) = {1};
                    filterdata(Noind,i) = {0};
                end
            end
            
            
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
    

    if nargout >2
        %Determine whether repeat if FA checkbox is activated
        varargout{1} = GUI_HANDLES.RepeatNOGO.Value;
        
        if nargout >3
            %Define Go probability
            Go_prob_ind =  GUI_HANDLES.go_prob.Value;
            varargout{2} = str2num(GUI_HANDLES.go_prob.String{Go_prob_ind});
            
            if nargout>4
                %Define limit for consecutive nogos
                Nogo_lim_ind  =  GUI_HANDLES.Nogo_lim.Value;
                varargout{3} = str2num(GUI_HANDLES.Nogo_lim.String{Nogo_lim_ind});
            end
            
        end
        
    end
    
    
    %Special case: expected vs. unexpected trial types
    if nargin >3 
        
        expected = find([TRIALS.trials{go_indices,varargin{1}}]' == 1);
        varargout{4} = go_indices(expected); %expected indices
        
        unexpected = find([TRIALS.trials{go_indices,varargin{1}}]' == 0);
        varargout{5} = go_indices(unexpected); %#ok<*FNDSB> %unexpected indices
        
        %Define probability of expected trials
        Expected_prob_ind = GUI_HANDLES.expected_prob.Value;
        varargout{6} = str2num(GUI_HANDLES.expected_prob.String{Expected_prob_ind});
        
    end
    
    
    
    
    
else
    go_indices = find([TRIALS.trials{:,trial_type_ind}]' == 0);
    nogo_indices = find([TRIALS.trials{:,trial_type_ind}]' == 1);
   
end