function result = remTankFromRegistry(tank)
% result = remTankFromRegistry(tank)
%
% Remove tank from registry
%
% Windows 64-bit versions 7 and higher only DJS 2/25/2013
%
% 
% See also, TankReg, addTankToRegistry
% 
% DJS (c) 2010

% Windows Vista and 7 places keys in a different place DJS 4/10
% persistent b
% 
% if isempty(b)
%     [~,b] = system('systeminfo');
% end
% a = strfind(b,'Windows 7');
% if isempty(a), a = strfind(b,'Vista'); end
% if ~isempty(a)
    % 64-bit system
    regKey = 'HKLM\SOFTWARE\Wow6432Node\TDT\TTank\EnumTanks';
% else
%     % 32-bit system
%     regKey = 'HKLM\Software\TDT\TTank\EnumTanks';
% end

[a,~] = system(sprintf('reg delete %s /v %s /f',regKey,tank)); 
result = ~a;



