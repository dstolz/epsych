function dbs = DB_Connect(host,user,pass)
% dbs = DB_Connect
% dbs = DB_Connect(host,user,pass)
% dbs = DB_Connect(forcePrompt)
%
% Connect to database via mym
%
% Returns list of databases if successful connection is established
%
% DJS 2013

prevcon = getpref('DB_Connect',{'host','user','pass'},{'','',''});
if nargin >= 1 && islogical(host) && host == true
    % force update
    newcon = PromptNewInfo(prevcon);
    if ~isempty(newcon)
        host = newcon{1}; user = newcon{2}; pass = newcon{3};
        mym('open',host,user,pass);
    end
    
elseif nargin == 0
    % use previous connection parameters
    host = prevcon{1}; user = prevcon{2}; pass = prevcon{3};
    
    try
        mym('open',prevcon{1},prevcon{2},prevcon{3});
    catch %#ok<CTCH>
        % try again
        newcon = PromptNewInfo(prevcon);
        if ~isempty(newcon)
            host = newcon{1}; user = newcon{2}; pass = newcon{3};
            mym('open',host,user,pass);
        end
    end

elseif nargin == 3
    mym('open',host,user,pass);
    
end

if ~myisopen
    error('Unable to connect to database')
end

dbs = dblist;
% remove reserved database names
reserved = {'information_schema','class_lists','db_util','mysql'};
dbs(ismember(dbs,reserved)) = [];

setpref('DB_Connect',{'host','user','pass'},{host,user,pass});


function newcon = PromptNewInfo(prevcon)
prompt  = {'Host','User name','Password'};
name    = 'Connect to DB';
opt.Resize      = 'on';
opt.WindowStyle = 'modal';
opt.Interpreter = 'none';
newcon = inputdlg(prompt,name,1,prevcon,opt);
