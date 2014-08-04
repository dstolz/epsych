function varargout = DB_PlotPSTH(unit_id,varargin)
% varargout = DB_PlotPSTH(unit_id,varargin)

% defaults
binsize   = 0.001;
shapefunc = 'mean';
win       = [-0.05 0.1];
kernel    = 5;
convolve  = false;
fh        = [];
resamp    = 1;
kstype    = 'unequal';
ksalpha   = 0.05;

ParseVarargin({'fh','rwin','bwin','convolve','kernel','kstype','ksalpha',...
    'resamp','plotresult','binsize','shapefunc'}, ...
    [],varargin);

kernel = gausswin(kernel); %#ok<NASGU>
% kernel = hann(kernel);
% kernel = blackmanharris(kernel);
% kernel = blackman(kernel); %#ok<NASGU>

block_id = myms(sprintf('SELECT block FROM v_ids WHERE unit = %d',unit_id));

st = DB_GetSpiketimes(unit_id);
p  = DB_GetParams(block_id);

[data,vals] = shapedata_spikes(st,p,{'Levl'},'win',win,'binsize',binsize,'func',shapefunc);
data(isnan(data)) = 0;

if convolve
    cdata = zeros(size(data)); %#ok<*UNRCH>
    for i = 1:size(data,2) 
        mv = max(data(:,i));
        cdata(:,i) = conv(data(:,i),kernel,'same');
        cdata(:,i) = cdata(:,i) / max(cdata(:,i)) * mv;
    end
end

r = DB_GetUnitProps(unit_id,'dBRIF$');
if isempty(r)
    for i = 1:size(data,2)
        if convolve
            d = data(:,i);
        else
            d = cdata(:,i); %#ok<NODEF>
        end
            
        t = ComputePSTHfeatures(vals{1},d,'rwin',rwin,'bwin',bwin, ...
            'resamp',resamp,'kstype',kstype,'ksalpha',ksalpha);
        r.unit_id(i)        = unit_id;
        r.level(i)          = vals{2}(i);
        r.onsetlat(i)       = t.onset.latency;
        r.risingslope(i)    = t.onset.slope;
        r.offsetlat(i)      = t.offset.latency;
        r.fallingslope(i)   = t.offset.slope;
        r.peakfr(i)         = t.peak.fr;
        r.peaklat(i)        = t.peak.latency;
        r.area(i)           = t.histarea;
        r.ksp(i)            = t.stats.p;
        r.ksstat(i)         = t.stats.ksstat;
        r.prestimmeanfr(i)  = t.baseline.meanfr;
        r.poststimmeanfr(i) = t.response.meanfr;
    end
end
R = r;

if isempty(fh) || ~ishandle(fh), fh = figure('color','w'); end

figure(fh);
clf(fh);
set(fh,'Name',sprintf('Unit %d',unit_id),'NumberTitle','off', ...
    'HandleVisibility','on','Renderer','Painters','units','normalized');

origpos = get(fh,'position');

data = data / binsize; % convert to mean firing rate


numL = length(R.onsetlat);
for i = 1:numL
    h(i) = subplot(numL,1,i); %#ok<AGROW>
    bar(vals{1},data(:,i),'EdgeColor',[0.3 0.3 0.3],'FaceColor',[0.6 0.6 0.6]);
    ylabel(vals{2}(i),'Color',[0 0 1]*double(R.ksp(i)<0.025));
end
xlabel(h(end),'time (s)');
axis(h,'tight');


y = cell2mat(get(h,'ylim'));
y = [0 max(y(:))*1.1];
set(h(1:end-1),'xticklabel',[])
set(h,'ylim',y);
set(h,'TickLength',[0.005 0.01],'TickDir','out');

for i = 1:numL
    hold(h(i),'on');
    
    plot(h(i),[0 0],y,'-k');
    
%     if R.ks_p(i) < 0.025 && R.onset_latency(i) > 0
%         plot(h(i),[R.onset_latency(i) R.onset_latency(i)],y,  ':g','linewidth',2)
%         plot(h(i),[R.offset_latency(i) R.offset_latency(i)],y,':g','linewidth',2)
        plot(h(i),[R.onsetlat(i) R.offsetlat(i)],[0 0],'-*g','linewidth',2);
        plot(h(i),[R.onsetlat(i) R.onsetlat(i)+0.05],[y(2) y(2)],'-r','linewidth',3)
        pkval = interp1(vals{1},data(:,i),R.peaklat(i),'nearest');
        plot(h(i),R.peaklat(i),pkval,'^g', ...
            'markerfacecolor','none','markersize',10,'linewidth',2)
%     end
    
    astr = sprintf(['Onset:  % 3.0fms | Base FR: %0.0fHz\n', ...
                    'Peak:   % 3.0fms | Resp FR: %0.0fHz\n', ...
                    'Offset: % 3.0fms | Peak FR: %0.0fHz\n', ...
                    'Resp Duration: % 3.0fms'], ...
        R.onsetlat(i)*1000,    R.prestimmeanfr(i), ...
        R.peaklat(i)*1000,     R.poststimmeanfr(i), ...
        R.offsetlat(i)*1000,   R.peakfr(i), ...
        1000*(R.offsetlat(i) - R.onsetlat(i)));
    
    p = get(h(i),'position');
    annotation('textbox',[p(1),p(2)+p(4)-0.25*p(4) 0.4*p(3) 0.25*p(4)], ...
        'string',astr,'FitHeightToText','off','LineStyle','none','fontsize',6, ...
        'Margin',2,'FontName','Courier New');

    if convolve
        plot(h(i),vals{1},cdata(:,i)/binsize,'m:');
    end
    
    hold(h(i),'off');
end

set(fh,'position',origpos);


varargout{1} = fh;
varargout{2} = h;
varargout{3} = R;
varargout{4} = {data,vals};



























