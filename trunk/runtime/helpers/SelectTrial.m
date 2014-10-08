function varargout = SelectTrial(C,parameter)
%  val = SelectTrial(C,parameter)
%  [val,i] = SelectTrial(C,parameter)

val = nan;

[ind,i] = ismember(C.writeparams,parameter);
if any(ind)
    val = C.trials{C.tidx,ind};
end

varargout{1} = val;
varargout{2} = i;


