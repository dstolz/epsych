function tags = ReadRPvdsTags(RPfile)
% tags = ReadRPvdsTags(RPfile);
% 
% Read parameter tags from an RPvds file. RPfile is the full path and
% filename to an RCX file.
% 
% Daniel.Stolzberg@gmail.com 2014


% Grab parameter tags from an existing RPvds file
fh = findobj('Type','figure','-and','Name','RPfig');
if isempty(fh), fh = figure('Visible','off','Name','RPfig'); end

RP = actxcontrol('RPco.x','parent',fh);
RP.ReadCOF(RPfile);

k = 1;
n = RP.GetNumOf('ParTag');
for i = 1:n
    x = RP.GetNameOf('ParTag', i);
    % remove any error messages and OpenEx proprietary tags (starting with 'z')
    if ~(any(ismember(x,'/\|')) || ~isempty(strfind(x,'rPvDsHElpEr')))
        tags{k,1} = x; %#ok<AGROW>
        k = k + 1;
    end
end

tags = sortrows(tags,1);

delete(RP);
close(fh);