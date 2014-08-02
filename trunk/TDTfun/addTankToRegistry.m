function result = addTankToRegistry (tank, directory) 
% AddTankToRegistry Adds a given tank to the TTankEng through the registry
%
% result = addTankToRegistry (tank, directory) 
%    Given the string tank name (i.e. '070515A') and the string directory
%    to the tank (i.e. 'C:\Tanks\') with a trailing backslash, this
%    function adds the given pair to the directory. Returns true on
%    success, false on failure.
%
% Windows 64-bit versions 7 and higher only DJS 2/25/2013
% 
% See also, TankReg, remTankFromRegistry
% 
% DJS 2012

% Windows Vista and 7 places keys in a different place DJS 4/10

% persistent b
% 
% if isempty(b)
%     [~,b] = system('systeminfo');
% end

% a = strfind(b,'Windows 7');
% if isempty(a), a = strfind(b,'Vista'); end
% if ~isempty(a)
regKey = 'HKLM\SOFTWARE\Wow6432Node\TDT\TTank\EnumTanks';
% else
%     regKey = 'HKLM\Software\TDT\TTank\EnumTanks';
% end

if ~strcmp(directory(end),'\'), directory(end+1) = '\'; end % DJS 3/10

% some conflict results if key already exists.  Check if key already exists
% DJS 3/10
rkstr = sprintf('reg query %s /v %s',regKey,tank);
[a,~] = system(rkstr); 
if ~a
    % registry key already exists
    result = true;
    return
end

% make sure path ends in '\\' 
if directory(end) ~= '\'; 
    directory(end+1) = '\\';
elseif directory(end) == '\'; 
    directory(end+1) = '\'; 
end
akstr = sprintf('reg.exe add %s /v %s /t REG_SZ /d "%s"',regKey,tank,directory);
[status,result] = system(akstr); %#ok<NASGU>

result = ~status;
