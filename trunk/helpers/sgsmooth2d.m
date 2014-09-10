function smdata = sgsmooth2d(data,K,F)
% smdata = sgsmooth2d(data)
% smdata = sgsmooth2d(data,K,F)
%
% Applies Savitsky-Golay smoothing filter to rows and columns of data.
%
% Smoothing adapted from Adam Dziorny's data analysis code
% original parameters from Adam's code: K = 10; F = 4;
%
% DJS (c) 2010

if ~exist('K','var') || isempty(K), K = 10; end

if ~exist('F','var') || isempty(F), F = 4;  end

[nrow, ncol] = size(data);


if rem(floor(ncol/F),2)
    smdata = sgolayfilt(data, floor(ncol/K), floor(ncol/F),[], 2); 
else
    smdata = sgolayfilt(data, floor(ncol/K), floor(ncol/F)+1,[], 2); 
end

if rem(floor(nrow/F),2)
    smdata = sgolayfilt(smdata, floor(nrow/K), floor(nrow/F),[], 1);
else
    smdata = sgolayfilt(smdata, floor(nrow/K), floor(nrow/F)+1,[], 1);
end
