function S = ReadDATags(DA,TRIALS,params)
% S = ReadDATags(DA,P)
% S = ReadDATags(DA,P,params)
% 
% 
% Reads current values from an RPvds circuit running on a TDT module into a
% structure S.
% 
% P is a Protocol structure (typical a field in the CONFIG
% structure)
%   ex: S = ReadDATags(DA,CONFIG(1).PROTOCOL);
% 
% DA is the handle to the OpenDeveloper ActiveX control.
% 
% Optionally specify which parameter tag to read.
% 
% The fieldnames of the structure S are modified versions of parameter
% tag names being read from the circuit.
% 
% See also, UpdateDAtags, SetupDAexpt, ReadRPtags
% 
% Daniel.Stolzberg@gmail.com 2014

% Copyright (C) 2016  Daniel Stolzberg, PhD

if nargin == 2
    params = TRIALS.readparams;
    ind = true(size(params));
else
    ind = ismember(params,TRIALS.COMPILED.readparams);
end
params = params(ind);
mptag  = TRIALS.Mreadparams(ind);
datatype = TRIALS.datatype(ind);


for i = 1:length(params)
    ptag = params{i};
    
    switch datatype{i}
        case {'I','S','L','A'}
            S.(mptag{i}) = DA.GetTargetVal(ptag);
            
        case 'D' % Data Buffer
            bufsze = DA.GetTargetSize(ptag);
            S.(mptag{i}) = DA.ReadTargetV(ptag,0,bufsze);
            S.(mptag{i}) = DA.ZeroTarget(ptag);
            
      % case 'P' % Coefficient buffer
            
        otherwise
            fprintf(2,'WARNING: The parameter "%s" has an unrecognized datatype (''%s''). Data not collected.',ptag,datatype{i}) %#ok<PRTCAL>
            continue
    end
    
end






