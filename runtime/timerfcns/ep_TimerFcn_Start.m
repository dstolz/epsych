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


isRP = isa(G_RP,'COM.RPco_x');
if isRP, TYPE = 'RP'; else TYPE = 'DA'; end

% make temporary directory in current folder for storing data during
% runtime in case of a computer crash or Matlab error
if ~isfield(CONFIG(1),'RunTimeDataDir') || ~isdir(CONFIG(1).RunTimeDataDir)
    CONFIG(1).RunTimeDataDir = [cd filesep 'RunTimeDATA'];
end
if ~isdir(CONFIG(1).RunTimeDataDir), mkdir(CONFIG(1).RunTimeDataDir); end

for i = 1:length(CONFIG)
    C = CONFIG(i);
 
    % Initalize C.TrialCount
    C.TrialCount = zeros(size(C.COMPILED.trials,1),1);

    
    % Initialize first trial
    C = feval(C.OPTIONS.trialfunc,C);
    
    % Update parameter tags
    feval(sprintf('Update%stags',TYPE),AX,C);
    
    
    if isRP
        % Initialize C.DATA
        for mrp = C.COMPILED.Mreadparams
            C.DATA.(char(mrp)) = [];
        end
    end
    

    % Create data file for saving data during runtime in case there is a problem
    % * this file will automatically be overwritten
    C.RunTimeDataDir  = CONFIG(1).RunTimeDataDir;
    dfn = sprintf('TEMP_DATA_%s_Box_%02d.mat',genvarname(C.SUBJECT.Name),C.SUBJECT.BoxID);
    C.RunTimeDataFile = fullfile(C.RunTimeDataDir,dfn);
    
    CONFIG(i) = C;
end











