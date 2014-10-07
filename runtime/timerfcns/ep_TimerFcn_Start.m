function RUNTIME = ep_TimerFcn_Start(CONFIG, RUNTIME, AX)
% RUNTIME = ep_TimerFcn_Start(CONFIG, RUNTIME, RP)
% RUNTIME = ep_TimerFcn_Start(CONFIG, RUNTIME, DA)
% 
% Default Start timer function
% 
% Initialize parameters and take care of some other things just before
% beginning experiment
% 
% Use ep_PsychConfig GUI to specify custom timer function.
% 
% Daniel.Stolzberg@gmail.com 2014



% make temporary directory in current folder for storing data during
% runtime in case of a computer crash or Matlab error
if ~isfield(RUNTIME,'DataDir') || ~isdir(RUNTIME.DataDir)
    RUNTIME.DataDir = [cd filesep 'DATA'];
end
if ~isdir(RUNTIME.DataDir), mkdir(RUNTIME.DataDir); end

RUNTIME.NSubjects = length(CONFIG);

for i = 1:RUNTIME.NSubjects
    C = CONFIG(i);
    
    RUNTIME.SUBJECT(i) = C.SUBJECT;
    
    RUNTIME.TRIALS(i).trials = C.PROTOCOL.COMPILED.trials;
    RUNTIME.TRIALS(i).TrialCount = zeros(size(RUNTIME.TRIALS(i).trials,1),1); 
    RUNTIME.TRIALS(i).trialfunc = C.PROTOCOL.OPTIONS.trialfunc;
   
    % Initialize first trial
    RUNTIME.TRIALS(i).NextIndex = [];
    RUNTIME.TRIALS(i) = feval(RUNTIME.TRIALS(i).trialfunc,RUNTIME.TRIALS(i));
    
    % Update parameter tags
    feval(sprintf('Update%stags',RUNTIME.TYPE),AX,RUNTIME.TRIALS(i));
    
    
    if ~RUNTIME.UseOpenEx
        % Initialize C.DATA
        for mrp = RUNTIME.TRIALS(i).Mreadparams
            RUNTIME.DATA(i).(char(mrp)) = [];
        end
    end
    
    
    RUNTIME.RespCodeStr{i}  = sprintf('#RespCode~%d', RUNTIME.SUBJECT(i).BoxID);
    RUNTIME.TrigStateStr{i} = sprintf('#TrigState~%d',RUNTIME.SUBJECT(i).BoxID);
    RUNTIME.TrigTrialStr{i} = sprintf('#TrigTrial~%d',RUNTIME.SUBJECT(i).BoxID);
    
    
    % Create data file for saving data during runtime in case there is a problem
    % * this file will automatically be overwritten
    dfn = sprintf('TEMP_DATA_%s_Box_%02d.mat',genvarname(RUNTIME.SUBJECT.Name),RUNTIME.SUBJECT.BoxID);
    RUNTIME.DataFile{i} = fullfile(RUNTIME.DataDir,dfn);

end

RUNTIME.RespCodeIdx  = zeros(1,RUNTIME.NSubjects);
RUNTIME.TrigStateIdx = zeros(1,RUNTIME.NSubjects);
RUNTIME.TrigTrialIdx = zeros(1,RUNTIME.NSubjects);
for i = 1:RUNTIME.NSubjects
    
    ind = ismember(RUNTIME.RespCodeStr,RUNTIME.devinfo(i).tags);
    if any(ind), RUNTIME.RespCodeIdx(i) = find(ind); end
    
    ind = ismember(RUNTIME.TrigStateStr,RUNTIME.devinfo(i).tags);
    if any(ind), RUNTIME.TrigStateIdx(i) = find(ind); end
    
    ind = ismember(RUNTIME.TrigTrialStr,RUNTIME.devinfo(i).tags);
    if any(ind), RUNTIME.TrigTrialIdx(i) = find(ind); end
    
end


for i = 1:RUNTIME.NSubjects
    if isempty(RUNTIME.TrigTrialStr{i}), continue; end
    
    % Trigger first new trial
    if RUNTIME.UseOpenEx
        TrigDATrial(AX,RUNTIME.TrigTrialStr{i});
    else
        TrigRPTrial(AX(RUNTIME.TrigTrialIdx(i)),RUNTIME.TrigTrialStr{i});
    end
end











