function[i] = myisopen
% myisopen True if MySQL instance active  [mym utilities]  
% Example  if mycheck, disp('MySQL running!'), end
i = ~mym('status');
