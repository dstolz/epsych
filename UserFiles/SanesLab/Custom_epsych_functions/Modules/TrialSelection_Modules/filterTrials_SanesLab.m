function [hObject,handles] = filterTrials_SanesLab(hObject, eventdata, handles)
%[hObject,handles] = filterTrials_SanesLab(hObject, eventdata, handles)
%
%Custom function for SanesLab epsych
%
%This function allows the user to select or deselect trials for delivery.
%at least one GO and one NOGO trial must always be selected for delivery.
%
%Input:
%   hObject: handle to the GUI trial selection table
%   eventdata: structure containing indices for the selected table cell
%   handles: GUI handles structure
%
%Updated by ML Caras 8.17.2016

global TRIAL_STATUS


%Only proceed if an event occurred
if isempty(eventdata.Indices)
    return
end


%Get the row and column of the selected or de-selected checkbox
r = eventdata.Indices(1);
c = eventdata.Indices(2);


%Identify some important columns
col_names = get(hObject,'ColumnName');
trial_type_col = find(ismember(col_names,'TrialType'));
logical_col = find(ismember(col_names,'Present'));

%Only proceed if the cell clicked on was in a logical column
if c ~= logical_col
    return
end

%Determine the data we currently have active
table_data = get(hObject,'Data');
active_ind = (strfind(table_data(:,c),'false'));
active_ind = cellfun('isempty',active_ind);
active_data = table_data(active_ind,:);


%Define the starting state of the check box
starting_state = table_data{r,c};

switch starting_state
    
    %If the box started out as checked...
    case 'true'
        
        %Prevent the only NOGO from being de-selected
        [NOGO_row_active,NOGO_row] = prevent_select(active_data,table_data,...
            trial_type_col,'NOGO');
        
        %Prevent the only GO from being de-selected
        [~,GO_row] = prevent_select(active_data,table_data,...
            trial_type_col,'GO');
        
        
        %Prevent the only expected and the only unexpected GO value from
        %being deselected
        [expected_row,unexpected_row] = ...
            prevent_expected(col_names,active_data,table_data,NOGO_row_active);
        
        
    %If the box started out as unchecked, it's always okay to check it
    otherwise
        NOGO_row = 0;
        GO_row = 0;
        expected_row = 0; %Special case
        unexpected_row = 0; %Special case
end


%If the selected/de-selected row matches one of the special cases,
%present a warning to the user and don't alter the trial selection
switch r
    case [NOGO_row, GO_row, expected_row, unexpected_row]
        
        beep
        warnstring = ['The following trial types cannot be deselected:'...
            '(a) The only GO trial  (b) The only NOGO trial '...
            '(c) The only expected GO trial'...
            '(d) The only unexpected GO trial '];
        warnhandle = warndlg(warnstring,'Trial selection warning'); %#ok<*NASGU>
        
        
    %If it's okay to select or de-select the checkbox, then proceed
    otherwise
        
        
        switch starting_state
            
            %If the box started as checked, uncheck it
            case 'true'
                table_data(r,c) = {'false'};
                
            %If the box started as unchecked, check it
            otherwise
                table_data(r,c) = {'true'};
        end
        
        
        %When checking or unchecking boxes, the uitable scrollbar automatically
        %resets to the top of the table.  This default feature can be annoying when
        %dealing with a long list of variables to check or uncheck. This
        %is an undocumented and unsupported workaround using java controls. 
        

        %Execute all subsequent calls on EDT, rather than MATLAB thread
        %(unclear if this is truly necessary here)
        javaObjectEDT(handles.jScrollPane);
        
        %Save current scrollbar position
        currentViewPos = handles.jScrollPane.getViewPosition;

        %Update the GUI object
        set(hObject,'Data',table_data);
        set(hObject,'ForegroundColor',[1 0 0]);
        
        %Render graphic now
        drawnow; 
        
        %Reset the scroll bar to original position
        handles.jScrollPane.setViewPosition(currentViewPos);
        
        %Enable apply button
        set(handles.apply,'enable','on');
end


%Update trial status
TRIAL_STATUS = 1; %Indicates user has made changes to trial filter


%Update guidata
guidata(hObject,handles)



%FUNCTION TO FIND ROW INDICES FOR GO AND NOGO TRIALS
function [active_row,row] = prevent_select(active_data,table_data,...
    col,trialtype)

%Find the rows of currently active trials, that contain the trial type of interest
active_row = find(ismember(active_data(:,col),trialtype));

%If there are more than one of these rows (i.e. there are at least 2 GO or
%NOGO trials active)
if numel(active_row) > 1
    
    %Then set the row index to 0
    row = 0;

%If there is only one of these rows (i.e. there is only a single GO or NOGO
%trial active)
else
    
    %Identify the row
    row = find(ismember(table_data(:,col),trialtype));
    row = num2cell(row');
end
        
        
%FUNCTION TO FIND ROW INDICES FOR EXPECTED AND UNEXPECTED TRIALS
function [expected_row,unexpected_row] = ...
    prevent_expected(col_names,active_data,table_data,NOGO_row_active)

%Find the index of the "expected" column
expected_col = find(ismember(col_names,'Expected')); %Special case

%Abort if expected column is empty
if isempty(expected_col)
    expected_row = 0;
    unexpected_row = 0;
    return
end


%Prevent the only expected GO value from being deselected
expected_row = find(ismember(active_data(:,expected_col),'Yes'));
expected_row(expected_row == NOGO_row_active) = [];

if numel(expected_row)<= 1
    expected_row = find(ismember(table_data(:,expected_col),'Yes'));
    expected_row = num2cell(expected_row');
end


%Prevent the only unexpected GO value from being deselected
unexpected_row = find(ismember(active_data(:,expected_col),'No'));
if numel(unexpected_row)<=1
    unexpected_row = find(ismember(table_data(:,expected_col),'No'));
    unexpected_row = num2cell(unexpected_row');
end



