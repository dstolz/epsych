function e = UpdateRPtags(RP,trial)
% e = UpdateRPtags(RP,trial)
% 
% RP is a handle (or handles) to the RPco.x
% 
% trial is a cell array chosen (by call to some trial selection function)
% from trials list compiled by ep_ExperimentDesign GUI
% 
% 
% see also, ep_ExperimentDesign
% 
% Daniel.Stolzberg@gmail.com 2014


for j = 1:length(sch.writemodule)
    e = 0;
    m = sch.writemodule(j);
    par = trial{j};
    
    if length(par) == 2 % random value between boundaries (from flat distr.)
        par = fix(par(1) + (par(2) - par(1)) .* rand(1));
    end
    
    if m < 0 % update G_PA5
        RP(abs(m)).SetAtten(par);
        
    else % update G_RP
        n = sch.writeparams{j};
        if n(1) == '*', continue; end % * hides parameter tag from being updated
        
        if isscalar(par) && ~isstruct(par)
            % set value
            e = RP(m).SetTagVal(n,par);

        elseif ~ischar(par) && ismatrix(par) && ~isstruct(par)
            % write buffer
            v = trial{j};
            e = RP(m).WriteTagV(n,0,reshape(v,1,numel(v)));
            
        elseif isstruct(par)
            % file buffer
            % set buffer size parameter : #buffername
            RP(m).SetTagVal(['#' n],par.nsamps); 
            v = par.buffer;
            e = RP(m).WriteTagV(n,0,v(:)');
            
        end
        
        if ~e
            fprintf('** WARNING: Parameter: ''%s'' was not updated **\n',n)
        end
    end
end


