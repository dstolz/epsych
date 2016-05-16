function [P,fail] = ep_CompileProtocol(P)
% [P,fail] = ep_CompileProtocol(P)
%
% Takes protocol structure created by ExperimentDesign GUI and compiles the
% data for use by Psychophysics_GUI.
% 
% Adds fields to the protocol structure:
%       protocol.COMPILED.writeparams
%       protocol.COMPILED.readparams
%       protocol.COMPILED.trials
% 
% Alternatively, compiled protocol can be fully customized manually by
% manually specifying values for writeparams, readparams, and trials
% fields in protocol.COMPILED structure.
%
% See also, ep_ExperimentDesign, ep_CompiledProtocolTrials
% 
% Daniel.Stolzberg@gmail.com 2014

fldn = fieldnames(P.MODULES);

% look for buffers and replace them into the table as parameters
for i = 1:length(fldn)
    if ~isfield(P.MODULES,fldn{i}) || ~isfield(P.MODULES.(fldn{i}),'buffers')
        continue
    end
    bufs = P.MODULES.(fldn{i}).buffers;
    idx = findincell(bufs);
    for j = idx
        P.MODULES.(fldn{i}).data{j,4} = bufs{j};
    end
end


% trim any undefined parameters
for i = 1:length(fldn)
    v = P.MODULES.(fldn{i}).data;
    v(~ismember(1:size(v,1),findincell(v(:,1))),:) = [];
    P.MODULES.(fldn{i}).data = v;
end


% RUN THROUGH EACH MODULE AND EXPAND PARAMETERS ACROSS MODULES
[COMPILED,fail] = ParamPrep(P);
if fail, return; end

n = P.OPTIONS.num_reps;
if ~isinf(n)
    if P.OPTIONS.randomize
        % randomized presentation order
        m = size(COMPILED.trials,1);
        for i = 1:n
            ind = randperm(m);
            t(m*(i-1)+1:m*i,:) = COMPILED.trials(ind,:);
        end
        COMPILED.trials = t;
    else
        % serialized presentation orders
        COMPILED.trials = repmat(COMPILED.trials,n,1);
    end
end

COMPILED.OPTIONS = P.OPTIONS;
COMPILED = rmfield(COMPILED,'buds'); % not needed

P.COMPILED = COMPILED;

end



function [comp,fail] = ParamPrep(P)
comp.writeparams = [];
comp.readparams  = [];

d = [];
data = {};
mod  = {};

