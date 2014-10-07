function RUNTIME = ep_TimerFcn_RunTime(RUNTIME, AX)
% RUNTIME = ep_TimerFcn_RunTime(RUNTIME, RP)
% RUNTIME = ep_TimerFcn_RunTime(RUNTIME, DA)
% 
% Default RunTime timer function
% 
% Use ep_PsychConfig GUI to specify custom timer function.
% 
% Daniel.Stolzberg@gmail.com 2014


for i = 1:length(RUNTIME.TRIALS)
    
    % Check #RespCode parameter for non-zero value or if #TrigState is true
    if RUNTIME.UseOpenEx
        RCtag = AX.GetTargetVal(RUNTIME.RespCodeStr{i});
        TStag = AX.GetTargetVal(RUNTIME.TrigStateStr{i});
    else
        RCtag = AX(RUNTIME.RespCodeIdx(i)).GetTagVal(RUNTIME.RespCodeStr{i});
        TStag = AX(RUNTIME.TrigStateIdx(i)).GetTagVal(RUNTIME.TrigStateStr{i});
    end
    
    
    if ~(RCtag && TStag), continue; end
    
    
    % There was a response and the trial is over.
    % Retrieve parameter data from RPvds circuits
    RUNTIME.TRIALS(i).DATA(end+1) = feval(sprintf('Read%sTags',RUNTIME.TYPE),AX,RUNTIME);

    
    % Save runtime data in case of crash
    save(RUNTIME.DataFile,'RUNTIME','-v6'); % -v6 is much faster because it doesn't use compression  


    % Select next trial with default or custom function
    RUNTIME = feval(RUNTIME.TRIALS(i).trialfunc,C,true);
    
    
    % Update parameters for next trial
    feval(sprintf('Update%sTags',RUNTIME.TYPE),AX,RUNTIME);   
    
    % Trigger next trial
    if RUNTIME.UseOpenEx
        TrigDATrial(AX,RUNTIME.TrigTrialStr{i});
    else
        TrigRPTrial(AX(RUNTIME.TrigTrialIdx(i)),RUNTIME.TrigTrialStr{i});
    end    
end













