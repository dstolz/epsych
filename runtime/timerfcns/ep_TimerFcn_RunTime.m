function RUNTIME = ep_TimerFcn_RunTime(RUNTIME, AX)
% RUNTIME = ep_TimerFcn_RunTime(RUNTIME, RP)
% RUNTIME = ep_TimerFcn_RunTime(RUNTIME, DA)
% 
% Default RunTime timer function
% 
% Daniel.Stolzberg@gmail.com 2014



for i = 1:RUNTIME.NSubjects
    
    % Check #RespCode parameter for non-zero value or if #TrigState is true
    if RUNTIME.UseOpenEx
        RCtag = AX.GetTargetVal(RUNTIME.RespCodeStr{i});
        TStag = AX.GetTargetVal(RUNTIME.TrigStateStr{i});
        TrialNum = AX.GetTargetVal(RUNTIME.TrialNumStr{i});
    else
        RCtag = AX(RUNTIME.RespCodeIdx(i)).GetTagVal(RUNTIME.RespCodeStr{i});
        TStag = AX(RUNTIME.TrigStateIdx(i)).GetTagVal(RUNTIME.TrigStateStr{i});
        TrialNum = AX(RUNTIME.TrialNumIdx(i)).GetTagVal(RUNTIME.TrialNumStr{i});
    end
    
    if ~RCtag || TStag, continue; end
  
    
    
    
    % There was a response and the trial is over.
    % Retrieve parameter data from RPvds circuits
    data = feval(sprintf('Read%sTags',RUNTIME.TYPE),AX,RUNTIME.TRIALS(i));
    data.ResponseCode = RCtag;
    data.TrialID = TrialNum;
    data.ComputerTimestamp = now;
    RUNTIME.TRIALS(i).DATA(RUNTIME.TRIALS(i).TrialIndex) = data;
    
    
    
    
    
    % Save runtime data in case of crash
    data = RUNTIME.TRIALS(i).DATA;  %#ok<NASGU>
    save(RUNTIME.DataFile{i},'data','-append','-v6'); % -v6 is much faster because it doesn't use compression  


     % Increment trial index
    RUNTIME.TRIALS(i).TrialIndex = RUNTIME.TRIALS(i).TrialIndex + 1;
    
    

    
    % Select next trial with default or custom function
    try
        RUNTIME.TRIALS(i).NextTrialID = feval(RUNTIME.TRIALS(i).trialfunc,RUNTIME.TRIALS(i));
    catch me
        errordlg('Error in Custom Trial Selection Function');
        rethrow(me)
    end
    
    
    
    
    
    % Increment TRIALS.TrialCount for the selected trial index
    RUNTIME.TRIALS(i).TrialCount(RUNTIME.TRIALS(i).NextTrialID) = ...
        RUNTIME.TRIALS(i).TrialCount(RUNTIME.TRIALS(i).NextTrialID) + 1;

    

    
    
    
    
  
    
    
    % Send trigger to indicate a new trial
    if RUNTIME.UseOpenEx
        TrigDATrial(AX,RUNTIME.TrigTrialStr{i});
    else
        TrigRPTrial(AX(RUNTIME.TrigTrialIdx(i)),RUNTIME.TrigTrialStr{i});
    end
    

    % Update parameters for next trial
    feval(sprintf('Update%stags',RUNTIME.TYPE),AX,RUNTIME.TRIALS(i));   

    

end













