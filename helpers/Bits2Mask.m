function mask = Bits2Mask(bits)
% mask = Bits2Mask(data)
% 
% Converts an array of bits to a bitmask.
% 
% Input must be a 1xn or nx1 array of integers or logical values.
% 
% Output is a scalar unsigned integer (uint32).
% 
% ex: bits = [0 1 1 1 0]; 
%     mask = Bits2Mask(bits)
% 
% See also, Mask2Bits
% 
% Daniel.Stolzberg@gmail.com

% narginchk(1,1);
assert(isvector(bits),'Input must be a vector.')

bits = bits(:)';
mask = uint32(sum(bits.*2.^(0:length(bits)-1)));
