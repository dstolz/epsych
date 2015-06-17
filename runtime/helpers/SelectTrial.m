function varargout = SelectTrial(TRIALS,parameter)
%  val = SelectTrial(TRIALS,parameter)
%  [val,i] = SelectTrial(TRIALS,parameter)
%
% Select values from a particular trial index in the structure TRIALS.  For
% use with custom Trial Selection functions.  See help DefaultTrialSelectFcn
% for more info.
%
% NOTE: This function needs to be updated because the subfield TRIALS.tidx
% is no longer in use by ep_RunExpt.
%
% Daniel.Stolzberg@gmail.com 2015

val = nan;

[ind,i] = ismember(TRIALS.writeparams,parameter);
if any(ind)
    val = TRIALS.trials{TRIALS.TrialIndex,ind};
end

varargout{1} = val;
varargout{2} = logical(i);


