function RUNTIME = ep_TimerFcn_RunTime_SanesLab(RUNTIME, AX)
% RUNTIME = ep_TimerFcn_RunTime_SanesLab(RUNTIME, RP)
% RUNTIME = ep_TimerFcn_RunTime_SanesLab(RUNTIME, DA)
% 
% SanesLab RunTime timer function
% 
% Daniel.Stolzberg@gmail.com 2014. Updated by ML Caras 2015

global GUI_HANDLES

for i = 1:RUNTIME.NSubjects
    
    % Check #RespCode parameter for non-zero value or if #TrigState is true
    if RUNTIME.UseOpenEx
        RCtag = AX.GetTargetVal(RUNTIME.RespCodeStr{i});
        TStag = AX.GetTargetVal(RUNTIME.TrigStateStr{i});
    else
        RCtag = AX(RUNTIME.RespCodeIdx(i)).GetTagVal(RUNTIME.RespCodeStr{i});
        TStag = AX(RUNTIME.TrigStateIdx(i)).GetTagVal(RUNTIME.TrigStateStr{i});
    end
    
    if ~RCtag || TStag, continue; end
  
    
    if RUNTIME.UseOpenEx
        TrialNum = AX.GetTargetVal(RUNTIME.TrialNumStr{i}) - 1;
    else
        TrialNum = AX(RUNTIME.TrialNumIdx(i)).GetTagVal(RUNTIME.TrialNumStr{i}) - 1;
    end
    
    % There was a response and the trial is over.
    % Retrieve parameter data from RPvds circuits
    data = feval(sprintf('Read%sTags',RUNTIME.TYPE),AX,RUNTIME.TRIALS(i));
    data.Freq = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'Freq'); %Hz
    data.dBSPL = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'dBSPL'); 
    data.Expected = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'Expected'); %Logical
    data.MinPokeDur = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'MinPokeDur'); %msec
    data.RespWinDelay = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'RespWinDelay'); %msec
    data.RespWinDur = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'RespWinDur'); %msec
    data.Silent_delay = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'Silent_delay'); %msec
    data.to_duration = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'to_duration'); %msec
    data.fs =  AX.GetSFreq; %Samples/sec
    data.FMdepth = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'FMdepth'); %percent
    data.FMrate = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'FMrate'); %Hz
    
    Stim_Duration = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'Stim_Duration'); %samples
    data.Stim_Duration = Stim_Duration/data.fs; %msec
    
    
    %Append response, trial and timing information to data structure
    data.ResponseCode = RCtag;
    data.TrialID = TrialNum;
    data.ComputerTimestamp = clock;
   
    %Append information from GUI into data structure
    if ~isempty(GUI_HANDLES)
        data.Go_prob = getval(GUI_HANDLES.go_prob);
        data.NogoLim = getval(GUI_HANDLES.Nogo_lim);
        data.Expected_prob = getval(GUI_HANDLES.expected_prob);
        data.RepeatNOGOcheckbox = GUI_HANDLES.RepeatNOGO.Value;
        data.RewardVol = GUI_HANDLES.vol; %ml
        data.PumpRate = GUI_HANDLES.rate; %ml/min
    end
    
    %Make sure fields of structure are in the same order
    ordereddata = orderfields(data,RUNTIME.TRIALS(i).DATA(1));
    
    %Append data to runtime structure
    RUNTIME.TRIALS(i).DATA(RUNTIME.TRIALS(i).TrialIndex) = ordereddata;
    
    
    % Save runtime data in case of crash
    data = RUNTIME.TRIALS(i).DATA;  %#ok<NASGU>
    save(RUNTIME.DataFile{i},'data','-append','-v6'); % -v6 is much faster because it doesn't use compression  


   %Increment trial index
   RUNTIME.TRIALS(i).TrialIndex = RUNTIME.TRIALS(i).TrialIndex + 1;
    
    
    % Select next trial with default or custom function
    try
        n = feval(RUNTIME.TRIALS(i).trialfunc,RUNTIME.TRIALS(i));
        if isstruct(n)
            RUNTIME.TRIALS(i).trials = n.trials;
            RUNTIME.TRIALS(i).NextTrialID = n.NextTrialID;
        elseif isscalar(n)
            RUNTIME.TRIALS(i).NextTrialID = n;
        else
            error('Invalid output from custom trial selection function ''%s''',RUNTIME.TRIALS(i).trialfunc)
        end
    catch me
        errordlg('Error in Custom Trial Selection Function');
        rethrow(me)
    end
    
    
    
    % Increment TRIALS.TrialCount for the selected trial index
    RUNTIME.TRIALS(i).TrialCount(RUNTIME.TRIALS(i).NextTrialID) = ...
        RUNTIME.TRIALS(i).TrialCount(RUNTIME.TRIALS(i).NextTrialID) + 1;

    
    % Send trigger to reset components before updating parameters
    if RUNTIME.UseOpenEx
        TrigDATrial(AX,RUNTIME.ResetTrigStr{i});
    else
        TrigRPTrial(AX(RUNTIME.ResetTrigIdx(i)),RUNTIME.ResetTrigStr{i});
    end
    
    
    % Update parameters for next trial
    feval(sprintf('Update%stags',RUNTIME.TYPE),AX,RUNTIME.TRIALS(i));   

    
    % Send trigger to indicate ready for a new trial
    if RUNTIME.UseOpenEx
        TrigDATrial(AX,RUNTIME.NewTrialStr{i});
    else
        TrigRPTrial(AX(RUNTIME.NewTrialIdx(i)),RUNTIME.NewTrialStr{i});
    end

end




function val = getval(s)

ind =  s.Value;
val = str2num(s.String{ind});









