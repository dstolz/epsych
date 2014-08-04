function tbprint(table)
% tbprint  List a few rows of MySQL table [mym utilities]
% Example  tbprint('junk')
if ~istable(table)
   error('Table %s not found; use ''tblist'' to list available tables',table)
else
   mym(['select * from ' table ' limit 20'])
end   