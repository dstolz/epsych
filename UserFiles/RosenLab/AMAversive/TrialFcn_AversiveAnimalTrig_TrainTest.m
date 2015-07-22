function NextTrialID = TrialFcn_AversiveAnimalTrig_TrainTest(TRIALS)
% NextTrialID = TrialFcn_AversiveAnimalTrig_TrainTest(TRIALS)
% 
% June 2015 RosenLab
% This is a modified trialfcn designed to run with FwdMask_AnimalTrig_ExpReady.prot
%  It uses the custom boxfig GUI CondAversiveGUI.m, which has buttons to
%  specify whether you're running a critter in one of three modes:
%  Spout Train, Train with Varying Tone Duration, or Test with Varying Tone Level.
% 
% 
% NextTrialID is the next schedule index, that is the row selected 
%  from the TRIALS.trials matrix
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

global traintype tonedur tonelev RUNTIME AX RandNoGos

%disp(traintype)
%keyboard

%Establish some persistent variables
persistent CountNoGos GoTrialRow TrackGoTrials min_nogos max_nogos ttind
% RandNoGos used to be persistent; making it global to pass into GUI function


try

%If it's the first trial...
if TRIALS.TrialIndex == 1
   
   %Initialize the pump with inner diameter of syringe and water rate in ml/min
   TrialFcn_PumpControl_ROSEN(14.5,0.3); % 14.5 mm ID (estimate); 0.3 ml/min water rate
    
   %Find the column indices that define trial type (SAFE (NOGO) or WARN (GO))
   %depth_ind = ismember(TRIALS.writeparams,'Stim.AMdepth');
   if RUNTIME.UseOpenEx
       ttind = ~cellfun(@isempty,strfind(TRIALS.writeparams,'Stim.TrialType'));
   else
       ttind = ~cellfun(@isempty,strfind(TRIALS.writeparams,'TrialType'));
   end
   ttind = find(ttind,1);
   
   %Sort TRIALS.trials structure in order of descending depth
%    TRIALS.trials = sortrows(TRIALS.trials,-depth_ind);
   
   %Define the total number of GO trials
%    numGO = numel([TRIALS.trials{:,ttind}] == 0);
   
   %Select the initial number of NOGO trials to occur between the first 2
   %GO trials
   i = ~cellfun(@isempty,strfind(TRIALS.writeparams,'*MIN_NOGOS'));
   min_nogos = TRIALS.trials{1,i};
   i = ~cellfun(@isempty,strfind(TRIALS.writeparams,'*MAX_NOGOS'));
   max_nogos = TRIALS.trials{1,i};
   
   % choose the number of SAFES to be presented prior to the next WARN
   RandNoGos = randi([min_nogos,max_nogos],1); 
   
   %Set the NOGOcount to zero
   CountNoGos = 0;
   
   %Initialize the type of WARN/GO trial to zero
   GoTrialRow = 0;
   %Initialize the position of WARN/GO trials to zero
   TrackGoTrials = 1;
   
   % NextTrialID refers to the row of the TRIALS.trials matrix set up in
   % the .prot file under ep_ExperimentDesign
   NextTrialID = 6;
%    NextTrialID = 2;  % Set to 1 for Calibration
   
%    trialtype=[]; tonedur=[]; tonelev=[];
   
   fprintf('DONE prepping for first trial\n')
%    return
end


% if RUNTIME.UseOpenEx
%     licked = AX.GetTargetVal('Behave.!Licking',1);
% else
%     keyboard
%     licked = AX.GetTagVal('!Licking',1);
%     disp('licked: ',num2str(licked))
% end




% disp('I''m in the TrialFcn')



if isempty(traintype)
    traintype = 'empty';
end

switch traintype
    case 'spoutTrain'
        % Just present SAFES
%         disp('I''m in the spoutTrain case')
        NextTrialID = find([TRIALS.trials{:,ttind}]==1); % trialtype of 1 means SAFE as defined in .prot file
    case 'varydurTrain'
