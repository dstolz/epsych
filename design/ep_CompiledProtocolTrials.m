function varargout = ep_CompiledProtocolTrials(protocol,varargin)
% cp = ep_CompiledProtocolTrials(protocol,varargin)
% [cp,fail] = ep_CompiledProtocolTrials(...)
% return and/or view compiled protocol trials
%
% Parameter ... Value
%   showgui ... true/false (default = true)
%     trunc ... truncate to some scalar value. (default = 0, no truncation)
% 
% See also, ep_ExperimentDesign, ep_CompileProtocol
%
% Daniel.Stolzberg@gmail.com 2014

% Copyright (C) 2016  Daniel Stolzberg, PhD

argin.showgui = true;
argin.trunc   = 0;

if nargin > 1
    for i = 1:2:length(varargin)
        argin.(varargin{i}) = varargin{i+1};
    end
end

[protocol,fail] = ep_CompileProtocol(protocol);
if fail
    vprintf(0,1,'Unable to properly compile protocol.\nCheck all ''buddy'' variables are balanced.\n')
    varargout{1} = [];
    varargout{2} = fail;
    return
end
C = protocol.COMPILED;

if argin.showgui
    trials = C.trials;
    if argin.trunc && size(trials,1) > argin.trunc
        trials = trials(1:argin.trunc,:);
    end
    
    % adjust values for table
    fisn = cell2mat(cellfun(@isnumeric, trials, 'UniformOutput', false));
    trials(fisn) = cellfun(@num2str,trials(fisn),'UniformOutput',false);
    
    fiss = cell2mat(cellfun(@isstruct, trials, 'UniformOutput',false));
    if any(fiss(:))
        trials(fiss) = cellfun(@(x) (x.file), trials(fiss), 'UniformOutput',false);
    end
    
    
    ShowGUI(C,trials);
end

varargout{1} = C;
varargout{2} = false;

function ShowGUI(C,trials)
fh = findobj('type','figure','-and','tag','CPfig');
if isempty(fh)
    fh = figure('tag','CPfig','Position',[200 100 700 400],'Color',[0.804 0.878 0.969]);
end
figure(fh); % bring to front

sc = size(C.trials,1);
str = '';
if sc > size(trials,1)
    str = sprintf('(displaying first %d)',size(trials,1));
end

n = C.OPTIONS.num_reps;
if C.OPTIONS.randomize
    rstr = 'Randomized';
else
    rstr = 'Serialized';
end

if isinf(n)
    fnstr = sprintf('%d unique trials, Infinite repetitions, %s %s',size(trials,1),rstr,str);
else
    fnstr = sprintf('%d unique trials, %d reps, %s %s',size(trials,1)/n,n,rstr,str);
    ntr = size(trials,1);
    iti = C.OPTIONS.ISI;
    pdur = mean(ntr*iti/1000/60);
    fnstr  = sprintf('%s | Protocol Duration: %0.1f min',fnstr,pdur);
end
set(fh,'Name',fnstr,'NumberTitle','off');

uitable(fh, ...
    'Units',        'Normalized', ...
    'Position',     [0.025 0.025 0.95 0.95], ...
    'Data',         trials, ...
    'ColumnName',   C.writeparams, ...
    'ColumnWidth',  'auto', ...
    'TooltipString','Presentation Order');



