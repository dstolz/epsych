%% Connect to database
DB_Connect;


%% Display researchers
mym('SELECT * FROM db_util.researchers')


%% Add researcher
NAME = 'First Last';
INITIALS = 'FL';
EMAIL = 'first.last@lab.com';

mym(['INSERT db_util.researchers (name,initials,email) ', ...
     'VALUES ("{S}","{S}","{S}")'],NAME,INITIALS,EMAIL)

mym('SELECT * FROM db_util.researchers')


%% Remove researcher
INITIALS = 'FL';

mym('DELETE FROM db_util.researchers WHERE initials = "{S}"',INITIALS);

mym('SELECT * FROM db_util.researchers')
