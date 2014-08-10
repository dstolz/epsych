function e = UpdateRPtags(RP,C)
% e = UpdateRPtags(RP,C)
% 
% RP is a handle (or array of handles) to the RPco.x returned from a call
% to SetupRPexp.
% 
% C is the CONFIGURATION structure returned from a call to SetupRPexpt.
% C is a single index the configuration structure and can be obtained
% during runtime by using getappdata with the handle to the subject box
% figure.  ex:
%       C = getappdata(BoxFig(1),'C'); 
%       UpdateRPtags(RP,C);
%   
% 
% C.NextIndex is the trial index which will be used to update parameter tags
% running on RPvds circuits
% 
% 
% See also, ReadRPtags, SetupRPexpt
% 
% Daniel.Stolzberg@gmail.com 2014


wp = C.COMPILED.writeparams;
wm = C.RPwrite_lut;

trial = C.COMPILED.trials(C.NextIndex,:);

for j = 1:length(wp)
    e = 0;
    m = wm(j);
    par = trial{j};
    
    if strfind(C.modmap{j},'PA5') % update PA5 module
        RP(m).SetAtten(par);
        
    else % update G_RP
               
        % * hides parameter tag from being updated
        if wp{j}(1) == '*', continue; end 
        
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
            RP(m).SetTagVal(['#' wp{j}],par.nsamps); 
            v = par.buffer;
            e = RP(m).WriteTagV(wp{j},0,v(:)');
            
        end
        
        if ~e
            fprintf(2,'** WARNING: Parameter: ''%s'' was not updated **\n',wp{j}) %#ok<PRTCAL>
        end
    end
end


