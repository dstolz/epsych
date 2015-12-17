function dinfo = TDT_GetDeviceInfo(DA,echo)
% dinfo = TDT_GetDeviceInfo(DA)
% dinfo = TDT_GetDeviceInfo(DA,echo)
% 
% Get Device Names, RCX files, and Sampling rates from OpenEx
% 
% DA is a handle to the OpenDeveloper ActiveX control after a conneciton
% has already been established.
% 
% If echo == true (default), then information about the hardware modules
% and rcx files will be printed in the command window.
% 
% Note: Parameter tags embedded in RPvds macros or scripts may not be read
% when using 64-bit Matlab.  The function ReadRPvdsTags is able to read
% embedded parameters by using the RPco.X ActiveX control.
% 
% See also, TDT_SetupDA, ReadRPvdsTags
% 
% Daniel.Stolzberg@gmail.com 2014

if nargin == 1, echo = true; end

dinfo = [];
i = 1;
while 1
    name = DA.GetDeviceName(i-1);
    if isempty(name), break;   end
    dinfo.name{i}   = name; %#ok<*AGROW>
    dinfo.Module{i} = DevLUT(DA.GetDeviceType(name));
    dinfo.status(i) = DA.GetDeviceStatus(name);
    dinfo.RPfile{i} = DA.GetDeviceRCO(name);
    if strcmp(dinfo.RPfile{i},'*.rco') % probably PA5
        dinfo.RPfile{i} = '';
    end
    dinfo.Fs(i)     = DA.GetDeviceSF(name);
    
    
    if strcmp(dinfo.Module{i},'PA5')
        if echo, fprintf('% 5s (PA5)\n',name); end
    else        
        [dinfo.tags{i},dinfo.datatypes{i}] = GetTags(DA,name);
        if echo
            s = sprintf('(Fs ~%3.0fkHz)',dinfo.Fs(i)/1000);
            fprintf('% 5s% 9s:\t%s\n',name,s,dinfo.RPfile{i})
        end
    end
    
    i = i + 1;
end


function [tags,datatypes] = GetTags(DA,name)
dt = 'DINPS';
di = uint8(dt);
dn = {'Buffer','Integer','Logical','Coefficients','Float'};

tags = {''};
datatypes = {''};

k = 1;
for i = 1:length(dt)
    j = 0;
    while 1
        t = DA.GetNextTag(name,di(i),j==0);
        if isempty(t), break; end
        tags{k} = t;
        datatypes{k} = dn{i};
        j = j + 1; k = k + 1;
    end
end
    

function dev = DevLUT(type)
switch type
    case  0, dev = 'RP2';
    case  1, dev = 'RL2';
    case  2, dev = 'RA16';
    case  3, dev = 'RV8';
    case  5, dev = 'RM1';
    case  6, dev = 'RM2';
    case 10, dev = 'RX5';
    case 11, dev = 'RX6';
    case 12, dev = 'RX7';
    case 13, dev = 'RX8';
    case 15, dev = 'RZ2';
    case 18, dev = 'RZ5';
    case 19, dev = 'RZ6';
    otherwise, dev = 'UNKNOWN';
end







