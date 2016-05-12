function e = DAUpdateParams(DA,C)
% DAUpdateParams(DA,C)
% 
% Updates parameters on modules.  Use ProtocolDesign GUI.
%
% DA is handle to OpenDeveloper ActiveX control
% C is the protocol.COMPILED structure
%
% '*' as the first character of a parameter tag serves as ignore flag.
% This is useful if you want something to be updated by a custom
% trial-select function after being modified
%
% Note on Programmable Attenuators (PA5 and RZ6):
% > TDT programmable attenuators produce a transient voltage (strong enough
% to drive a speaker) therefore this function will automatically use small
% steps from previous attenuation value to new attenuation value on PA5
% rather than a big jump to avoid switching transients (DS 9/24/13)
% > RZ6 module has an integrated programmable attenuator which suffers from
% the same large transient during switching. If a parameter tag pointing to
% the programmable attenuator in the RPvds macro has 'Atten' as the last 5
% characters (could be 'ChA_Atten' or 'ChB_Atten', etc) then this function
% will automatically use small steps from the previous attenuation value to
% the new attenuation value rather than a big jump to avoid switching
% transients (DS 10/4/13)  ** This is still not very effective.  Recommend
% using constant PA5 attenuation and adjusting voltage of ADC ** (DS 3/14)
% 
% See also, ProtocolDesign, EPhysController
%
% DJS 2013

trial = C.trials(C.tidx,:);


for j = 1:length(trial)
    param = C.writeparams{j};

    if any(param=='*'), continue; end 
    
    par = trial{j};
    
    if isstruct(par) % file buffer (usually WAV file)
        if ~isfield(par,'buffer')
            wfn = fullfile(par.path,par.file);
            if ~exist(wfn,'file')
                par.buffer = [];
            else
                switch upper(par.file(end-2:end))
                    case 'WAV'
                        %                 par.buffer = wavread(wfn);
                        [par.buffer,~] = audioread(wfn);
                    case 'MAT'
                        par = load(wfn,'buffer');
                        
                end
                
            end
        end
        
        e = DA.WriteTargetVEX(param,0,'F32',par.buffer(:)');
    
    elseif isscalar(par) % set value
        
        if isequal('PA5',param(1:3)) || strcmpi('Atten',param(end-4:end))
            pa = DA.GetTargetVal(param);
            if pa < par, a = pa:5:par; else a = pa:-5:par; end
            for i = a, DA.SetTargetVal(param,i); pause(0.01); end
        end
        
        e = DA.SetTargetVal(param,par);
    end
    
    if ~e
        fprintf(2,'** WARNING: Parameter: ''%s'' was not updated **\n',param);
    end
end
