function S = ReadDATags(DA,P,params)
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


if nargin == 2
    params = P.COMPILED.readparams;
else
    ind = ismember(params,P.COMPILED.readparams);
    params = params(ind);
end

for i = 1:length(params)
    ptag = strrep(params{i},'.','_');
    
    switch P.COMPILED.datatype{i}
        case {'I','S','L','A'}
            S.(ptag) = DA.GetTargetVal(params{i});
            
        case 'D' % Data Buffer
            bufsze = DA.GetTargetSize(params{i});
            S.(ptag) = DA.ReadTargetV(params{i},0,bufsze);
            S.(ptag) = DA.ZeroTarget(params{i});
            
      % case 'P' % Coefficient buffer
            
        otherwise
            fprintf(2,'WARNING: The parameter "%s" has an unrecognized datatype (''%s''). Data not collected.',params{i},P.COMPILED.datatype{i}) %#ok<PRTCAL>
            continue
    end
    
end






