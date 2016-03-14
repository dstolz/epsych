function [tag,datatype] = ReadRPvdsTags(RPfile)
% tag = ReadRPvdsTags(RPfile);
% [tag,datatype] = ReadRPvdsTags(RPfile);
% 
% Read parameter tags from an RPvds file. RPfile is the full path and
% filename to an RCX file.
% 
% Daniel.Stolzberg@gmail.com 2014


% Grab parameter tags from an existing RPvds file
try
    fh = findobj('Type','figure','-and','Name','ReadRPvdsfig');
catch %#ok<CTCH> % sometimes findobj fails for no apparent reason
    fh = [];
end
if isempty(fh), fh = figure('Visible','off','Name','ReadRPvdsfig'); end

RP = actxcontrol('RPco.x','parent',fh);
r = RP.ReadCOF(RPfile);

%For unknown reasons, sometimes the active X control fails to read the
%parameter tags during the first attempt. Only happens when using OpenEx
%and reading in a physiology RPVds circuit from an RZ5.
if ~r
    for k = 1:10
        disp ('Unable to read parameter tags from RPVds file. Trying again...')
        r = RP.ReadCOF(RPfile);
        if r, break; end
    end
    if ~r
        error('Unable to read parameter tags from  RPVds file.');
    end
end

k = 1;
n = RP.GetNumOf('ParTag');
tag = {[]};
for i = 1:n
    x = RP.GetNameOf('ParTag', i);
    % remove any error messages and OpenEx proprietary tags (starting with 'z')
    if ~any(ismember(x,'/\|')) && isempty(strfind(x,'rPvDsHElpEr'))
        tag{k,1} = x;
        datatype{k,1} = char(RP.GetTagType(x)); %#ok<AGROW>
        k = k + 1;
    end
end

if ~isempty(tag{1}), tag = sortrows(tag,1); end

delete(RP);
close(fh);