function out = dround(in,prec)

if( nargin < 2 )
    prec    =   100;
end

out     =   round( in * prec) / prec;