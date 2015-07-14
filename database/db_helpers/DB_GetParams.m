function p = DB_GetParams(id,type,conn)
% P = DB_GetParams(id)
% P = DB_GetParams(id,type)
% P = DB_GetParams(id,type,conn)
% 
% P = DB_GetParams(id)
% Simply retrieves parameters from the protocols table into structure P.
% If only the id is specified, then this function will assume it is a block
% id.
% 
% P = DB_GetParams(id,type)
% Retrieves parameters structure P using any of the following specified
% table ids: 'block' (default),'channel','unit'
% ex: 
%       P = DB_GetParams(4922,'unit') % where unit id is 4922
%
%
% P = DB_GetParams(id,type,conn)
% If using the Matlab Database Toolbox, a third input parameter can be
% specified as an connected database object (see DATABASE)
% ex:
%       conn = database('some_database', 'MyUsername', 'MyPassword', ...
%               'Vendor', 'MYSQL', 'Server', '129.100.111.111');
%       P = DB_GetParams(4922,'unit',conn);
% 
% Note: Uses a persistent variable and checks if the protocol is the same
% as the last call to this function.  This reduces the number of redundant
% calls to the server.
%
% Daniel.Stolzberg@gmail.com 2013
% 
% See also, DB_Browser, DB_GetSpiketimes, DB_GetWave

persistent PP

UseDBT = nargin == 3;

if UseDBT
    % Use Database Toolbox
    assert(isa(conn,'database'),'conn should be a database object');
    assert(isempty(conn.Message),conn.Message);
    assert(~isempty(conn.Instance),'Not connected to a database');
    
    %Set preferences with setdbprefs.
    setdbprefs('DataReturnFormat', 'numeric');
    setdbprefs('NullNumberRead', 'NaN');
    setdbprefs('NullStringRead', 'null');


else % use mym
    
    database = dbcurr;
    assert(~isempty(dbcurr),'No Database has been selected.');
    
end


if nargin >= 2 && ~isempty(type)
    if UseDBT
        curs = exec(conn,sprintf('SELECT block FROM v_ids WHERE %s = %d',type,id));
        curs = fetch(curs);
        close(curs);
        block_id = curs.Data;
    else
        block_id = myms(sprintf('SELECT block FROM v_ids WHERE %s = %d',type,id));
    end
    assert(~isempty(block_id),sprintf('ID %d of type ''%s'' was not found on the database',id,type));
else
    block_id = id;
end


if isempty(PP) || ~isfield(PP,'block_id') || block_id ~= PP.block_id
    % retrieve block data
    if UseDBT
        setdbprefs('DataReturnFormat', 'structure');
        curs = exec(conn,sprintf(['SELECT id,param_id,param_type,param_value FROM protocols ', ...
            'WHERE block_id = %d'],block_id));
        curs = fetch(curs);
        close(curs);
        PP = curs.Data;
    else
        PP = mym(['SELECT id,param_id,param_type,param_value FROM protocols ', ...
            'WHERE block_id = {Si}'],block_id);
    end
    
    if isempty(PP)
        error('No protocol data found for block %d',block_id);
    end
    
    % reorganize protocol data
    if UseDBT
        setdbprefs('DataReturnFormat', 'numeric');
        curs = exec(conn,'SELECT id FROM db_util.param_types');
        curs = fetch(curs);
        close(curs);
        pid = curs.Data;
        
        setdbprefs('DataReturnFormat', 'cellarray');
        curs = exec(conn,'SELECT param FROM db_util.param_types ORDER BY id');
        curs = fetch(curs);
        close(curs);
        pstr = curs.Data;
    else
        [pid,pstr] = myms('SELECT id,param FROM db_util.param_types');
    end
    
    ind = ~ismember(pid,unique(PP.param_type));
    pid(ind) = []; pstr(ind) = [];
    
    if UseDBT
        setdbprefs('DataReturnFormat', 'structure');
        curs = exec(conn,sprintf([ ...
            'SELECT t.spike_fs,t.wave_fs,t.id AS tank_id FROM tanks t ', ...
            'INNER JOIN blocks b ON b.tank_id = t.id LIMIT 1'],block_id));
        curs = fetch(curs);
        close(curs);
        p = curs.Data;

    else
        p = mym([ ...
            'SELECT t.spike_fs,t.wave_fs,t.id AS tank_id FROM tanks t ', ...
            'INNER JOIN blocks b ON b.tank_id = t.id ', ...
            'WHERE b.id = {Si} LIMIT 1'],block_id);
    end
    
    
    p.block_id   = block_id;
%     p.database   = database;
    p.param_type = pstr;
    p.param_id   = unique(PP.param_id);
    
    for i = 1:length(pid)
        ind = PP.param_type == pid(i);
        p.param_value(:,i)   = PP.param_value(ind); 
        p.ind.(pstr{i})      = strcmp(p.param_type,pstr{i});
        p.lists.(pstr{i})    = unique(PP.param_value(ind));
    end
    
    % sort by stimulus onset times if available
    onidx = strcmp('onset',pstr);
    if any(onidx)
        p.param_value = sortrows(p.param_value,find(onidx));
    end
    
    for i = 1:length(pid)
        p.VALS.(pstr{i}) = p.param_value(:,i);
    end
    
    p.updated = true;
    
    PP = p;
else
    PP.updated = false;
    p = PP;
end
