%% Batch histogram analysis.
%
% 1) Open DB_Browser and select an experiment you would like to process
% 2) Click your mouse in this script to give it focus and tap F5 on the keyboard to run
% 3) All units of the experiment selected in DB_Browser of the experiment
%    and protocol (ex: ProtocolName = 'RIF')
% Note: Any unit properties that have been manually adjusted using
% RIF_analysis will be updated with the results of the algorithm.
%
% Daniel.Stolzberg@gmail.com


ProtocolName = 'RIF';















%
ids = getpref('DB_BROWSER_SELECTION');


n = {'level','onsetlat','offsetlat','peaklat','risingslope','fallingslope', ...
    'peakfr','area','ksp','ksstat','prestimmeanfr','poststimmeanfr'};
d = {'Stimulus level','Onset latency','Offset latency','Peak latency','Rising slope', ...
'Falling slope','Peak firing rate','Calculated area','Kolmogorov-Smirnov p value', ...
'Kolmogorov-Smirnov statistic','Prestimulus mean firing rate','Poststimulus mean firing rate'};
DB_CheckAnalysisParams(n,d);



H = mym(['SELECT v.unit, v.block ', ...
         'FROM v_ids v JOIN blocks b ', ...
         'ON b.id = v.block ', ...
         'JOIN db_util.protocol_types p ON p.pid = b.protocol ', ...
         'JOIN units u ON v.unit = u.id ', ...
         'WHERE p.alias = "{S}" ', ...
         'AND u.pool > 0 ', ...
         'AND v.experiment = {Si}'], ...
         ProtocolName,ids.experiments);
    
kernel = blackman(5);

cfg = [];
cfg.rwin = [0 0.05];
cfg.bwin = [-0.05 0];
cfg.resamp = 3;
cfg.ksalpha = 0.025;
cfg.kstype  = 'larger';
cfg.plotresult = false;

for i = 1:length(H.unit)
    fprintf('Unit %d\t%d of %d units\n',H.unit(i),i,length(H.unit))
    st = DB_GetSpiketimes(H.unit(i));
    if numel(st)<5, continue; end
    p  = DB_GetParams(H.block(i));
    [data,vals] = shapedata_spikes(st,p,{'Levl'}, ...
        'win',[-0.1 0.1],'binsize',0.001);
    data = data * 1000; % firing rate
    clear R
    for j = 1:size(data,2)
        mv = max(data(:,j));
        cdata = conv(data(:,j),kernel,'same');
        cdata = cdata / max(cdata) * mv;
        cdata(isnan(cdata)) = 0;
        t = ComputePSTHfeatures(vals{1},cdata,cfg);
        R.level(j)          = vals{2}(j);
        R.onsetlat(j)       = t.onset.latency;
        R.risingslope(j)    = t.onset.slope;
        R.offsetlat(j)      = t.offset.latency;
        R.fallingslope(j)   = t.offset.slope;
        R.peakfr(j)         = t.peak.fr;
        R.peaklat(j)        = t.peak.latency;
        R.area(j)           = t.histarea;
        R.ksp(j)            = t.stats.p;
        R.ksstat(j)         = t.stats.ksstat;
        R.prestimmeanfr(j)  = t.baseline.meanfr;
        R.poststimmeanfr(j) = t.response.meanfr;
    end
    R.level = cellstr(num2str(R.level(:),'%0.2fdBRIF'));
    try
        DB_UpdateUnitProps(H.unit(i),R,'level',false);
    end
end
