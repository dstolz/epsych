function idx = rParamIdx(TRIALS,param)
% idx = rParamIdx(TRIALS,param)
%
% Helper function returns index to a read parameter (param).  
%
% Returns empty if the parameter is not found in TRIALS.readparams.
%
% See also wParamIdx
% 
% Daniel.Stolzberg@gmail.com 2016

idx = find(ismember(TRIALS.readparams,param));