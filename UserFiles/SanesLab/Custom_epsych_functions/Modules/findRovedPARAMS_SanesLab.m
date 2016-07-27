function findRovedPARAMS_SanesLab(TRIALS,remind_row)
%Custom function for SanesLab epsych
%
%This function identifies the indices of the roved parameters
%
%Inputs are: TRIALS structure and the index of the reminder trial
%Global Variables ROVED_PARAMS and CONSEC_NOGOS are updated
%
%Written by ML Caras 7.22.2016

global ROVED_PARAMS CONSEC_NOGOS

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