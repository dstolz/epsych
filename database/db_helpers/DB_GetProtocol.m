function varargout = DB_GetProtocol(block_id,add_unique)
% P = DB_GetProtocol(block_id,[add_unique])
% [column_names,data] = DB_GetProtocol(block_id);
%
% Retrieve protocol data for block_id (scalar integer) from the currently
% selected database.
%
% Optionally set add_unique to true (default = false) to return unique
% values of each parameter (except 'onset' if available) in an additional
% subfield called 'UNIQUE'. Only available when one output is specified
% (i.e. structured output).
%
% If one output, returns a structure, P, with subfields named by the
% protocol type.
%
% If two outputs, returns parameter types in the order of column names and
% the data in a matrix.
%
% Sorts all data by 'onset' parameter if available
%
% See also, DB_GetParams
%
% Daniel.Stolzberg@gmail.com 2016

narginchk(1,2);
nargoutchk(1,2);

assert(isscalar(block_id),'DB_GetProtocol:block_id input must be a scalar integer')

if nargin == 1 || isempty(add_unique), add_unique = false; end


dP = myms(sprintf(['SELECT t.param,p.param_value ', ...
          'FROM protocols p LEFT JOIN db_util.param_types t ', ...
          'ON p.param_type = t.id ', ...
          'WHERE p.block_id = %d'],block_id));


      
types = unique(dP.param);

for i = 1:length(types)
    ind = ismember(dP.param,types{i});
    data(:,i) = dP.param_value(ind); %#ok<AGROW>
end

% sort by 'onset' parameter if available
oind = ismember(types,'onset'); 
if any(oind)
    data = sortrows(data,find(oind));
end


if nargout == 1
    for i = 1:length(types)
        P.(types{i}) = data(:,i);
    end
    
    if add_unique
        for i = find(~oind)'
            P.UNIQUE.(types{i}) = unique(P.(types{i}));
        end
    end
    varargout{1} = P;
else
    varargout{1} = types(:)';
    varargout{2} = data;
end

