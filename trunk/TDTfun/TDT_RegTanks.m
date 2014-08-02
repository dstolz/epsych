function tanklist = TDT_RegTanks(TT)
% tanklist = TDT_RegTanks % creates temporary connection to TTank.X and then closes it
% tanklist = TDT_RegTanks(TT) % uses established TTank.X connection (TT)
% 
% Returns list of registered tanks.
% 
% DJS (c) 2010

c = false;

if ~exist('TT','var') || isempty(TT)
    TT = TDT_SetupTT;
    c = true;
end

i = 1;
while 1
    tanklist{i} = TT.GetEnumTank(i-1); %#ok<AGROW>
    if isempty(tanklist{i})
        tanklist(i) = []; %#ok<AGROW>
        break
    end
    i = i + 1;
end

if c
    delete(TT);
	h = findobj('Type','figure','-and','Name','TDTFIG');
    if ~isempty(h), close(h); end
end


