function ParseVarargin(paramkeys,varnames,vin)
% ParseVarargin(paramkeys,varnames,vin);
% 
% Single line 'varargin' checking.  'vin' should be the varargin cell
% array for the calling functiion.
% 
% ParseVarargin(paramkeys,[],vin) will use the paramkeys value as a
% variable name.  Note: spaces are invalid in variable names and are
% replaced with an underscore ('_') in this function.
% 
% paramkeys and varnames must have the same number of elements.
%
% If vin is a structure, then the field names of the structure are assumed
% to be the variable names.
%
% Default values for variables should be made explicitly prior to calling
% this function.
% 
% ex:
%   window  = [0 0.1];
%   binsize = 0.001;
%   ParseVarargin({'window','binsize'},[],varargin);
%
% ex:
%   window  = [0 0.1];
%   binsize = 0.001;
%   ParseVarargin({'window','binsize'},{'win','bsz'},varargin);
% 
% 
% Daniel.Stolzberg@gmail.com 2013

if isempty(vin), return; end

paramkeys  = cellstr(paramkeys);
if isempty(varnames)
    varnames = paramkeys;
    for i = 1:length(varnames)
        ind = strfind(varnames{i},' ');
        if any(ind), varnames{i}(ind) = '_'; end
    end
else
    varnames = cellstr(varnames);
end


if isstruct(vin{1})
    cfg = vin{1};
    fn = fieldnames(cfg);
    k = 1;
    for i = 1:length(fn)
        vin{k}   = fn{i};
        vin{k+1} = cfg.(fn{i});
        k = k + 2;
    end
end

for i = 1:2:length(vin)
    ind = strcmpi(vin{i},paramkeys);
    if ~any(ind), continue; end
    
    ind = find(ind,1,'last');
    
    assignin('caller',varnames{ind},vin{i+1});
end
