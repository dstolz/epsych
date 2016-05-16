function r = DB_AddResearcher(conn)



myms(['CREATE TABLE IF NOT EXISTS db_util.researchers (' ...
        'initials VARCHAR(3) NOT NULL, ', ...
        'researcher VARCHAR(45) NOT NULL, ', ...
        'email VARCHAR(45) NULL, ', ...
        'UNIQUE INDEX initials_UNIQUE (initials ASC), ', ...
        'PRIMARY KEY (researcher), ', ...
        'UNIQUE INDEX researcher_UNIQUE (researcher ASC));'],conn);

opts.WindowStyle = 'modal';
opts.Resize      = 'on';
opts.Interpreter = 'none';
r = inputdlg({'Name: ','Initials: ','E-Mail Address: '}, ...
    'Add Researcher', 1,{'','',''},opts);

if isempty(r) % cancelled
    r = {'','',''};
    return
end


if isempty(r{1})
    uiwait(msgbox('The ''Name'' field is required','Add Researcher','modal'));
    return
end
    

R = myms('SELECT researcher FROM db_util.researchers',conn,'cellarray');

if any(ismember(R,r{1}))
    uiwait(msgbox(sprintf('The researcher ''%s'' already exists.',r{1}), ...
        'Add Researcher','modal'));
    return
end

myms(sprintf(['INSERT INTO db_util.researchers ', ...
    '(researcher,initials,email) VALUES ("%s","%s","%s");'], ...
    r{1},r{2},r{3}),conn);

vprintf(0,'Added researcher: ''%s'' (%s) %s',r{1},r{2},r{3})




