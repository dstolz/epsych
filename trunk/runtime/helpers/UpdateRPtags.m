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

trial = TRIALS.trials(TRIALS.NextIndex,:);

for j = 1:length(wp)
    e = 0;
    m = wm(j);
    par = trial{j};
    
    if strcmp(wp{j},'SetAtten') % update PA5 module
        RP(m).SetAtten(par);
        
    else % update G_RP
               
        % * hides parameter tag from being updated
        % ! indicates a custom trigger
        if any(wp{j}(1) == '*!'), continue; end 
        
        if isscalar(par) && ~isstruct(par)
            % set value
            e = RP(m).SetTagVal(wp{j},par);

        elseif ~ischar(par) && ismatrix(par) && ~isstruct(par)
            % write buffer
            v = trial{j};
            e = RP(m).WriteTagV(wp{j},0,reshape(v,1,numel(v)));
            
        elseif isstruct(par)
            % file buffer
            % set buffer size parameter : #buffername
            RP(m).SetTagVal(['~' wp{j} '_Size'],par.nsamps); 
            v = par.buffer;
            e = RP(m).WriteTagV(wp{j},0,v(:)');
            
        end
        
        if ~e
            fprintf(2,'** WARNING: Parameter: ''%s'' was not updated **\n',wp{j}) %#ok<PRTCAL>
        end
    end
end


