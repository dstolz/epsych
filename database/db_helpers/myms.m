function varargout = myms(str,conn,DataReturnFormat)
% varargout = myms(str);        % use mym
% varargout = myms(str,conn);   % use Matlab Database Toolbox
% varargout = myms(str,conn,DataReturnFormat);   % use Matlab Database Toolbox
%
% Wrapper function for mym and Matlab Database Toolbox
%
% Returns individual outputs instead of a single structure.
%
% Use with mym:
% > Requires a connection is already established (see DB_Connect)
% > Use sprintf instead of normal mym inline placeholders like {Si}
% 
% Use with Database Toolbox:
% > Requires a connection is already established (see DATABASE)
% > Must pass a second parameter, conn, which is the database connection
%   object returned from a call to DATABASE
% > A third parameter, DataReturnFormat, can be set to 'cellarray',
%   'dataset', 'numeric', or 'structure' (see SETDBPREFS).  If not
%   specified, the most recent option will be used.
% 
% 
% DJS 2013/2015
%
% See also, sprintf, mym

assert(ischar(str),'First input must be a string');

if nargin >= 2 && ~isempty(conn)
    assert(isa(conn,'database'),'conn should be a database object');
    assert(isempty(conn.Message),conn.Message);
    assert(~isempty(conn.Instance),'Not connected to a database');
    
    if nargin == 3
        assert(ischar(DataReturnFormat),'DataReturnFormat must be a string')
        setdbprefs('DataReturnFormat',DataReturnFormat);
    end
    
    if nargout == 0
        exec(conn,str);
    else
        curs = exec(conn,str);
        curs = fetch(curs);
        varargout{1} = curs.Data;
    end
    
else
    try
        s = mym(str);
        if numel(fieldnames(s)) > 1 && nargout > 1 || numel(fieldnames(s)) == 1 && nargout == 1
            varargout = struct2cell(s);
        else
            varargout{1} = s;
        end
    catch %#ok<CTCH>
        varargout{1} = [];
    end
end


