function NextTrialID = TrialFcn_PureToneDetection_MasterHelper(TRIALS)
% NextTrialID = TrialFcn_PureToneDetection_MasterHelper(TRIALS)
% 
% This is default function for selecting the next trial in the pure tone
% detection task. 
%   
% NextTrialID is the next schedule index, that is the row selected 
%             from the TRIALS.trials matrix
% 
% 
% Custom trial selection functions can be written to add more complex,
% dynamic programming to the behavior paradigm.  For example, a custom
% trial selection function can be used to create an adaptive threshold
% tracking paradigm to efficiently track audibility of tones across sound
% level.
% 
% The goal of any trial selection function is to return an integer pointing
% to a row in the TRIALS.trials matrix which is generated using the
% ep_ExperimentDesign GUI (or by some other method).
% 
% The function must have the same call syntax as this default function. 
%       ex:
%           function NextTrialID = MyCustomFunction(TRIALS)
% 
% TRIALS is a structure which has many subfields used during an experiment.
% Below are some important subfields:
% 
% TRIALS.TrialIndex  ... Keeps track of each completed trial
% TRIALS.trials      ... A cell matrix in which each column is a different
%                        parameter and each row is a unique set of
%                        parameters (called a "trial")
% TRIALS.readparams  ... Parameter tag names for reading values from a
%                        running TDT circuit. The position of the parameter
%                        tag name in this array is the same as the position
%                        of its corresponding parameters (column) in
%                        TRRIALS.trials.
% TRIALS.writeparams ... Parameter tag names writing values from a
%                        running TDT circuit. The position of the parameter
%                        tag name in this array is the same as the position
%                        of its corresponding parameters (column) in
%                        TRIALS.trials.
% 
% See also, SelectTrial
% 
% Daniel.Stolzberg@gmail.com 2014
global USERDATA RUNTIME


%Establish some variables
%Go trials = 0; Nogo trials = 1;
Go_prob = 0.5; %need to soft code

Trial_distribution = ones(1,10);
Trial_distribution(1:Go_prob*10) = 0;


%Find the column indices that defines the trial type
if RUNTIME.UseOpenEx
    trial_type_ind = ismember(TRIALS.writeparams,'Behavior.TrialType');
else
    trial_type_ind = ismember(TRIALS.writeparams,'TrialType');
end

%Find the column indices that defines the trial type
%delay_ind = ismember(TRIALS.writeparams,'Behavior.Silent_delay');

%If it's the start of the experiment
if TRIALS.TrialIndex == 1
   
   %Initialize the pump 
   TrialFcn_PumpControl

   %Select a go trial for the first trial
   g = find([TRIALS.trials{:,trial_type_ind}]== 0);
   NextTrialID = g(randi(length(g),1));
   
    fprintf('DONE\n')
    return
    
%If it's a later trial...    
elseif TRIALS.TrialIndex > 1
    
    %Randomly select a go or nogo (using the go probability hard coded)
    r = randi(10,1);
    Next_trial_type = Trial_distribution(r);
    g = find([TRIALS.trials{:,trial_type_ind}]== Next_trial_type);
    NextTrialID = g(randi(length(g),1));

end

USERDATA.TrialType = Next_trial_type;

if RUNTIME.UseOpenEx
    i = ismember(TRIALS.writeparams,'Behavior.Silent_delay');
else
    i = ismember(TRIALS.writeparams,'Silent_delay');
end

USERDATA.SilentDelay = TRIALS.trials{NextTrialID,i};














