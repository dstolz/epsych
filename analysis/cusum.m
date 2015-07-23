function S = cusum(D,theta)
% S = cusum(D)
% S = cusum(D,theta)
% 
% Computes the CUSUM of vector D.
% 
% theta is a function handle to compute the "quality number" which is a
% parameter of the probility distrubution.  The default is @mean.  Other
% examples can be @var, @std, @median, or the handle to some custom
% function.
% 
% S will be returned the same size as D with the first row set to 0.
% 
% Daniel.Stolzberg@gmail.com 2015


assert(isvector(D),'D must be a vector')
if nargin == 1 || isempty(theta), theta = @mean; end
assert(isa(theta,'function_handle'), 'theta parameter must be a function handle')

S = zeros(size(D));
for i = 2:numel(D)
    Xbar = feval(theta,D(1:i));
    S(i) = S(i-1)+(D(i)-Xbar);
end








