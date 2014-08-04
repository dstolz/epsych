function myopen(host,user,pwd)
% myopen   Connect to MySQL               [mym utilities]
% Example  myopen('localhost','root','pwd')
try
   a = mym('open',host,user,pwd);  %#ok
catch
   error('Could not connect to MySQL; check login parameters')
end   