function DB_UpdateUnitProps(unit_id,P,groupid,verbose,conn)
% DB_UpdateUnitProps(unit_id,P,groupid)
% DB_UpdateUnitProps(unit_id,P,groupid,verbose)
% DB_UpdateUnitProps(unit_id,P,groupid,verbose,conn)
%
% Updates unit_properties table of currently selected database.
%
% Accepts a unit_id (from units table) and P which is a structure in which
% each field name is an existing name from db_util.analysis_params table.  
%
% Fields of P can be a matrix of any size/dimensions and either a cellstr
% type or numeric type.
%
% groupid is a string with the name of one field in the structure P.  This
% field (P.(groupid)) is used to group results in unit_properties by some 
% common value such as sound level, frequency, etc.  If P.(groupid) can
% also be numeric.
%
% ex: % this example uploads peakfr and peaklat with the group level
%   P.level   = {'10dB','30dB','50dB','70dB'};
%   P.peakfr  = [6.1, 10.3, 24.2, 56.1];
%   P.peaklat = [15.1, 14.0, 12.1, 11.5];
%   groupid = 'level';
%   DB_UpdateUnitProperties(unit_id,P,groupid)
% 
% If verbose is true, then the updating progress will be displayed in the
% command window. (default = false)
%
% See also, DB_GetUnitProps, DB_CheckAnalysisParams
% 
% DJS 2013 daniel.stolzberg@gmail.com

% narginchk(3,4);

% use mym by default
if nargin < 5, conn = []; end

if nargin >= 3 && ~isfield(P,groupid)
    error('The groupid string must be a fieldname in structure P');
end

if nargin < 4, verbose = true; end

% % check that all fields of P are of equal length
% n = structfun(@length,P);
% assert(all(n==n(1)),'All fields of P must be the same length.');

setdbprefs('DataReturnFormat','structure');
ap = myms('SELECT analysis_params.id, analysis_params.name FROM db_util.analysis_params',conn);

fn = fieldnames(P)';
fn(ismember(fn,groupid)) = [];

if isnumeric(P.(groupid))
    P.(groupid) = num2str(P.(groupid)(:));
    P.(groupid) = cellstr(P.(groupid));
elseif ~iscellstr(P.(groupid))
    P.(groupid) = cellstr(P.(groupid));
end

fstrs = 'unit id %d\t%s:\t%s\t%- 16s % 12s\n';


fname = fullfile(matlabroot,'DB_TMP.txt');
fid = fopen(fname,'w');

setdbprefs('DataReturnFormat','structure');
p = myms('SELECT DISTINCT name,id FROM db_util.analysis_params',conn);

dltstr = ['DELETE FROM unit_properties ', ...
          'WHERE unit_id = %d AND group_id = "%s" AND param_id = %d'];
for f = fn
    f = char(f); %#ok<FXSET>
    ind = ismember(p.name,f);
    pid = p.id(ind);
    if ~any(ind), continue; end % <- this may mean that the parameter was not added to db_util.analysis_params
    for i = 1:numel(P.(groupid))
        myms(sprintf(dltstr,unit_id,P.(groupid){i},pid),conn);
    end
end


for f = fn
    f = char(f); %#ok<FXSET>
    paramid = ap.id(ismember(ap.name,f));
    if ischar(P.(f))
        P.(f) = cellstr(P.(f));
    elseif isnumeric(P.(f)) || islogical(P.(f))
        P.(f) = num2cell(P.(f));
    end
    
    for i = 1:numel(P.(groupid))

        
        if i > numel(P.(f)), continue; end
        
        if isnan(P.(f){i}), P.(f){i} = 'NULL'; end

        % UNIT_ID, PARAM_ID,GROUP_ID,PARAMS,PARAMF
        if isnumeric(P.(f){i}) || islogical(P.(f){i})
            fprintf(fid,'%d,%d,"%s",NULL,%0.6f\r\n', ...
                unit_id,paramid,P.(groupid){i},P.(f){i});
            par = num2str(P.(f){i},'%0.6f');
            
        else
            fprintf(fid,'%d,%d,"%s","%s",NULL\r\n', ...
                unit_id,paramid,P.(groupid){i},P.(f){i});
            par = P.(f){i};
            
        end
        
        if verbose
            fprintf(fstrs,unit_id,groupid,P.(groupid){i},[f ':'],par)
            drawnow
        end

    end
    
end

fclose(fid);

dbfname = strrep(fname,'\','\\');

fprintf('Updating ...')
myms(sprintf(['LOAD DATA LOCAL INFILE ''%s'' INTO TABLE unit_properties ', ...
    'FIELDS TERMINATED BY '','' OPTIONALLY ENCLOSED BY ''"'' ', ...
    'LINES TERMINATED BY ''\r\n'' ', ...
    '(unit_id,param_id,group_id,paramS,paramF)',],dbfname),conn)
fprintf(' done\n')

delete(fname);