%         disp('I''m in the varydurTrain case')
        
        %Find the column indices that define tone duration
        %depth_ind = ismember(TRIALS.writeparams,'Stim.AMdepth');
        if RUNTIME.UseOpenEx
            ToneDurColIdx = ~cellfun(@isempty,strfind(TRIALS.writeparams,'Stim.Tone_Dur'));
        else
            ToneDurColIdx = ~cellfun(@isempty,strfind(TRIALS.writeparams,'Tone_Dur'));
        end
        % !!! This line assumes that the WARN trial you're lookin for is in the first 7 rows.
        warnidx = find([TRIALS.trials{1:7,ToneDurColIdx}]'==tonedur);
%         warnidx = 1;  % Use this line for calibration
          
        % Choose trial where the tone duration matches that in the GUI
        % VaryToneDuration textbox. Present ONLY that trial type as a WARN.
        if CountNoGos == RandNoGos % Criterion for # of NoGos (safe) prior to Go (warn) trial
            % select a WARN/GO trial
            GoTrialRow = warnidx;
            
            % choose the number of SAFES to be presented prior to the next WARN
            RandNoGos = randi([min_nogos,max_nogos],1);
            CountNoGos = 0;
            
            NextTrialID = GoTrialRow;
        else
            % select a SAFE/NOGO trial - choose row from matrix TRIALS.trials
            NextTrialID = find([TRIALS.trials{:,ttind}]==1); % trialtype of 1 means SAFE as defined in .prot file
            CountNoGos = CountNoGos + 1;
        end
        
    case 'varylevTest'
%         disp('I''m in the varylevTest case')
        
        %Find the column indices that define tone level
        %depth_ind = ismember(TRIALS.writeparams,'Stim.AMdepth');
        if RUNTIME.UseOpenEx
            ToneLevColIdx = ~cellfun(@isempty,strfind(TRIALS.writeparams,'Stim.Tone_dBSPL'));
        else
            ToneLevColIdx = ~cellfun(@isempty,strfind(TRIALS.writeparams,'Tone_dBSPL'));
        end
        
        % create a warnidx vector of levels in descending order
        [tonelevdesc, tonelevdescidx] = sort(tonelev,'descend');
        for d = 1:size(tonelevdesc,1)
             % !!! Assumes that the WARN trial you want is in rows 8 thru 19.
            warnidx(d) = find([TRIALS.trials{8:19,ToneLevColIdx}]'==tonelevdesc(d)) + 7; % +7 because we're looking in rows 8 thru 19
        end
        
        % Step through chosen trials (in GUI ToneLev_listbox) in descending order (from easier/louder to harder/quieter)
        % In that order, present each of those trial types as a WARN.
        if CountNoGos == RandNoGos % Criterion for # of NoGos (safe) prior to Go (warn) trial
            % select a WARN/GO trial
            GoTrialRow = warnidx(TrackGoTrials);
            NextTrialID = GoTrialRow;
            
            if TrackGoTrials >= size(warnidx,2), TrackGoTrials = 0; end
            
            TrackGoTrials = TrackGoTrials + 1;
            CountNoGos = 0;
            % Choose a random # of SAFES for the next interval
            RandNoGos = randi([min_nogos,max_nogos],1);
            
%         % !!! Assumes that the WARN trial you want is in rows 8 thru 19.
%         warnidx = find([TRIALS.trials{8:19,ToneLevColIdx}]'==tonelev) + 7; % !!! +7 because we're looking in rows 8 thru 19

        % Choose trial where the tone level matches that in the GUI
        % VaryToneDuration textbox. Present ONLY that trial type as a WARN.
%             % select a WARN/GO trial
%             GoTrialRow = warnidx;
%             
%             % choose the number of SAFES to be presented prior to the next WARN
%             RandNoGos = randi([min_nogos,max_nogos],1);
%             CountNoGos = 0;
%             
%             NextTrialID = GoTrialRow;
        else
            % select a SAFE/NOGO trial - choose row from matrix TRIALS.trials
            NextTrialID = find([TRIALS.trials{:,ttind}]==1); % trialtype of 1 means SAFE as defined in .prot file
            CountNoGos = CountNoGos + 1;
        end
        
    otherwise
        %Step through WARN trials in order of their entry
        if CountNoGos == RandNoGos % Criterion for # of NoGos (safe) prior to Go (warn) trial
            % select a WARN/GO trial
            GoTrialRow = GoTrialRow + 1;
            
            % choose the number of SAFES to be presented prior to the next WARN
            RandNoGos = randi([min_nogos,max_nogos],1);
            CountNoGos = 0;
            
            if GoTrialRow > 6, GoTrialRow = 1; end
            
            NextTrialID = GoTrialRow;
        else
            %keyboard
            % select a SAFE/NOGO trial - choose row from matrix TRIALS.trials
            NextTrialID = find([TRIALS.trials{:,ttind}]==1); % trialtype of 1 means SAFE as defined in .prot file
            CountNoGos = CountNoGos + 1;
        end

end




% fprintf('# %d\tNext Trial\n',TRIALS.TrialIndex)
% TRIALS.trials(NextTrialID,:)




catch
    
   disp('DOH!!!') 
end








