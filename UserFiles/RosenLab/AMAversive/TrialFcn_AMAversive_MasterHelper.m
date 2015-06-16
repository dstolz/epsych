function NextTrialID = TrialFcn_AMAversive_MasterHelper(TRIALS)
% NextTrialID = TrialFcn_PumpControl(TRIALS)
% 
% This is the default function for selecting the next trial and can be
% overridden by specifying a custom function name in ep_ExperimentDesign.
% The code in this function serves as a good template for custom trial
% selection functions.
%   
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


%Establish some persistent variables
persistent RandNoGos CountNoGos TrackGoTrials

%If it's the first trial...
if TRIALS.TrialIndex == 1
   
   %Initialize the pump 
   TrialFcn_AMAversive_PumpControl
    
   %Find the column indices that define AM Depth and trial type
   depth_ind = ismember(TRIALS.writeparams,'Stim.AMdepth');
   ttind = ismember(TRIALS.writeparams,'Stim.TrialType');
   
   %Sort TRIALS.trials structure in order of descending depth
   TRIALS.trials = sortrows(TRIALS.trials,-depth_ind);
   
   %Define the total number of GO trials
   numGO = numel(TRIALS.trials(:,ttind) == 0);
   
   %Select the initial number of NOGO trials to occur between the first 2
   %GO trials
   RandNoGos = randi([3,5],1);
   
   %Set the NOGOcount to zero
   CountNoGos = 0;
   
   %Set the GO count zero
   TrackGoTrials = 0;
    
    NextTrialID = 6;
    
    fprintf('DONE\n')
    return
end




%Currently hard coded; recode later
if CountNoGos == RandNoGos
    % select a go trial
    TrackGoTrials = TrackGoTrials + 1;
    
    RandNoGos = randi([3,5],1);
    CountNoGos = 0;
    
    if TrackGoTrials > 5, TrackGoTrials = 1; end
    
    NextTrialID = TrackGoTrials;
else
    % select a no go trial
    NextTrialID = find([TRIALS.trials{:,ttind}]==1);
    CountNoGos = CountNoGos + 1;
    
end
