k = 1; m = 1;
fn = fieldnames(P.MODULES);
for i = 1:length(fn)
    v = P.MODULES.(fn{i}).data;
    cind = ~ismember(v(:,end),'< NONE >'); % associate calibration
    if any(cind)
        idx = find(cind);
        for j = 1:length(idx)
            if ~isfield(P.MODULES.(fn{i}),'calibrations') % backwards compatability
                dd = getpref('ProtocolDesign','CALDIR',cd);
                if isnumeric(dd), dd = cd; end
                cfn = fullfile(dd,v{idx(j),end});
            else
                cfn = P.MODULES.(fn{i}).calibrations{idx(j)}.filename;
            end
            
            if ~exist(cfn,'file')
                r = questdlg(sprintf([ ...
                    'Can''t locate the calibration file which was part of this protocol: ', ...
                    '"%s"\n\n', ...
                    'Would you like to locate it manually?'],cfn), ...
                    'Missing Calibration','Yes','No','Yes');
                if isequal(r,'Yes')
                    cfn = uigetfile({'Calibration File (*.cal)','*.cal'}, ...
                        'Locate Calibration file');
                    if ~cfn
                        fprintf('** Missing Calibration file: "%s"\n',cfn)
                        v{idx(j),end} = '< NONE >';
                        continue
                    end
                else
                    fprintf('** Missing Calibration file: "%s"\n',cfn)
                    v{idx(j),end} = '< NONE >';
                    continue
                end
            end

            try
                vals = eval(v{idx(j),4});
            catch %#ok<CTCH>
                vals = str2num(v{idx(j),4}); %#ok<ST2NM>
            end
            warning('off','MATLAB:dispatcher:UnresolvedFunctionHandle');
            C = load(cfn,'-mat');
            warning('on','MATLAB:dispatcher:UnresolvedFunctionHandle');
            
            if isequal(v{idx(j),3},'< NONE >')
                cb = sprintf('CalBuddy%d',m);
            else
                cb = v{idx(j),3};
            end
    
            v{idx(j),3} = cb;
            cvals = Calibrate(vals,C);
            v(end+1,:)  = {sprintf('~%s_Amp',v{idx(j),1}), ...
                'Write', cb, cvals, 0, 0, '< NONE >'}; %#ok<AGROW>
            v(end+1,:)  = {sprintf('~%s_Norm',v{idx(j),1}), ...
                'Write', cb, repmat(C.hdr.cfg.ref.norm,1,length(cvals)), ...
                0, 0, '< NONE >'}; %#ok<AGROW>
            
            
            m = m + 1;
        end
    end
    
    % buffers
    idx = find([v{:,6}]);
    for j = 1:length(idx)
        buflengths = zeros(size(v{idx(j),4}));
        for b = 1:length(v{idx(j),4})
            buflengths(b) = v{idx(j),4}{b}.nsamps;
            if strcmp(P.OPTIONS.IncludeWAVBuffers,'off')
                v{idx(j),4}{b} = rmfield(v{idx(j),4}{b},'buffer');
            end
        end
        if isempty(v{idx(j),3}) || strcmp(v{idx(j),3},'< NONE >')
            bb = sprintf('BufBuddy%d',m);
        else
            bb = v{idx(j),3};
        end
        
        v{idx(j),3} = bb;
        v(end+1,:) = {sprintf('~%s_Size',v{idx(j),1}), ...
            'Write', bb, buflengths, 0, 0, '< NONE >'}; %#ok<AGROW>
        v(end+1,:) = {sprintf('~%s_ID',v{idx(j),1}), ...
            'Read/Write', bb, 1:length(buflengths), 0, 0, '< NONE >'}; %#ok<AGROW>
        v(end+1,:) = v(idx(j),:); %#ok<AGROW> Place buffer tag last so that the buffer size is updated first (DJS 5/2016)
        v(idx(j),:) = []; % delete original buffer tag
    end
    
    
    kl = size(v,1);
    mod(k:k+kl-1,1)  = repmat(fn(i),kl,1);
    data(k:k+kl-1,:) = v;
    k = k + kl;
end

[data,idx] = sortrows(data,3);
mod = mod(idx);

% fields: 1 - parameter tag
%         2 - Write/Read
%         3 - buddy variable
%         4 - Associated parameter values
%         5 - Random within range (specified in values)

for i = 1:size(data,1)
    module = mod{i};
    if isempty(strfind(data{i,2},'Write')) % 'Read' only
        comp.readparams{end+1} = [module '.' data{i,1}];
        continue
    end
    
    if strfind(data{i,2},'Write')
        comp.writeparams{end+1} = [module '.' data{i,1}];
    end
    
    if strfind(data{i,2},'Read')
        comp.readparams{end+1} = [module '.' data{i,1}];
    end
    
    if isnumeric(data{i,4}) % Numeric data
        v = data{i,4};
    
    elseif ~data{i,6} % Char and not WAV
        if ~ischar(data{i,4}) % left over from previous use as WAV file
            data{i,4} = '';
        end
        
        v = str2num(data{i,4}); %#ok<ST2NM>
    
    elseif data{i,6} % WAV files
%         t = findobj('type','uitable','-and','tag','param_table');
%         S = get(t,'UserData');
%         v = S.WAV{i}';
        v = data{i,4};
    else
        v = str2num(data{i,4}); %#ok<ST2NM>
    end
    
    if data{i,5} % randomized
        d{end+1}{1} = 'randomized'; %#ok<AGROW>
        d{end}{2} = []; 
        d{end}{3} = v; 
    else
        % Buddy variables
        if strcmp(data{i,3},'< NONE >')
            d{end+1} = v; %#ok<AGROW>
        else
            d{end+1}{1} = 'buddy'; %#ok<AGROW>
            d{end}{2} = data{i,3}; 
            d{end}{3} = v; 
        end
    end
end

[comp,fail] = ep_AddTrial(comp,d);

end


