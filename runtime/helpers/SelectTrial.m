function varargout = SelectTrial(TRIALS,parameter)
%  val = SelectTrial(TRIALS,parameter)
%  [val,i] = SelectTrial(TRIALS,parameter)
%
% Select values from a particular trial index in the structure TRIALS.  For
% use with custom Trial Selection functions.  See help DefaultTrialSelectFcn
% for more info.
%
% NOTE: This function needs to be updated because the subfield TRIALS.tidx
% is no longer in use by ep_RunExpt, but is still used by ep_EPhys
%
% Daniel.Stolzberg@gmail.com 2015

% Copyright (C) 2016  Daniel Stolzberg, PhD

val = nan;

if isfield(TRIALS,'tidx')
    id = TRIALS.tidx;

elseif isfield(TRIALS,'NextTrialID')
    id = TRIALS.NextTrialID;

else
    id = 1; 
end 

[ind,i] = ismember(TRIALS.writeparams,parameter);
if any(ind)
    val = TRIALS.trials{id,ind};
end

varargout{1} = val;
varargout{2} = logical(i);


