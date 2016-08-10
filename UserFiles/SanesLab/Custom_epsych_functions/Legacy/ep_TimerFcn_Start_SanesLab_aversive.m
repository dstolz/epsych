function RUNTIME = ep_TimerFcn_Start_SanesLab_aversive(CONFIG, RUNTIME, AX)
% RUNTIME = ep_TimerFcn_Start_SanesLab(CONFIG, RUNTIME, AX)
%
%Custom function for SanesLab epsych
%
%Initialize parameters and take care of some other things just before
%beginning experiment.
%
%Inputs: 
%   CONFIG: epsych CONFIG structure (global var)
%   RUNTIME: epsych RUNTIME structure (global var)
%   AX: handle to active X control for RPVds circuit (global var)
%
%Outputs:
%   RUNTIME: epsych RUNTIME structure (global var)
% 
% Daniel.Stolzberg@gmail.com 2014. Updated by ML Caras 2016.

global FUNCS

% Make temporary directory in current folder for storing data during
% runtime in case of a computer crash or Matlab error
if ~isfield(RUNTIME,'DataDir') || ~isdir(RUNTIME.DataDir)
    RUNTIME.DataDir = [cd filesep 'DATA'];
end
if ~isdir(RUNTIME.DataDir), mkdir(RUNTIME.DataDir); end

RUNTIME.NSubjects = length(CONFIG);


%For each subject...
for i = 1:RUNTIME.NSubjects
    C = CONFIG(i);
       
    RUNTIME.TRIALS(i).trials     = C.PROTOCOL.COMPILED.trials;
    RUNTIME.TRIALS(i).TrialCount = zeros(size(RUNTIME.TRIALS(i).trials,1),1); 
    RUNTIME.TRIALS(i).trialfunc  = C.PROTOCOL.OPTIONS.trialfunc;
   
    for j = 1:length(RUNTIME.TRIALS(i).readparams)
        ptag = RUNTIME.TRIALS(i).readparams{j};
        if RUNTIME.UseOpenEx
            dt = AX.GetTargetType(ptag);
        else
            lut = RUNTIME.TRIALS(i).RPread_lut(j);
            dt  = AX(lut).GetTagType(ptag);    
        end
        if isempty(deblank(char(dt))), dt = {'S'}; end % PA5
        RUNTIME.TRIALS(i).datatype{j} = char(dt);
        
    end
    
    RUNTIME.TRIALS(i).Subject = C.SUBJECT;    
    
    % Initialze required parameters genereated by behavior macros
    RUNTIME.RespCodeStr{i}  = sprintf('#RespCode~%d', RUNTIME.TRIALS(i).Subject.BoxID);
    RUNTIME.TrigStateStr{i} = sprintf('#TrigState~%d',RUNTIME.TRIALS(i).Subject.BoxID);
    RUNTIME.NewTrialStr{i}  = sprintf('#NewTrial~%d', RUNTIME.TRIALS(i).Subject.BoxID);
    RUNTIME.ResetTrigStr{i} = sprintf('#ResetTrig~%d',RUNTIME.TRIALS(i).Subject.BoxID);
    RUNTIME.TrialNumStr{i}  = sprintf('#TrialNum~%d', RUNTIME.TRIALS(i).Subject.BoxID);
    
    
    % Create data file for saving data during runtime in case there is a problem
    % * this file will automatically be overwritten
    
    % Create data file info structure
    info.Subject = RUNTIME.TRIALS(i).Subject;
    info.CompStartTimestamp = now;
    info.StartDate = strtrim(datestr(info.CompStartTimestamp,'mmm-dd-yyyy'));
    info.StartTime = strtrim(datestr(info.CompStartTimestamp,'HH:MM PM'));
    [~, computer] = system('hostname'); info.Computer = strtrim(computer);
    
    dfn = sprintf('RUNTIME_DATA_%s_Box_%02d_%s.mat',genvarname(RUNTIME.TRIALS(i).Subject.Name), ...
        RUNTIME.TRIALS(i).Subject.BoxID,datestr(now,'mmm-dd-yyyy'));
    RUNTIME.DataFile{i} = fullfile(RUNTIME.DataDir,dfn);

    if exist(RUNTIME.DataFile{i},'file')
        oldstate = recycle('on');
        delete(RUNTIME.DataFile{i});
        recycle(oldstate);
    end
    save(RUNTIME.DataFile{i},'info','-v6');
    
    
    %If user enters AM or FM depth as a percent, we need to change it to a proportion
    %here to make sure that the RPVds circuit will function properly.
    RUNTIME = checkDepth(RUNTIME,'AMdepth');
    RUNTIME = checkDepth(RUNTIME,'FMdepth');

    
    %Identify the module running behavior (RZ6)
    h = findModuleIndex_SanesLab('RZ6', []);
    
    %Pull out parameter tags and remove OpenEx/TDT proprietary tags
    tags = RUNTIME.TDT(i).devinfo(h.dev).tags;
    tags = rmTags_SanesLab(tags);

    %Initialize data structure
    for j = 1:length(tags)
        RUNTIME.TRIALS(i).DATA.(tags{j}) = [];
    end

    %Append timing, response and pump info
    RUNTIME.TRIALS(i).DATA.ResponseCode = [];
    RUNTIME.TRIALS(i).DATA.TrialID = [];
    RUNTIME.TRIALS(i).DATA.ComputerTimestamp = [];
    RUNTIME.TRIALS(i).DATA.PumpRate = [];
    
    %Append GUI-specific info
    switch lower(FUNCS.BoxFig)
        case 'aversive_detection_gui'
            RUNTIME.TRIALS(i).DATA.Nogo_lim = [];
            RUNTIME.TRIALS(i).DATA.Nogo_min = [];
            
        case {'appetitive_detection_gui','appetitive_detection_gui_v2'}
            RUNTIME.TRIALS(i).DATA.Go_prob = [];
            RUNTIME.TRIALS(i).DATA.NogoLim = [];
            RUNTIME.TRIALS(i).DATA.Expected_prob = [];
            RUNTIME.TRIALS(i).DATA.RepeatNOGOcheckbox = [];
            RUNTIME.TRIALS(i).DATA.RewardVol= [];
    end

