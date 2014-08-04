function pname = DB_GetProtocolName(protocol)
% pname = DB_GetProtocolName(protocol)
%
% Returns name of protocol (scalar) from MySQL database.
%
% If protocol does not exist, then the user will prompted to enter it into
% the database.
%
% *Requires mym
%
% DJS 2013

% look on db_util.protocol_types table
if ~myisopen, DB_Connect; end
pname = char(myms(sprintf('SELECT alias FROM db_util.protocol_types WHERE pid = %d',protocol)));
if isempty(pname)
    while 1
        pstr = inputdlg({sprintf([ ...
            'Protocol ID %d was not found on the database (db_util.protocol_types).\n\n', ...
            'Enter an alias for the protocol (between 3 and 5 characters; eg. eFRA; required):'], protocol), ...
            'Enter a more descriptive name (up to 50 characters; optional):', ...
            'Enter a longer description if desired (up to 200 characters; optional):'}, ...
            sprintf('Protocol ID: %d',protocol), ...
            [1 50; 1 50; 3 50]);
        
        if ~isempty(pstr) && (length(pstr{1}) < 3 || length(pstr{1}) > 5)
            uiwait(errordlg('Protocol alias must be between 3 and 5 characters.  Try again, bozo!','getTankData','modal'));
            
        elseif ~isempty(pstr) && length(pstr{1}) <= 5
            mym(['INSERT db_util.protocol_types (pid,alias,name,description) ', ...
                'VALUES ({Si},"{S}","{S}","{S}")'],protocol,pstr{1},pstr{2},pstr{3})
            fprintf('Added Protocol ID %d %s to the database (db_util.protocol_types)\n',protocol,pstr{1})
            DO.protocolname = char(pstr{1});
            break
            
        elseif isempty(pstr)
            break
        end
    end
    
end
