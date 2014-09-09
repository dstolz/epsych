function CONFIG = ep_TimerFcn_RunTime(CONFIG, AX, FLAGS)
% CONFIG = ep_TimerFcn_RunTime(CONFIG, RP, FLAGS)
% CONFIG = ep_TimerFcn_RunTime(CONFIG, DA, FLAGS)
% 
% Default RunTime timer function
% 
% Use ep_PsychConfig GUI to specify custom timer function.
% 
% Daniel.Stolzberg@gmail.com 2014

if FLAGS.UseOpenEx, TYPE = 'DA'; else TYPE = 'RP'; end

for i = 1:length(CONFIG)
    C = CONFIG(i);
    
    % Check #RespCode parameter for non-zero value or if #TrigState is true
    if FLAGS.UseOpenEx
        RCtag = AX.GetTargetVal(C.RUNTIME.RespCodeStr);
        TStag = AX.GetTargetVal(C.RUNTIME.TrigStateStr);
    else
        ind = ismember(C.RUNTIME.RespCodeStr,C.COMPILED.readparams);
        RCtag = AX(C.RUNTIME.RPread_lut(ind)).GetTagVal(C.RUNTIME.RespCodeStr);
        ind = ismember(C.RUNTIME.TrigStateStr,C.COMPILED.readparams);
        TStag = AX(C.RUNTIME.RPread_lut(ind)).GetTagVal(C.RUNTIME.TrigStateStr);
    end
    
    
    if ~(RCtag && TStag), continue; end
    
    
    % There was a response and the trial is over.
    % Retrieve parameter data from RPvds circuits
    C.DATA(end+1) = feval(sprintf('Read%sTags',TYPE),AX,C);

    
    % Save runtime data in case of crash
    save(C.RUNTIME.DataFile,'C','-v6'); % -v6 is much faster because it doesn't use compression  


    % Select next trial with default or custom function
    C = feval(C.OPTIONS.trialfunc,C,true);
    
    
    % Update parameters for next trial
    feval(sprintf('Update%sTags',TYPE),AX,C);
    feval(sprintf('Trig%sTrial',TYPE),AX,C);
    
    
    % Trigger next trial
    feval(sprintf('Trig%sTrial',TYPE),AX,C.RUNTIME.TrigTrialStr);
    
    CONFIG(i) = C;
end