end

RUNTIME.RespCodeIdx  = zeros(1,RUNTIME.NSubjects);
RUNTIME.TrigStateIdx = zeros(1,RUNTIME.NSubjects);
RUNTIME.TrigTrialIdx = zeros(1,RUNTIME.NSubjects);
RUNTIME.TrialNumIdx  = zeros(1,RUNTIME.NSubjects);

%For each TDT module...
for i = 1:RUNTIME.TDT.NumMods
    
    %Initialize Response Code
    ind = find(ismember(RUNTIME.RespCodeStr,RUNTIME.TDT.devinfo(i).tags));
    if ~isempty(ind)
        if RUNTIME.UseOpenEx
            RUNTIME.RespCodeStr(ind) = cellfun(@(s) ([RUNTIME.TDT.name{i} '.' s]),RUNTIME.RespCodeStr(ind),'UniformOutput',false);
        end
        RUNTIME.RespCodeIdx(ind) = i;
    end
    
    %Initialize Trigger State
    ind = find(ismember(RUNTIME.TrigStateStr,RUNTIME.TDT.devinfo(i).tags));
    if ~isempty(ind)
        if RUNTIME.UseOpenEx
            RUNTIME.TrigStateStr(ind) = cellfun(@(s) ([RUNTIME.TDT.name{i} '.' s]),RUNTIME.TrigStateStr(ind),'UniformOutput',false);
        end
        RUNTIME.TrigStateIdx(ind) = i;
    end
    
    %Initialize New Trial Status
    ind = find(ismember(RUNTIME.NewTrialStr,RUNTIME.TDT.devinfo(i).tags));
    if ~isempty(ind)
        if RUNTIME.UseOpenEx
            RUNTIME.NewTrialStr(ind) = cellfun(@(s) ([RUNTIME.TDT.name{i} '.' s]),RUNTIME.NewTrialStr(ind),'UniformOutput',false);
        end
        RUNTIME.NewTrialIdx(ind) = i;
    end
    
    %Initialize Reset Trigger Status
    ind = find(ismember(RUNTIME.ResetTrigStr,RUNTIME.TDT.devinfo(i).tags));
    if ~isempty(ind)
        if RUNTIME.UseOpenEx
            RUNTIME.ResetTrigStr(ind) = cellfun(@(s) ([RUNTIME.TDT.name{i} '.' s]),RUNTIME.ResetTrigStr(ind),'UniformOutput',false);
        end
        RUNTIME.ResetTrigIdx(ind) = i;
    end
    
    %Initialize Trial Number
    ind = find(ismember(RUNTIME.TrialNumStr,RUNTIME.TDT.devinfo(i).tags));
    if ~isempty(ind)
        if RUNTIME.UseOpenEx
            RUNTIME.TrialNumStr(ind) = cellfun(@(s) ([RUNTIME.TDT.name{i} '.' s]),RUNTIME.TrialNumStr(ind),'UniformOutput',false);
        end
        RUNTIME.TrialNumIdx(ind) = i;
    end    
end


%For each subject...
for i = 1:RUNTIME.NSubjects
    
    %Find the column with the most unique values (this is our roved param)
    trial_mat = cell2mat(RUNTIME.TRIALS.trials);
    unique_mat = [];
    
    for col = 1:size(trial_mat,2)
       nvals = numel(unique(trial_mat(:,col)));
       
       unique_mat = [unique_mat;col,nvals];
    end
    
    roved_param_col = unique_mat(unique_mat(:,2) == max(unique_mat(:,2)),1);
    
    %Sort trial structure by roved param col
    RUNTIME.TRIALS.trials = sortrows(RUNTIME.TRIALS.trials,roved_param_col);
    
    %Initialize first trial
    RUNTIME.TRIALS(i).TrialIndex = 0;
    [RUNTIME,AX] = updateRUNTIME_SanesLab(RUNTIME,AX);
    
end



%CHECK THAT DEPTH IS PROPORTION VALUE FOR RPVDS
function RUNTIME = checkDepth(RUNTIME,variable)

%If user enters AM or FM depth as a percent, we need to change it to a proportion
%here to make sure that the RPVds circuit will function properly.
if find(cell2mat(strfind(RUNTIME.TRIALS.writeparams,variable)))
    
    %Find the column containing AM depth info
    col_ind = find(~cellfun(@isempty,(strfind(RUNTIME.TRIALS.writeparams,variable))) == 1 );
    
    %If percent...
    if any(cell2mat(RUNTIME.TRIALS.trials(:,col_ind))> 1)
        
        %Proportion
        RUNTIME.TRIALS.trials(:,col_ind) = cellfun(@(x)x./100, RUNTIME.TRIALS.trials(:,col_ind),'UniformOutput',false);
    end
    
end






