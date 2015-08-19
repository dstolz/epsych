function e = enow(n2,n1)
% e = enow(n2,n1)
% 
% Helper function to compute elapsed time between scalar values returned
% from calls to NOW function.
% 
% Inputs can also be matrices of equal number of elements.
% 
% Converts NOW values to [y,m,d,h,min,s] and calls ETIME.
% 
% Daniel.Stolzberg@gmail.com 2015

assert(numel(n1)==numel(n2),'Number of elements in n1 must equal n2')

e = zeros(size(n1));
for i = 1:numel(n1)
    e(i) = etime(datevecmx(n2(i),true),datevecmx(n1(i),true));
end