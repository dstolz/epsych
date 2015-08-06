function portlist = scanports(portlimit)
% Function that scans for available serial ports.
% Returns cell array of string identifiers for available ports.
% Scans from COM1 - COM15 unless portlimit is specified,
% then scans from COM1 - COM[portlimit].
% version 1 by Robert Slazas, October 2011

% check for existing serial connections and close them
if ~isempty(instrfind)
    fclose(instrfind);
    delete(instrfind);
end

% set portlimit if not specified
if nargin < 1
    portlimit = 15;
end
portlist = cell(0);

h = waitbar(0,'Scanning Serial Ports...','Name','Scanning Serial Ports...');
for i = 1:portlimit
    eval(['s = serial(''COM',num2str(i),''');']);
    try
        fopen(s);
        fclose(s);
        delete(s);
        portlist{end+1,1}=['COM',num2str(i)];
        waitbar(i/portlimit,h,['Found ',num2str(numel(portlist)),' COM Ports...']);
    catch
        delete(s);
        waitbar(i/portlimit,h);
    end
end
close(h);
drawnow