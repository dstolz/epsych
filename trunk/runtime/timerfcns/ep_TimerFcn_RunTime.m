function CONFIG = ep_TimerFcn_RunTime(CONFIG, AX, FLAGS)
% CONFIG = ep_TimerFcn_RunTime(CONFIG, RP, FLAGS)
% CONFIG = ep_TimerFcn_RunTime(CONFIG, DA, FLAGS)
% 
% Default RunTime timer function
% 
% Use ep_PsychConfig GUI to specify custom timer function.
% 
% Daniel.Stolzberg@gmail.com 2014

isRP = isa(G_RP,'COM.RPco_x');
if isRP, TYPE = 'RP'; else TYPE = 'DA'; end

for i = 1:length(CONFIG)
    C = CONFIG(i);
    
    % Check #RespCode parameter for non-zero value or if #TrigState is true
    RCtag = FLAGS.RespCode{i};
    ITtag = FLAGS.TrigState{i};
    
    S = feval(sprintf('Read%stags',TYPE),AX,C,{RCtag,ITtag});
    
    if ~S.(RCtag) || S.(ITtag), continue; end
    
    
    % There was a response and the trial is over.
    % Retrieve parameter data from RPvds circuits
    C.DATA(end+1) = feval(sprintf('Read%stags',TYPE),AX,C);

    
    % Save runtime data in case of crash
    save(C.RunTimeDataFile,'C','-v6'); % -v6 is much faster because it doesn't use compression  


    % Select next trial with default or custom function
    C = feval(C.OPTIONS.trialfunc,C,true);
    
    
    % Update parameters for next trial
    feval(sprintf('Update%sTags',TYPE),AX,C);
    feval(sprintf('Trig%sTrial',TYPE),AX,C);
    
    
    % Trigger next trial
    feval(sprintf('Trig%sTrial',TYPE),AX,FLAGS.TrigTrial{i});
    
    CONFIG(i) = C;
end













