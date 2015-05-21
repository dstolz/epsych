function e = UpdateRPtags(RP,TRIALS)
% e = UpdateRPtags(RP,TRIALS)
% 
% RP is a handle (or array of handles) to the RPco.x returned from a call
% to SetupRPexp.
%   
% 
% TRIALS.NextIndex is the trial index which will be used to update parameter tags
% running on RPvds circuits
% 
% 
% See also, ReadRPtags, SetupRPexpt
% 
% Daniel.Stolzberg@gmail.com 2014


wp = TRIALS.writeparams;
wm = TRIALS.RPwrite_lut;

trial = TRIALS.trials(TRIALS.NextTrialID,:);

for i = 1:length(wp)
    e = 0;
    m = wm(i);
    par = trial{i};
    param = wp{i};

    
    if TRIALS.randparams(i)
        par = par(1) + abs(diff(par)) .* rand(size(TRIALS.trials,1),1);
    end
    
    if strcmp(param,'SetAtten') % update PA5 module
        RP(m).SetAtten(par);
        
    else % update G_RP
               
        % * hides parameter tag from being updated
        % ! indicates a custom trigger
        if any(param(1) == '*!'), continue; end 
        
        if isscalar(par) && ~isstruct(par)
            % set value
            e = RP(m).SetTagVal(param,par);

        elseif ~ischar(par) && ismatrix(par) && ~isstruct(par)
            % write buffer
            v = trial{i};
            e = RP(m).WriteTagV(param,0,reshape(v,1,numel(v)));
            
        elseif isstruct(par)
            % file buffer
            % set buffer size parameter : #buffername
            RP(m).SetTagVal(['~' param '_Size'],par.nsamps); 
            v = par.buffer;
            e = RP(m).WriteTagV(param,0,v(:)');
            
        end
        
        if ~e
            fprintf(2,'** WARNING: Parameter: ''%s'' was not updated **\n',param) %#ok<PRTCAL>
        end
    end
end


