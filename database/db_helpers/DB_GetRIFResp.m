function d = DB_GetRIFResp(unit_id)
% d = DB_GetRIFResp(unit_id)
% 
% Retrieves Rate-Intensity Function analysis (RIF_mdanalysis) of unit_id of
% the currently selected database.  
% 
% The function also sorts the subfields by stimulus level in ascending
% order.
% 
% June 2014  Daniel.Stolzberg@gmail.com


r = DB_GetUnitProps(unit_id,'^Resp.*dB$');
d.resp = SortFieldsByLevels(r);

p = DB_GetUnitProps(unit_id,'^Peak.*dB$');
d.peak = SortFieldsByLevels(p);

d.features.resp = DB_GetUnitProps(unit_id,'ResponseFeature');
d.features.peak = DB_GetUnitProps(unit_id,'PeakFeature');

function d = SortFieldsByLevels(d)
i = cellfun(@regexp,d.group_id,repmat({'\d'},size(d.group_id)),'UniformOutput',false);
g = cellfun(@(a,b) (a(b(1):b(end))),d.group_id,i,'UniformOutput',false);
levels = cellfun(@str2num,g);
[levels,i] = sort(levels);
d = structfun(@(a) (a(i)),d,'UniformOutput',false);
d.levels = levels;



