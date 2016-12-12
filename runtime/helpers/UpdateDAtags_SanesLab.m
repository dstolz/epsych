function e = UpdateDAtags_SanesLab(DA,TRIALS)
% e = UpdateDAtags(DA,TRIALS)
% 
% DA is a handle (or array of handles) to the OpenDeveloper ActiveX control
% returned from a calls to SetupDAexp.
% 
% 
% TRIALS.NextIndex is the trial index which will be used to update parameter tags
% running on RPvds circuits
% 
% 
% See also, ReadDAtags, SetupDAexpt
% 
% Daniel.Stolzberg@gmail.com 2014


wp = TRIALS.writeparams;

trial = TRIALS.trials(TRIALS.NextTrialID,:);

for i = 1:length(wp)
    e = 0;
    param = wp{i};

    if any(ismember(param,'*!')), continue; end
    
    par = trial{i};
    
    if TRIALS.randparams(i)
        par = par(1) + abs(diff(par)) .* rand(1);
    end

    if isstruct(par) && ~isfield(par,'buffer') 
        % file buffer (usually WAV file) that needs to be loaded
        wfn = fullfile(par.path,par.file);
        par.buffer = wavread(wfn);
        DA.SetTargetVal(['~' param '_Size'],par.nsamps);
        e = DA.WriteTargetV(param,0,single(par.buffer(:)'));
        
    elseif isstruct(par)
        % preloaded file buffer
        e = DA.WriteTargetV(param,0,single(par.buffer(:)'));
    
    elseif isscalar(par) % set value
        e = DA.SetTargetVal(param,par);
        
    end
    
    if ~e
        fprintf(2,'** WARNING: Parameter: ''%s'' was not updated **\n',param);
    end
end



