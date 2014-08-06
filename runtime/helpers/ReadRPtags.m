function vals = ReadRPtags(RP,COMPILED)
% vals = ReadRPtags(RP,COMPILED)
% 
% Daniel.Stolzberg@gmail.com 2014

% TO DO:  IT MAY BE BETTER TO RETURN A STRUCTURE RATHER THAN AN ARRAY OF
% VALUES.  THIS WOULD MAKE IT EASIER TO RETURN VARIOUS DATA TYPES AND THE
% FIELDNAMES CAN BE THE VARIABLE NAME (AS LONG AS SPECIAL CHARACTERS ARE
% SUBSTITED,ex: '~')

vals = {[]};

for j = 1:length(COMPILED.readparams)
    
    m = COMPILED.RPread_lut(j);
    ptag = COMPILED.readparams{j};
    if ptag(1) == '*', ptag(1) = []; end
    dt = char(RP(m).GetTagType(ptag));
    
    switch dt
        case {'I','S','L','A'}
            vals{j} = RP(m).GetTagVal(ptag); %#ok<AGROW>
            
            % case 'D' % Data Buffer - Add for future version
            
            % case 'P' % Coefficient buffer - Add for future version
            
        otherwise
            continue
    end
    
end