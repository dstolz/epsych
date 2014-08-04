function p = DB_GetParams(id,type)
% P = DB_GetParams(id)% 
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
% Note: Uses a persistent variable and checks if the protocol is the same
% as the last call to this function.  This reduces the number of redundant
% calls to the server.
%
% Daniel.Stolzberg@gmail.com 2013
% 
% See also, DB_Browser

persistent PP

assert(nargin==1|nargin==2,'Not enough input arguments.');

database = dbcurr;
assert(~isempty(dbcurr),'No Database has been selected.');

if nargin == 2
    block_id = myms(sprintf('SELECT block FROM v_ids WHERE %s = %d',type,id));
    assert(~isempty(block_id),sprintf('ID %d of type ''%s'' was not found on the database',id,type));
else
    block_id = id;
end


if isempty(PP) || block_id ~= PP.block_id || ~strcmp(PP.database,database)   
    % retrieve block data
    PP = mym(['SELECT id,param_id,param_type,param_value FROM protocols ', ...
        'WHERE block_id = {Si}'],block_id);
    
    if isempty(PP)
        error('No protocol data found for block %d',block_id);
    end
    
    % reorganize protocol data
    [pid,pstr] = myms('SELECT id,param FROM db_util.param_types');
    
    ind = ~ismember(pid,unique(PP.param_type));
    pid(ind) = []; pstr(ind) = [];
    
    p = mym([ ...
        'SELECT t.spike_fs,t.wave_fs,t.id AS tank_id FROM tanks t ', ...
        'INNER JOIN blocks b ON b.tank_id = t.id ', ...
        'WHERE b.id = {Si} ', ...
        'LIMIT 1'],block_id);

    
    p.block_id   = block_id;
    p.database   = database;
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
