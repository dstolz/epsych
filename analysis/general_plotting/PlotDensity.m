function varargout = PlotDensity(raster,values,varargin)
% PlotDensity(raster,values)
% PlotDensity(raster,values,'Parameter',value)
% D = PlotDensity(raster,values,...)
% [D,h] = PlotDensity(raster,values,...)
% 
% Takes raster input (see PlotRaster) and creates a surface plot of a
% 2D histogram from the data.
% 
% 
% Optional 'Parameter',value pair arguments:
% 
%   'ax'        ...     axis handle (default = gca)
%   'bins'      ...     equally spaced bins
%                       default is determined from data
%   'smoothing' ...     true or false.  If true, a 5x5 gaussian kernel is
%                       convolved with the 2D histogram.
% 
% Daniel.Stolzberg@gmail.com 2014
% 
% See also, PlotRaster



assert(nargin>=2,'Requires atleast 2 inputs.');
assert(iscell(raster),'raster must be a cell array.');
assert(isnumeric(values)&&length(values)==length(raster), ...
    'values must be a numerical array the same size as raster.');

% defaults
ax   = [];
bins = [];
smoothing = true;

ParseVarargin({'ax','bins','smoothing'},[],varargin);

if isempty(ax),   ax = gca; end
if isempty(bins)
    t = cell2mat(raster);
    if isempty(t)
        bins = 0:0.001:0.01;
    else
        bins = min(t):0.001:max(t)-0.001;
    end
end
binsize = bins(2)-bins(1);

raster = raster(:);
values = values(:);

[values,i] = sort(values);
raster     = raster(i);

uvals = unique(values);
nvals = length(uvals);

raster = cellfun(@(x) (x(:)),raster,'UniformOutput',false);

D = zeros(nvals,length(bins));
for i = 1:nvals
    ind = values == uvals(i);
    t   = cell2mat(raster(ind));
    D(i,:) = histc(t,bins); % spike count
    D(i,:) = D(i,:) / sum(ind); % spike count -> mean spike count
end

D = D / binsize; % mean spike count -> mean firing rate

if smoothing
    gw = gausswin(5) * gausswin(10)';
    mD = max(D(:));
    D = conv2(D,gw,'same');
    D  = D/max(D(:))*mD;
end

% surf function doesn't display top and right boundary data so manually
% account for this for display purposes
x = [bins(:); bins(end)];
y = [uvals(:); uvals(end)];
z = [D; D(end,:)];
z = [z z(:,end)];

h = surf(ax,x,y,z);
if smoothing
    shading(ax,'interp'); 
else
    shading(ax,'flat');
end
set(ax,'tickdir','out');
axis tight
view(ax,2)

varargout{1} = D;
varargout{2} = h;




















