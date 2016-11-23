function findRovedPARAMS_SanesLab(TRIALS,remind_row)
%findRovedPARAMS_SanesLab(TRIALS,remind_row)
%
%Custom function for SanesLab epsych
%
%This function identifies the indices of the roved parameters
%
%Inputs: 
%   TRIALS: RUNTIME.TRIALS structure 
%   remind_row: row index in TRIALS.trials of the reminder trial
%
%No outputs are returned, but global Variables 
%ROVED_PARAMS and CONSEC_NOGOS are updated
%
%Written by ML Caras 7.22.2016.
%Updated by KP 11.4.2016. (param WAV/MAT compatibility)

global ROVED_PARAMS CONSEC_NOGOS CURRENT_FA_STATUS CURRENT_EXPEC_STATUS

trials = TRIALS.trials;
trials(remind_row,:) = [];

%Set up an empty matrix for the roved parameter indices
roved_inds = [];

%Identify columns in the trial matrix that contain parameters that we
%want to ignore (i.e. ~Freq.Amp and ~Freq.Norm values for calibrations)
ignore = find(~cellfun(@isempty,strfind(TRIALS.writeparams,'~')));

%Keep column that is the FileID number for a param corresponding to a
%datatype of WAV or MAT
keep = find(~cellfun(@isempty,strfind(TRIALS.writeparams,'_ID')));  %kp
if ~isempty(keep),  ignore(ignore==keep)=[];  end


%For each column (parameter)...
for i = 1:size(trials,2)
    
    %Find the number of unique variables, ignoring struct data params
    if isstruct([trials{:,i}])                  %kp
        num_param = 1;
    else
        num_param = numel(unique([trials{:,i}]));
    end
    
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

%These lines of code added by Justin for Same-Different task. Still needs 
%to be tested and conditionalized.
% % % roved_inds = unique(roved_inds);
% % % sel = roved_inds == 1;
% % % if( sum(sel) == 0 )
% % %     roved_inds = [1;roved_inds];
% % % end

%Pull out the names of the roved parameters
ROVED_PARAMS = TRIALS.writeparams(roved_inds);

%Initialize flags to zero
CONSEC_NOGOS = 0;
CURRENT_FA_STATUS = 0;
CURRENT_EXPEC_STATUS = 0;