function S = ReadRPTags(RP,TRIALS,params)
% S = ReadRPTags(RP,TRIALS)
% S = ReadRPTags(RP,TRIALS,params)
% 
% 
% Reads current values from an RPvds circuit running on a TDT module into a
% structure S.
% 
% C is a single index the configuration structure
%   ex: S = ReadRPtags(RP,C(2));
% 
% RP is a handle (or array of handles) to the RPco.x returned from a call
% to SetupRPexp.
% 
% Optionally specify which parameter tag to read.
% 
% The fieldnames of the structure S are modified versions of parameter
% tag names being read from the circuit.
% 
% See also, UpdateRPtags, SetupRPexpt, ReadDATags
% 
% Daniel.Stolzberg@gmail.com 2014

% Copyright (C) 2016  Daniel Stolzberg, PhD

if nargin == 2
    params = TRIALS.readparams;
    ind = true(size(params));
else
    ind = ismember(params,TRIALS.COMPILED.readparams);
end
params   = params(ind);
mptag    = TRIALS.Mreadparams(ind);
lut      = TRIALS.RPread_lut(ind);
datatype = TRIALS.datatype(ind);

for i = 1:length(params)
    ptag = params{i};
    
    switch datatype{i}
        case {'I','S','L','A'}
            S.(mptag{i}) = RP(lut(i)).GetTagVal(ptag); 
            
        case 'D' % Data Buffer
            bufsze = RP(lut(i)).GetTagSize(ptag);
            S.(mptag{i}) = RP(lut(i)).ReadTagV(ptag,0,bufsze);
            RP(lut(i)).ZeroTag(ptag); % clear out buffer after reading
            
      % case 'P' % Coefficient buffer
            
        otherwise
            fprintf(2,'WARNING: The parameter "%s" has an unrecognized datatype (''%s''). Data not collected.',ptag,RUNTIME.COMPILED.datatype{i}) %#ok<PRTCAL>
            continue
    end
    
end





