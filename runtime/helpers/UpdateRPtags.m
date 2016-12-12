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
    
    % * hides parameter tag from being updated
    % ! indicates a custom trigger
    if any(param(1) == '*!'), continue; end
    
    if TRIALS.randparams(i)
        par = par(1) + abs(diff(par)) .* rand(1);
    end
    
    if strcmp(param,'SetAtten') % update PA5 module
        RP(m).SetAtten(par);
        
    else % update G_RP
        
        if isscalar(par) && isstruct(par) && ~isfield(par,'buffer') 
            % file buffer (usually WAV file) that needs to be loaded
            wfn = fullfile(par.path,par.file);
            par.buffer = wavread(wfn);
            RP(m).SetTagVal(['~' param '_Size'],par.nsamps); 
            e = RP(m).WriteTagV(param,0,par.buffer(:)');
            
        elseif isstruct(par) && isfield(par,'buffer') 
            % preloaded file buffer
            e = RP(m).WriteTagV(param,0,par.buffer(:)');
        
        elseif isscalar(par)
            % set value
            e = RP(m).SetTagVal(param,par);
            

         elseif ~ischar(par) && ismatrix(par) && ~isstruct(par)
             % write buffer
             e = RP(m).WriteTagV(param,0,reshape(par,1,numel(par)));
            
        end
        
        if ~e
            vprintf(0,1,'** WARNING: Parameter: ''%s'' was not updated **',param)
        end
    end
end


