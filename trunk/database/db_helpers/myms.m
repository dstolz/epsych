function varargout = myms(str)
% varargout = myms(str)
%
% Wrapper function for mym.
%
% Returns individual outputs instead of a single structure.
% 
% Use sprintf instead of normal mym inline placeholders like {Si}
%
% DJS 2013
%
% See also, sprintf, mym

try
    varargout = struct2cell(mym(str));
catch %#ok<CTCH>
    varargout{1} = [];
end

