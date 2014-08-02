function regtanks = GetRegTanks(TTX)
% regtanks = GetRegTanks(TTX)
%
% DJS 2013

for idx = 1:100
    regtanks{idx} = TTX.GetEnumTank(idx-1);
    if isempty(regtanks{idx}), break; end
end

regtanks(end) = [];

end