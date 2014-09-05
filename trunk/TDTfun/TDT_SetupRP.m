function varargout = TDT_SetupRP(mod,modid,ct,rpfile)
% RP = TDT_SetupRP(mod,modid,ct,rpfile)
% [RP,status] = TDT_SetupRP( ...
% 
% where mod is a valid module type: 'RZ5','RX6','RP2', etc..
%   modid is the module id.  default is 1.
%   ct is a connection type:  'GB' or 'USB'
%   rpfile is the full path to an RPvds file.
% 
% returns RP which is the handle to the RPco.x control.  Also returns
% status which is a bitmask of the module status.  Use with bitget function
%   Bit# 0 = Connected
%   Bit# 1 = Circuit loaded
%   Bit# 2 = Circuit running
%   Bit# 3 = RA16BA Battery
% (see page 43 of ActiveX reference manual for more status values).
% 
% See also TDT_SetupDA, TDT_SetupTT, bitget
% 
% DJS (c) 2010

varargout = cell(1,3);

if isempty(modid), modid = 1; end

if ~exist(rpfile,'file')
    beep
    errordlg(sprintf('File does not exist: "%s"',rpfile),'File Does Not Exist', ...
        'modal');
    return
end

h = findobj('Type','figure','-and','Name','RPfig');
if isempty(h)
    h = figure('Visible','off','Name','RPfig');
end
varargout{3} = h;

RP = actxcontrol('RPco.x','parent',h);


rpstatus = double(RP.GetStatus);
if all(bitget(rpstatus,1:3))
    fprintf('RPco.X already connected, loaded, and running.\n')
    varargout{2} = rpstatus;
    return
end

if ischar(modid), modid = str2double(modid); end

if ~eval(sprintf('RP.Connect%s(''%s'',%d)',mod,ct,modid))
    beep
    errordlg(sprintf(['Unable to connect to %s_%d module via %s connection!\n\n', ...
        'Ensure all modules are powered on and connections are secured\n\n', ...
        'Ensure the module is recognized in the zBusMon program.'], ...
        mod,modid,ct),'Connection Error','modal');
    CloseUp(RP,h);
    return
    
else
    fprintf('%s_%d connected ... ',mod,modid)
    RP.ClearCOF;
    if ~RP.LoadCOF(rpfile)
        beep
        errordlg(sprintf(['Unable to load RPvds file to %s module!\n\n', ...
            'The RPvds file exists, but can not be loaded for some reason'], ...
            mod),'Loading Error','modal');
        CloseUp(RP,h);
        return
    else
        fprintf('loaded ...')
        if ~RP.Run
            beep
            errordlg(sprintf(['Unable to run %s module!\n\n', ...
                'Ensure all modules are powered on and connections are secured'], ...
                mod),'Run Error','modal');
            CloseUp(RP,h);
            return
        else
            fprintf('running\n')
        end
    end
end

varargout{1} = RP;
varargout{2} = double(RP.GetStatus);




function CloseUp(RP,h)
delete(RP);
close(h);



