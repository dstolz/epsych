function idx = wParamIdx(TRIALS,param)
% idx = wParamIdx(TRIALS,param)
%
% Helper function returns index to a write parameter (param).  
%
% Returns empty if the parameter is not found in TRIALS.writeparams.
%
% See also rParamIdx, SelectTrial
%
% Daniel.Stolzberg@gmail.com 2016

% Copyright (C) 2016  Daniel Stolzberg, PhD

idx = find(ismember(TRIALS.writeparams,param));