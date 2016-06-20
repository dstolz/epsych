function varargout = shapedata_spikes(spiketimes,P,dimparams,varargin)
% data = shapedata_spikes(spiketimes,P,dimparams)
% data = shapedata_spikes(...,'PropertyName',PropertyValue)
% [data,vals] = shapedata_spikes(...) 
% [data,vals,raster] = shapedata_spikes(...) 
%
% Returns an N+1-dimensional matrix which can be used for analysis and
% plotting.  The number of dimensions N of the return matrix, data, is
% dependent on the number of dimensions specified in dimparams. An
% additional dimension (hence N+1) is the bins of the data histogram.
%
% dimparams is an Nx1 cell matrix of strings specifying what dimensions the
% data should be shaped.  The values in dimparams are dependent on how the
% parameters are coded and can be found on the database and in the
% structure returned from a call to DB_GetParams.
% ex: P = DB_GetParams(block_id);
%       % or
%     P = DB_GetParams(unit_id,'unit');
%     P.param_type   % <-- will list parameters for this protocol
% 
% [data,vals] = shapedata_spikes(...) 
% The second output, vals, is a cell array with the parameter values
% corresponding to the dimensions of data.
%
% [data,vals,raster] = shapedata_spikes(...) 
% Returns a cell array with the spike times of individual trials adjusted
% for stimulus onset time.
% 
% For example, if we have noise-burst intensity function, we can sort raw
% spiketime into average responses within a 50 millisecond window following
% stimulus onset (returns a 2D matrix):
%   % note: The id of a unit can be found using the DB_Browser utility
%   Spiketimes = DB_GetSpiketimes(unit_id);
%   P = DB_GetParams(unit_id,'unit');
%   [data,vals] = shapedata_spikes(Spiketimes,P,{'Levl'},'win',[0 0.05]);
%   figure;
%   subplot(211)
%   plot(vals{2},mean(data),'-o');
%   xlabel('Sound Level (dB)'); ylabel('Mean Response Magnitude');
%   subplot(212)
%   imagesc(vals{1},vals{2},data'); % note that data must be transposed to
%   be properly displayed
%   set(gca,'ydir','normal');
%   xlabel('Time (s)'); ylabel('Sound Level(dB)');
% 
% Example where two parameters are in use (returns a 3D matrix):
%   Spiketimes = DB_GetSpiketimes(unit_id);
%   P = DB_GetParams(unit_id,'unit');
%   binsize = 0.001; % for computing mean firing rate
%   [data,vals] = shapedata_spikes(Spiketimes,P,{'Freq','Levl'},'win',[0 0.05],'binsize',binsize);
%   FRA = squeeze(mean(data))'/binsize; % average trials and convert to firing rate
%   figure;
%   surf(vals{2},vals{3},FRA);
%   shading flat
%   xlabel('Frequency (Hz)'); 
%   ylabel('Sound Level (dB)');
%   zlabel('Mean Firing Rate (Hz)');
% 
% 
% Example where individual trials are returned as an extra dimension:
%   Spiketimes = DB_GetSpiketimes(unit_id);
%   P = DB_GetParams(unit_id,'unit');
%   [data,vals] = shapedata_spikes(Spiketimes,P,{'Levl'},'win',[0 0.05],'returntrials',true);  
%   whos data vals
%
% PropertyName   ... PropertyValue
% 'win'          ... window in seconds (default = [0 0.05])
% 'binsize'      ... in seconds (default = 0.001 s)
% 'func'         ... function to compute response magnitude (default = "mean")
% 'returntrials' ... if true, returns an extra dimension with each trial
%                           (default = false)
% 
% Daniel.Stolzberg@gmail.com 2013
%
% See also, shapedata_wave, DB_GetSpiketimes, DB_GetParams

win          = [0 0.05];
binsize      = 0.001;
func         = 'mean';
returntrials = false;

ParseVarargin({'win','binsize','func','returntrials'},[],varargin);

assert(isstruct(P),'Input ''P'' must be a structure returned from DB_GetParams')
assert(numel(win) == 2,'Invalid format for parameter: ''win''')

binvec = win(1):binsize:win(2)-binsize;

% sort spikes by onsets
ons = P.VALS.onset;
raster = cell(size(ons));

% psth:   bins/trials
psth = zeros(length(binvec),length(ons));

% first rearrange data based on stimulus onsets
for i = 1:length(ons)
    ind = spiketimes-ons(i) >= win(1) & spiketimes-ons(i) < win(2);
    if ~any(ind), continue; end
    raster{i} = spiketimes(ind)-ons(i);
    psth(:,i) = histc(raster{i},binvec);
end

% select parameter for dimensions
for i = 1:length(dimparams)
    vals{i} = P.lists.(dimparams{i}); %#ok<AGROW>
end

% sort raster/psth by first dimension parameter
[~,i] = sort(P.VALS.(dimparams{1}));
if nargout == 3
    raster = raster(i);
    n = length(P.lists.(dimparams{1}));
    lrn = length(raster)/n;
    if rem(lrn,1)
        warning('shapedata_spikes:Unable to reshape raster because it would create an non-square matrix')
    else
        raster = reshape(raster,lrn,n);
    end
end
psth   = psth(:,i);

P.VALS = structfun(@(x) (x(i)),P.VALS,'UniformOutput',false);

ndp = length(dimparams);

% THERE'S PROBABLY A MORE CLEVER WAY OF DOING THIS...
if returntrials
    if ndp == 1 %#ok<UNRCH>
        % data:    bins/trials/param1
        ind = P.VALS.(dimparams{1}) == vals{1}(1);
        data = nan(length(binvec),sum(ind),length(vals{1}));
        for i = 1:length(vals{1})
            ind = P.VALS.(dimparams{1}) == vals{1}(i);
            data(:,1:sum(ind),i) = psth(:,ind);
        end
        
        
    elseif ndp == 2
        % data:    bins/trials/param1/param2
        ind = P.VALS.(dimparams{1}) == vals{1}(1) ...
            & P.VALS.(dimparams{2}) == vals{2}(1);
        data = zeros(length(binvec),sum(ind),length(vals{1}),length(vals{2}));
        for i = 1:length(vals{1})
            for j = 1:length(vals{2})
                ind = P.VALS.(dimparams{1}) == vals{1}(i) ...
                    & P.VALS.(dimparams{2}) == vals{2}(j);
                data(:,:,i,j) = psth(:,ind);
            end
        end
        
        
    elseif ndp == 3
        % data:    bins/trials/param1/param2/param3
        ind = P.VALS.(dimparams{1}) == vals{1}(1) ...
            & P.VALS.(dimparams{2}) == vals{2}(1) ...
            & P.VALS.(dimparams{3}) == vals{3}(1);
        data = zeros(length(binvec),sum(ind),length(vals{1}),length(vals{2}),length(vals{3}));
        for i = 1:length(vals{1})
            for j = 1:length(vals{2})
                for k = 1:length(vals{3})
                    ind = P.VALS.(dimparams{1}) == vals{1}(i) ...
                        & P.VALS.(dimparams{2}) == vals{2}(j) ...
                        & P.VALS.(dimparams{3}) == vals{3}(k);
                    data(:,:,i,j,k) = psth(:,ind);
                end
            end
        end
        
    end
    varargout{2} = [{binvec},1:size(data,2),vals];
else
    if ndp == 1
        % data:    bins/param1
        data = zeros(length(binvec),length(vals{1}));
        for i = 1:length(vals{1})
            ind = P.VALS.(dimparams{1}) == vals{1}(i);
            data(:,i) = feval(func,psth(:,ind),2);
        end
        
        
    elseif ndp == 2
        % data:    bins/param1/param2
        data = zeros(length(binvec),length(vals{1}),length(vals{2}));
        for i = 1:length(vals{1})
            for j = 1:length(vals{2})
                ind = P.VALS.(dimparams{1}) == vals{1}(i) ...
                    & P.VALS.(dimparams{2}) == vals{2}(j);
                data(:,i,j) = feval(func,psth(:,ind),2);
            end
        end
        
        
    elseif ndp == 3
        % data:    bins/param1/param2/param3
        data = zeros(length(binvec),length(vals{1}),length(vals{2}),length(vals{3}));
        for i = 1:length(vals{1})
            for j = 1:length(vals{2})
                for k = 1:length(vals{3})
                    ind = P.VALS.(dimparams{1}) == vals{1}(i) ...
                        & P.VALS.(dimparams{2}) == vals{2}(j) ...
                        & P.VALS.(dimparams{3}) == vals{3}(k);
                    data(:,i,j,k) = feval(func,psth(:,ind),2);
                end
            end
        end
        
    end
varargout{2} = [{binvec},vals];    
end

varargout{1} = data;
varargout{3} = raster;
