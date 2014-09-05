function S = ReadDATags(DA,C,params)
% S = ReadDATags(DA,C)
% S = ReadDATags(DA,C,params)
% 
% 
% Reads current values from an RPvds circuit running on a TDT module into a
% structure S.
% 
% C is a single index the configuration structure
%   ex: S = ReadDATags(DA,C(2));
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


if nargin == 2
    params = C.COMPILED.readparams;
else
    ind = ismember(params,C.COMPILED.readparams);
    params = params(ind);
end

for i = 1:length(params)
    ptag = strrep(params{i},'.','_');
    
    switch C.COMPILED.datatype{i}
        case {'I','S','L','A'}
            S.(ptag) = DA.GetTargetVal(params{i});
            
        case 'D' % Data Buffer
            bufsze = DA.GetTargetSize(params{i});
            S.(ptag) = DA.ReadTargetV(params{i},0,bufsze);
            S.(ptag) = DA.ZeroTarget(params{i});
            
      % case 'P' % Coefficient buffer
            
        otherwise
            fprintf(2,'WARNING: The parameter "%s" has an unrecognized datatype (''%s''). Data not collected.',params{i},C.COMPILED.datatype{i}) %#ok<PRTCAL>
            continue
    end
    
end






