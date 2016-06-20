function[i] = istable(name)
% istable  True if MySQL table exists     [mym utilities]
% Example  if istable('junk'), tbdrop('junk'), end
if ~myisopen
   error('No MySQL connection active; use ''myopen'' to connect')
else
   try 
     i = false;
     [a,b,c,d,e,f] = myms(['describe ' name]);  %#ok
     i = true;
   catch
   end
end    