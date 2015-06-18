function varargout = shapedata_wave(wave,tvec,params,dimparams,varargin)
% data = shapedata_wave(wave,tvec,params,dimparams)
% data = shapedata_wave(...,'PropertyName',PropertyValue)
% [data,vals] = shapedata_wave(...) 
%
% Reshapes continuously sampled data based on some parameters (dimparams)
%
% PropertyName   ... PropertyValue
% 'win'          ... window (eg, [-0.1 0.5]) in seconds
% 'func'         ... function to compute response magnitude (default = "mean")
% 'returntrials' ... if true, returns an extra dimension with each trial
%                           (default = false)
% 
% Daniel.Stolzberg@gmail.com 2013
%
% See also, shapedata_spikes, DB_GetWave


win = [0 0.1];
returntrials = false;
func         = 'mean';

ParseVarargin({'win','returntrials'},[],varargin);

Fs = params.wave_fs;

% sort trials by onsets
ons = params.VALS.onset;

winsamps = floor(Fs*win(1)):round(Fs*win(2));

% tdata:   samples/trials
tdata = zeros(length(winsamps),length(ons));

for i = 1:length(ons)
    idx = find(tvec>=ons(i),1);
    if isempty(idx)
        error('Trigger onset occurred after time vector: trigger# %d',i)
    end
    idx = idx + winsamps;
    tdata(:,i) = wave(idx);
end

for i = 1:length(dimparams)
    vals{i} = params.lists.(dimparams{i});
end

if length(vals) == 1
    % data:    samples/param1
    if ~returntrials
        data = zeros(length(winsamps),length(vals{1}));
    end
    for i = 1:length(vals{1})
        ind = params.VALS.(dimparams{1}) == vals{1}(i);
        if returntrials
            data(:,:,i) = tdata(:,ind);
        else
            data(:,i) = feval(func,tdata(:,ind),2);
        end
    end
    
    
elseif length(dimparams) == 2
    % data:    samples/param1/param2
    data = zeros(length(winsamps),length(vals{1}),length(vals{2}));
    for i = 1:length(vals{1})
        for j = 1:length(vals{2})
            ind = params.VALS.(dimparams{1}) == vals{1}(i) ...
                & params.VALS.(dimparams{2}) == vals{2}(j);
            if returntrials
                data(:,:,i,j) = tdata(:,ind);
            else
                data(:,i,j) = feval(func,tdata(:,ind),2);
            end
        end
    end
    
    
elseif length(dimparams) == 3
    % data:    samples/param1/param2/param3
    data = zeros(length(winsamps),length(vals{1}),length(vals{2}),length(vals{3}));
    for i = 1:length(vals{1})
        for j = 1:length(vals{2})
            for k = 1:length(vals{3})
                ind = params.VALS.(dimparams{1}) == vals{1}(i) ...
                    & params.VALS.(dimparams{2}) == vals{2}(j) ...
                    & params.VALS.(dimparams{3}) == vals{3}(k);
                if returntrials
                    data(:,:,i,j,k) = tdata(:,ind);
                else
                    data(:,i,j,k) = feval(func,tdata(:,ind),2);
                end
            end
        end
    end

end


varargout{1} = data;

if returntrials
    vals = [1:size(data,2) vals];
end
varargout{2} = [{winsamps},vals];






