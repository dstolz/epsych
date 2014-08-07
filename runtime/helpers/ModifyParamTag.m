function mptag = ModifyParamTag(ptag,c)
% mptag = ModifyParamTag(ptag)
% 
% Helper function that takes a string and replaces non-alphanumeric values
% with underscores (or optionally, c).
% 
% Daniel.Stolzberg@gmail.com

if nargin == 2
    assert(ischar(c) && isscalar(c), 'If specified, c must be a single character');
else
    c = '_';
end

ind = isstrprop(ptag,'alphanum');
mptag = ptag;
mptag(~ind) = c;
mptag = genvarname(mptag);
