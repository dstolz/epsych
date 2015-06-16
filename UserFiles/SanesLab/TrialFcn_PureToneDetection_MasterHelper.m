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

%Find reminder column and row
if RUNTIME.UseOpenEx
    remind_col = find(ismember(TRIALS.readparams,'Behavior.Reminder'));
else
    remind_col = find(ismember(TRIALS.readparams,'Reminder'));
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
    ROVED_PARAMS = TRIALS.readparams(roved_inds);
end


%Find the column indices that defines the trial type (GO or NOGO)
if RUNTIME.UseOpenEx
    trial_type_ind = find(ismember(TRIALS.writeparams,'Behavior.TrialType'));
else
    trial_type_ind = find(ismember(TRIALS.writeparams,'TrialType'));
end

%-------------DUMMY VARIABLES IN PLACE RIGHT NOW ---------------------%

NextTrialID = 5;

% %Automatically set the first 10 trials to be reminder trials.  
% if TRIALS.TrialIndex == 1
% 
%    NextTrialID = remind_row;
%    
% %After the 10th trial, switch to a probabilistic delivery.
% %Go trials = 0; Nogo trials = 1;
% else
%     
%     %Define go probability
%     Go_prob_ind =  GUI_HANDLES.go_prob.Value;
%     Go_prob = str2num(GUI_HANDLES.go_prob.String{Go_prob_ind});
%     
%     %Define limit for consecutive nogos
%     Nogo_lim_ind  =  GUI_HANDLES.Nogo_lim.Value;
%     Nogo_lim = str2num(GUI_HANDLES.Nogo_lim.String{Nogo_lim_ind});
%     
%     %Define probability of expected trials
%     Expected_prob_ind = GUI_HANDLES.expected_prob.Value;
%     Expected_prob = str2num(GUI_HANDLES.expected_prob.String{Expected_prob_ind});
%     
%     %Define selected trials
%     filter_ind = find(strcmpi(GUI_HANDLES.trial_filter(:,end),'true'));
%     filtered_trials = GUI_HANDLES.trial_filter(filter_ind,1:end-1);
% 
%     NextTrialID = 1;
%   
% end
%-------------DUMMY VARIABLES IN PLACE RIGHT NOW ---------------------%


%Determine the next trial type
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













