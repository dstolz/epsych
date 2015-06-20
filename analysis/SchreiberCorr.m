function [Rcorr,nRcorr] = SchreiberCorr(S)
% Rcorr = SchreiberCorr(S)
% [Rcorr,nRcorr] = SchreiberCorr(S)
%
% Implements spike-train reliability measure introduced by Schreiber et al,
% 2003.  An Rcorr approaching 1 indicates very high spike-time reliability
% across trials, whereas Rcorr approaching 0 indicates very poor
% reliability across trials.
% 
% S is an MxN matrix of binned data with N observations (trials) and M samples
% (bins).  Typically, the matrix S will aready have been convolved
% with a a gaussian window (see reference).
% 
% The optional output nRcorr is the correlation value based on a random
% permutation of S.  This value is affected by the total number of events
% (spikes) in S.  It may be useful to subtract nRcorr from Rcorr in order
% to correct for bias based on the number of spikes (untested suggestion).
% 
% Reference: Schreiber et al, 2003 Neurocomputing 52-54, p925-931
% 
% Daniel.Stolzberg@gmail.com 2014

S(:,~any(S)) = [];

if isempty(S)
    Rcorr  = nan;
    nRcorr = nan;
    return
end

Rcorr = ComputeRCorr(S);

if nargout == 2
    idx = randperm(numel(S));
    idx = reshape(idx,size(S));
    nRcorr = ComputeRCorr(S(idx));
end




function Rcorr = ComputeRCorr(S)
N = size(S,2);
A = 0;
for i = 1:N
    for j = i+1:N
        A = A + (S(:,i)' * S(:,j) / (norm(S(:,i)) * norm(S(:,j))));
    end
end

Rcorr = 2/(N*(N-1)) * A;





