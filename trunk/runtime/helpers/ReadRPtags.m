function vals = ReadRPtags(RP,COMPILED)
% vals = ReadRPtags(RP,COMPILED)
% 
% Daniel.Stolzberg@gmail.com 2014

vals = [];

for j = 1:length(COMPILED.readparams)
    m = COMPILED.readmodule(j);
    ptag = sch.readparams{j};
    if ptag(1) == '*', ptag(1) = []; end
    dt = char(RP(m).GetTagType(ptag));
    
    switch dt
        case {'I','S','L','A'}
            vals(j) = RP(m).GetTagVal(ptag); %#ok<AGROW>
            
            % case 'D' % Data Buffer - Add for future version
            
            % case 'P' % Coefficient buffer - Add for future version
            
        otherwise
            continue
    end
    
end