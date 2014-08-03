function varargout = ep_CompiledProtocolTrials(protocol,varargin)
% cp = ep_CompiledProtocolTrials(protocol,varargin)
% [cp,fail] = ep_CompiledProtocolTrials(...)
% return and/or view compiled protocol trials
%
% Parameter ... Value
%   showgui ... true/false
%     trunc ... truncate to some scalar value. (default = 0, no truncation)
% 
% See also, ExperimentDesign
%
% Daniel.Stolzberg@gmail.com 2014

argin.showgui = true;
argin.trunc   = 0;

if nargin > 1
    for i = 1:2:length(varargin)
        argin.(varargin{i}) = varargin{i+1};
    end
end

[protocol,fail] = ep_CompileProtocol(protocol);
if fail
    fprintf(2,'Unable to properly compile protocol.\nCheck all ''buddy'' variables are balanced.\n')
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
    fisn = find(cell2mat(cellfun(@isnumeric, trials, 'UniformOutput', false)));
    for i = 1:length(fisn)
        trials{fisn(i)} = num2str(trials{fisn(i)});
    end
    
    fiss = find(cell2mat(cellfun(@isstruct, trials, 'UniformOutput',false)));
    for i = 1:length(fiss)
        trials{fiss(i)} = trials{fiss(i)}.file;
    end
    
    ShowGUI(C,trials);
end

varargout{1} = C;
varargout{2} = false;

function ShowGUI(C,trials)
fh = findobj('type','figure','-and','tag','CPfig');
if isempty(fh)
    fh = figure('tag','CPfig','Position',[200 100 700 400]);
end
figure(fh); % bring to front
sc = size(C.trials,1);
set(fh, ...
    'Name',sprintf('Compiled Protocol: # trials = %d (displaying first %d)',sc,size(trials,1)), ...
    'NumberTitle','off');

uitable(fh, ...
    'Units',        'Normalized', ...
    'Position',     [0.025 0.025 0.95 0.95], ...
    'Data',         trials, ...
    'ColumnName',   C.writeparams, ...
    'ColumnWidth',  'auto', ...
    'TooltipString','Presentation Order');



