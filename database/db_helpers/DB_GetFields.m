function varargout = DB_GetFields(table,field,val,cond,retfields,addargs,varargin) %#ok<STOUT>
% varargout = DB_GetFields(table,field,val,cond,retfields,addargs)
%   Returns structures with all fields from TABLE with the value VAL 
%   in the field specified from FIELD.  VAL must be an Nx1 cell of
%   scalars,vectors, 1xN char string or Nx1 cell strings.
%   NOTE: FIELD and VAL can be cell arrays specifying more than one 
%   condition, however they must be the same size.
% 
%   TABLE can also be specified as a cell array of strings if fields from 
%   more than one table is to be retrieved.
%   This will likely only be the case if ADDARGS is used to specify a join.
%   In the case of multiple tables, the output will contain a structure for
%   each table retrieved. 
% 
%   If FIELD and VAL are not specified, or are left empty ([]), then all
%   fields and rows from TABLE will be returned in FIELDS.
% 
%   COND is used only when FIELD and VAL have a length greater than 1, i.e.
%   there is more than one condition to query on.  ex: {'AND','OR'} for
%   three conditions specified in FIELD and VAL. The default is to use
%   'AND' between each condition.
% 
%   Additional MySQL arguments, more specifically additional SELECT
%   statement arguments, can be made in a single string of type char.  This
%   is useful for futher filtering or to specify ordering of retrieved
%   data.  Ex:  'AND protocol = 2 ' | Ex: 'ORDER BY name'
% 
%   RETFIELD can be optionally specified to retrieve only specific fields
%   from TABLE. RETFIELD should be a cell array of char strings.
%       An example of valid RETFIELDS input would be:
%       {'name','birthday'} 
%       if 'name' and 'birthday' are field names of TABLE.
% 
%       Basic wildcard use is also supported:
%       {'q10_*','q40_*'}
%       This would return all fields starting with q10_ and q40_ ...
%       such as q10_1,q10_2,q40_1,q40_2
% 
%       NOTE: if using RETFIELD with ambiguous field names following a join
%       (using ADDARGS), RETFIELD must contain the full name of the table
%       being returned.  ex: 'tanks.id,blocks.id,channels.*'
% 
%   Output will be a structure with TABLE field names containing retrieved
%   data.  If more that one TABLE is specified, i.e. TABLE is a cell array
%   of strings, then a structure will be returned for each table and in the
%   the same order of TABLE.
% 
%   Although DB_GetFields is useful in retrieving table data, more complex
%   joins and statements are likely best made explicitly.
%     That being said.. DB_GetFields can be used in the following way to
%     perform JOINs and return data from multiple tables in the following
%     way:
%       spontp = DB_GetFields({'blocks','protocols'},{'protocol'},{2},[],[], ...
%     'INNER JOIN protocols ON blocks.id = protocols.block_id');
%     > This example returns all fields from both the blocks and protocols
%     tables.  The right side of a JOIN statement must not be the first
%     table in the first input field ('blocks' in this case).
%     > NOTE: identical field names are not handled well and will be
%     returned from only one of the tables.
% 
%   NOTE: The current thread of MATLAB must already be connected to the server
%   and a database must be in use.
% 
%   NOTE: Avoid using table or variable aliases when calling this function
%
% DJS (c) 2009

if exist('table','var') && ~isempty(table)  && ischar(table)
    table = cellstr(table);
end

if exist('table','var') && ~isempty(table) && nargout ~= length(table)
%     error('Number of outputs must be the same as the number of tables');
elseif ~exist('table','var') || isempty(table)
    table = {'retstruct'};
end

% find all fields from table(s) (TABLE)
table = cellstr(table);
for i = 1:length(table)
    f{i} = tbattr(table{i});
end

% return fields (RETFIELDS)
if nargin >= 5 && ~isempty(retfields)
    retfields = cellstr(retfields);
    fieldstr = ' ';
    for i = 1:length(retfields)
        if findstr('*',retfields{i}) % look for wildcard character
            ind = regexp(f{1},retfields{i});
            for j = 1:length(ind)
                if isempty(ind{j}), ind{j} = 0; end
            end
            tmpfield = {f{1}{logical(cell2mat(ind))}};
        else
            tmpfield = retfields(i);
        end
        
        for j = 1:length(tmpfield)
            fieldstr = [fieldstr,table{1},'.',tmpfield{j},',']; %#ok<AGROW>
        end
    end
    fieldstr(end) = [];

else
    % generate output fields
    fi = '';
    for i = 1:length(f)
        fi = char(fi,[repmat([table{i},'.'],size(f{i},1),1),char(f{i})]);
    end
    fi = cellstr(fi);
    fi(1) = [];

    fieldstr = ' ';
    for i = 1:length(fi)
        fieldstr = [fieldstr,fi{i},',']; %#ok<AGROW>
    end
    fieldstr(end) = [];
end

% val string
valstr = ' ';
if nargin > 1 && ~isempty(field)
    if ~iscell(field), field = {field}; end
    if ~iscell(val),   val   = {val};   end
    
    if length(field) ~= length(val)
        error('FIELD and VAL must have the same length');
    end

    if ~exist('cond','var') || isempty(cond)
        cond = cellstr(repmat('AND',length(field),1));
    end

    for i = 1:length(val)
        str = ' ';
        if isnumeric(val{i})
            val{i} = reshape(val{i},1,numel(val{i}));
            str = [str,num2str(val{i},'%g,')]; %#ok<AGROW>
            
        elseif iscellstr(val{i})
            for j = 1:length(val{i})
                str = [str,'"',val{i}{j},'",']; %#ok<AGROW>
            end
        elseif ischar(val{i})
            str = [str,'"',val{i},'",']; %#ok<AGROW>
        else
            error(['VAL index %g is an invalid type.\n', ...
                'Only scalars, vectors, or cellstr may be used.'],i);
        end
        
        str(end) = []; % erase trailing comma
        
        valstr = [valstr,sprintf(' %s IN (%s)',field{i},str)]; %#ok<AGROW>

        if i < length(val)
            valstr = [valstr,' ',cond{i},' ']; %#ok<NASGU,AGROW>
        end
    end
    valstr = [' WHERE ',valstr];
end

% additional arguments
if ~exist('addargs','var'), addargs = ' '; end


if ~isempty(deblank(addargs))
% handle ORDER BY or GROUP BY statements
    ind = findstr(addargs,'ORDER');
    if isempty(ind)
        ind = findstr(addargs,'GROUP');
    end
    
    if ~isempty(ind)
        valstr = [valstr,' ',addargs(ind:end)];
        addargs(ind:end) = [];
    end
    
% handle conditioinal statements (AND, OR, etc.)
    ind = findstr(addargs,'AND');
    if isempty(ind)
        ind = findstr(addargs,'OR');
    end
    
    if ~isempty(ind)
        valstr = [valstr,' ',addargs(ind:end)];
        addargs(ind:end) = [];
    end
end

if isempty(fieldstr)
    error('No fields to return')
end


% evaluate MySQL statement
eval(sprintf('[%s] = mym(''SELECT %s FROM %s %s %s'');', ...
    fieldstr,fieldstr,table{1},addargs,valstr));

% set output
for i = 1:length(table)
    eval(sprintf('varargout{i} = %s;',table{i}));
end
