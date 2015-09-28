function DB_CheckAnalysisParams(n,d,u,conn)
% DB_CheckAnalysisParams(n,d)
% DB_CheckAnalysisParams(n,d,u)
% DB_CheckAnalysisParams(n,...,conn)
%
% check to see if necessary parameters already exist on db_util and add if
% not there
%
% Where n is a cellstr array of parameter names and d is a cell string
% array (same size as n) of descriptions for each parameter.  u is a cell
% string array with units of the corresponding parameter.  Individual
% values for u can be empty.
%
% Max number of characters for each n is 15.
% Max number of characters for each d is 45.
%
% A connection to the database must already be established before calling
% this function.
% 
% ex:
% n = {'bestlevel','maxresp','threshold'};
% d = {'Level of best response', 'Maximum response', 'Threshold'};
% u = {'dB','Hz','dB'};
% DB_CheckAnalysisParams(n,d,u);
%
% See also, DB_GetUnitProps, DB_UpdateUnitProps
%
% DJS 2013 daniel.stolzberg@gmail.com



if ~iscellstr(n), error('n must be a cellstr'); end
if ~iscellstr(d), error('d must be a cellstr'); end
if nargin < 3 || isempty(u), u = cell(size(n)); end

if ~isequal(numel(n),numel(d)), error('Size of n must equal size of d'); end
if ~isequal(numel(n),numel(u)), error('Size of u must equal size of n'); end

% use mym by default
if nargin < 4, conn = []; end


DB_CreateUnitPropertiesTable(conn);


p = myms('SELECT * FROM db_util.analysis_params',conn,'structure');


for i = 1:length(n)
    ind = ismember(p.name,n{i});
    if ~any(ind) || ~strcmp(d{i},p.description{ind})
        myms(sprintf(['INSERT db_util.analysis_params ', ...
            '(name,description) VALUES ("%s","%s") ', ...
            'ON DUPLICATE KEY UPDATE name = name'],n{i},d{i}),conn);
    end
% make sure analysis_params are up to date because units column was added
% later on

    if ~any(ind)
        continue
    elseif ~isempty(u{i}) && ~strcmp(u{i},p.units{ind})
        myms(sprintf(['UPDATE db_util.analysis_params ', ...
            'SET units = "%s" ', ...
            'WHERE name = "%s"'],u{i},n{i}),conn);
    end
end



















