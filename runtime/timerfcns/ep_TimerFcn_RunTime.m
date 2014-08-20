function CONFIG = ep_TimerFcn_RunTime(CONFIG, RP, DA)
% CONFIG = ep_TimerFcn_RunTime(CONFIG, RP, [])
% CONFIG = ep_TimerFcn_RunTime(CONFIG, [], DA)
% 
% Default RunTime timer function
% 
% Daniel.Stolzberg@gmail.com 2014

isDA = isempty(RP);
if isDA, AX = DA; else AX = RP; end

for i = 1:length(CONFIG)
    C = CONFIG(i);
    
    BoxID = C.SUBJECT.BoxID;
    
    % Check #RespCode parameter for non-zero value or if #InTrial is true
    RCtag = sprintf('#RespCode~%d',BoxID);
    ITtag = sprintf('#InTrial~%d',BoxID);
    if isDA
        S = ReadDAtags(AX,C,{RCtag,ITtag});
    else
        S = ReadRPtags(AX,C,{RCtag,ITtag});
    end
    if ~S.(RCtag) || S.(ITtag), continue; end
    
    
    % There was a response and the trial is over.
    % Retrieve parameter data from RPvds circuits
    if isDA
        C.DATA(end+1) = ReadDAtags(AX,C);
    else
        C.DATA(end+1) = ReadRPtags(AX,C);
    end
    
    % Save runtime data in case of crash
    save(C.RunTimeDataFile,'C','-v6'); % -v6 is much faster because it doesn't use compression  


    % Select next trial with default or custom function
    C = feval(C.OPTIONS.trialfunc,C,true);
    
    % Update parameters for next trial
    if isDA
        e = UpdateDATags(AX,C);
    else
        e = UpdateRPTags(AX,C);
    end
    
    CONFIG(i) = C;
end











