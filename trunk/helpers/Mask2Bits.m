function bits = Mask2Bits(mask,nbits)
% bits = Mask2Bits(mask)
% bits = Mask2Bits(mask,nbits)
% 
% Converts a bitmask to an array of bits.
% 
% The input mask must be a scalar integer.  An optional second input can be
% specified to determine the number of bits to return
% 
% Output will be an array of 1's and 0's (unit8).
% 
% ex:  mask = uint8(14);
%      bits = Mask2Bits(mask);
% 
% ex:  mask = uint8(14);
%      bits = Mask2Bits(mask,8);
% 
% See also, Bits2Mask
% 
% Daniel.Stolzberg@gmail.com 2014

narginchk(1,2);
assert(isscalar(mask),'mask input must be a scalar integer value.')
if nargin == 1 || isempty(nbits)
    nbits = 32;
end
assert(isscalar(nbits) && nbits>0,'nbits must be a scalar integer value greater than zero.')
nbits = uint8(nbits);

bits = zeros(1,nbits,'uint8');
try
    for i = 1:nbits
        bits(nbits-i+1) = bitget(mask,i);
    end
catch ME
    if ~strcmp(ME.identifier,'MATLAB:bitSetGet:BITOutOfRange'), rethrow(me); end
end



