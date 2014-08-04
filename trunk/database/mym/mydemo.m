%% MYDEMO: Demonstrate usage of mym utilities
% Example: mydemo (Oh, the FEX code metrics..)

%% List available functions
lookfor mym

%% Connect to MySQL
myisopen
myopen('localhost','root','fairfax')
myisopen

%% List available databases
dblist

%% Create database 'test2'
dbadd('test2')

%% Confirm that database 'test2' was created
isdbase('test2')

%% Make database 'test2' current
dbcurr
dbopen('test2')
dbcurr

%% Load FEX download data in file 'fex.txt' to table 'fex'
mym(['create table fex (' ...
     'time datetime, ' ...
     'id   mediumint unsigned, ' ...
     'rank smallint  unsigned, ' ...
     'file smallint  unsigned, ' ...
     'fcat tinyint   unsigned, ' ...
     'down smallint  unsigned)'])
tic
mym(['load data infile ''D:/Program Files/Matlab/work/fexstat/fex.txt'' ' ...
     'into table fex lines terminated by ''\n'' ' ...
     '(@time,id,rank,file,fcat,down) ' ...
     'set time = str_to_date(@time,''%d-%b-%Y %H:%i:%s'')'])
toc 

%% List tables in database 'test2'
tblist

%% List names and types of 'fex' columns
[names, types] = tbattr('fex')
tbsize('fex')

%% Read contents of table 'fex' into Matlab workspace
who
tic
tbread('fex',names,names,'')
toc
who

%% Write loaded data back to MySQL (500 rows per pass), to a table that is a copy of 'fex'
tic
tbadd('fex2',names,types,'replace')
tbwrite('fex2',names,names,500)
toc
tbsize('fex2')

%% Disconnect from MySQL
myclose