function S = ReadRPTags(RP,C,params)
% S = ReadRPTags(RP,C)
% S = ReadRPTags(RP,C,params)
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

if nargin == 2
    params = C.COMPILED.readparams;
    mptag  = C.COMPILED.Mreadparams;
    lut    = C.RUNTIME.RPread_lut;
else
    ind = ismember(params,C.COMPILED.readparams);
    params = params(ind);
    mptag = C.COMPILED.Mreadparams(ind);
    lut   = C.RUNTIME.RPread_lut(ind);
end

for i = 1:length(params)
    ptag = params{i};
    
    switch C.COMPILED.datatype{i}
        case {'I','S','L','A'}
            S.(mptag{i}) = RP(lut(i)).GetTagVal(ptag); 
            
        case 'D' % Data Buffer
            bufsze = RP(lut(i)).GetTagSize(ptag);
            S.(mptag{i}) = RP(lut(i)).ReadTagV(ptag,0,bufsze);
            RP(lut(i)).ZeroTag(ptag); % clear out buffer after reading
            
      % case 'P' % Coefficient buffer
            
        otherwise
            fprintf(2,'WARNING: The parameter "%s" has an unrecognized datatype (''%s''). Data not collected.',ptag,C.COMPILED.datatype{i}) %#ok<PRTCAL>
            continue
    end
    
end





