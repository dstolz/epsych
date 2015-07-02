function varargout = myms(str,conn)
% varargout = myms(str);        % use mym
% varargout = myms(str,conn);   % use Matlab Database Toolbox
%
% Wrapper function for mym and Matlab Database Tolbox
%
% Returns individual outputs instead of a single structure.
%
% Use sprintf instead of normal mym inline placeholders like {Si}
%
% DJS 2013/2015
%
% See also, sprintf, mym

assert(ischar(str),'First input must be a string');

if nargin == 2 && ~isempty(conn)
    assert(isa(conn,'database'),'conn should be a database object');
    assert(isempty(conn.Message),conn.Message);
    assert(~isempty(conn.Instance),'Not connected to a database');
    
    if nargout == 0
        exec(conn,str);
    else
        curs = exec(conn,str);
        curs = fetch(curs);
        varargout{1} = curs.Data;
    end
    
else
    try
        varargout = struct2cell(mym(str));
    catch %#ok<CTCH>
        varargout{1} = [];
    end
end


