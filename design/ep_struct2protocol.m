function protocol = ep_struct2protocol(T,Options,Info)
% protocol = ep_struct2protocol(T,[Options],[Info])
%
% Manually create a Protocol structure for use with ep_Ephys and
% ep_RunExpt.  This is useful for complete control over trial presentation
% order. 
%
% T is a structure with hardware module aliases as field names.  Subfields
% for each module alias all must contain an Nx1 array of values.  Subfields
% may contain numeric values or an Nx1 array of cell strings pointing to
% wav or mat files.  mat files must have a variable named 'buffer' with a
% one-dimensional array of numeric values.
%
%   format:  T.ModuleAlias.ParameterTag
%
%     ex:
%           T.Stim.ToneFreq     = [1000*ones(10,1); 2000*ones(10,1)];
%           T.Stim.ToneCalibrationFile = 'C:\some\Calibration\file.cal';
%               % This calibration file will be used to calibrate the previous
%               % 'ToneFreq' subfield.  This 'ToneCalibrationFile' subfield will
%               % be discarded from the final protocol output
%           T.Stim.TonedBSPL    = 60 + randn(20,1);
%           T.Stim.ToneDuration = 100 * ones(20,1);
%           T.Stim.WaveBuffer   = [repmat({'TEST_1.wav'},5,1); repmat({'TEST_2.wav'},5,1)];
%           
%
% Options can be specified as a structure with the following fields:
%   .ISI                ... Inter-Stimulus (trigger) Interval in ms (default = 1000 ms)
%   .trialfunc          ... Function name or handle. Must be on Matlab's search path
%   .UseOpenEx          ... True f using with OpenEx software (default = true)
%   .ConnectionType     ... 'USB' or 'GB' (default)
%   .IncludeWAVBuffers  ... Load buffers (wav or mat) at Runtime if false (default = true)
%   .optcontrol         ... True to use an external trigger instead of the
%                           'TrialTrigger' macro in RPvds (default = false)
%
% Info is an optional string to carry some description of the protocol.
%   Defaults to the current date.
%
%
% Output:
%   Output variable must be called: protocol
%   protocol structure the following:
%       protocol.COMPILED.writeparams
%       protocol.COMPILED.readparams
%       protocol.COMPILED.randparams
%       protocol.COMPILED.trials
%       protocol.COMPILED.OPTIONS
%       protocol.INFO
%
% *Important note:  Save the protocol strucuture to a file using the
%   following save syntax:
%       >> save('MyNewProtocol.prot','protocol','-mat')
% 
% See also, ep_ExperimentDesign
%
% Daniel.Stolzberg@gmail.com (c) 10/2016


assert(isstruct(T),'Input T must be as structure')


Ofns = {'randomize', 'compile_at_runtime', 'ISI', 'num_reps', 'trialfunc', ...
    'optcontrol','UseOpenEx','ConnectionType','IncludeWAVBuffers'};
Odft = {1,0,1000,1,[],0,1,'GB','on'};
for i = 1:length(Ofns)
    if nargin < 2 || isempty(Options) || ~isfield(Options,Ofns{i})
        Options.(Ofns{i}) = Odft{i}; 
    end
end

if nargin < 3
    Info = sprintf('Created on %s using ep_mat2protocol.m',datestr(now));
end

Mnames = fieldnames(T)';

k = 1;
for i = 1:length(Mnames)
    M = T.(Mnames{i});
    Tnames = fieldnames(M)';
    for j = 1:length(Tnames)
        V = M.(Tnames{j});
        if ischar(V) && exist(V,'file')
            % calibrate previous variable (??)
            C = load(V,'-mat');
            cV = zeros(size(N,1),2);
            cV(:,1) = Calibrate(cell2mat(N(:,end)),C);
            cV(:,2) = C.hdr.cfg.ref.norm;
            extraNames{1} = sprintf('%s.~%s_Amp',Mnames{i},Tnames{j-1});
            extraNames{2} = sprintf('%s.~%s_norm',Mnames{i},Tnames{j-1});
            N(:,k:k+1) = num2cell(cV);
            P(1,k:k+1) = extraNames;
            
        elseif iscell(V)
            if Options.IncludeWAVBuffers
                if ischar(V{1}) && exist(V{1},'file')
                    b = unique(V);
                    
                    for e = 1:length(V)
                        bID = find(ismember(b,V{e}));
                        ext = V{e}(find(V{e}=='.',1,'last')+1:end);
                        switch lower(ext)
                            case 'wav'
                                [Y,~] = wavread(V{e},'double');
                                
                                s.buffer = Y;
                                s.nsamps = length(Y);
                                
                            case 'mat'
                                if isempty(who('-file',pfn,'buffer'))
                                    errordlg(sprintf(['The file ''%s'' does not contain the ', ...
                                        'variable ''buffer'''],V{e}),'Missing Variable ''buffer''')
                                    return
                                end
                                
                                s = load(V{e});
                                s.buffer = s.buffer(:);
                                s.nsamps = length(s.buffer);
                                
                            otherwise
                        end
                        V = cell(1,3);
                        V{e,1} = s.buffer;
                        V{e,2} = s.nsamps;  extraNames{1} = sprintf('%s.~%s_Size',Mnames{i},Tnames{j});
                        V{e,3} = bID;       extraNames{2} = sprintf('%s.~%s_ID',Mnames{i},Tnames{j});
                    end
                end
            end
            N(:,k:k+size(V,2)-1) = V;
            P(1,k:k+length(extraNames)) = [{sprintf('%s.%s',Mnames{i},Tnames{j})} extraNames];

        else
            if ~iscell(V), V = num2cell(V); end
            N(:,k) = V(:);
            P{1,k} = sprintf('%s.%s',Mnames{i},Tnames{j});
        end
        k = size(N,2)+1;
        
    end    
end


protocol.COMPILED.writeparams = P;
protocol.COMPILED.readparams  = P;
protocol.COMPILED.randparams  = zeros(size(P));
protocol.COMPILED.trials      = N;
protocol.COMPILED.OPTIONS = Options;
protocol.OPTIONS.compile_at_runtime = Options.compile_at_runtime;
protocol.INFO = Info;




























