function CONFIG = ep_TimerFcn_Start(CONFIG, AX, FLAGS)
% CONFIG = ep_TimerFcn_Start(CONFIG, RP, FLAGS)
% CONFIG = ep_TimerFcn_Start(CONFIG, DA, FLAGS)
% 
% Default Start timer function
% 
% Initialize parameters and take care of some other things just before
% beginning experiment
% 
% Use ep_PsychConfig GUI to specify custom timer function.
% 
% Daniel.Stolzberg@gmail.com 2014


if FLAGS.UseOpenEx, TYPE = 'DA'; else TYPE = 'RP'; end

% make temporary directory in current folder for storing data during
% runtime in case of a computer crash or Matlab error
if ~isfield(CONFIG(1).RUNTIME,'DataDir') || ~isdir(CONFIG(1).RUNTIME.DataDir)
    CONFIG(1).RUNTIME.DataDir = [cd filesep 'DATA'];
end
if ~isdir(CONFIG(1).RUNTIME.DataDir), mkdir(CONFIG(1).RUNTIME.DataDir); end

for i = 1:length(CONFIG)
    C = CONFIG(i);
 
    % Initalize C.TrialCount
    C.RUNTIME.TrialCount = zeros(size(C.PROTOCOL.COMPILED.trials,1),1);

    
    % Initialize first trial
    C = feval(C.PROTOCOL.OPTIONS.trialfunc,C);
    
    % Update parameter tags
    feval(sprintf('Update%stags',TYPE),AX,C);
    
    
    if ~FLAGS.UseOpenEx
        % Initialize C.DATA
        for mrp = C.PROTOCOL.COMPILED.Mreadparams
            C.DATA.(char(mrp)) = [];
        end
    end
    
    C.RUNTIME.RespCodeStr  = sprintf('#RespCode~%d', C.SUBJECT.BoxID);
    C.RUNTIME.TrigStateStr = sprintf('#TrigState~%d',C.SUBJECT.BoxID);
    C.RUNTIME.TrigTrialStr = sprintf('#TrigTrial~%d',C.SUBJECT.BoxID);
    
    % Create data file for saving data during runtime in case there is a problem
    % * this file will automatically be overwritten
    C.RUNTIME.DataDir  = CONFIG(1).RUNTIME.DataDir;
    dfn = sprintf('TEMP_DATA_%s_Box_%02d.mat',genvarname(C.SUBJECT.Name),C.SUBJECT.BoxID);
    C.RUNTIME.File = fullfile(C.RUNTIME.DataDir,dfn);
    
    CONFIG(i) = C;
end











