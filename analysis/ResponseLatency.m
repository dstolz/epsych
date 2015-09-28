function [on,off] = ResponseLatency(psth,binvec,thresh,test,select,minsamps,gsamps)
% [on,off] = ResponseLatency(psth,binvec,thresh)
% [on,off] = ResponseLatency(psth,binvec,thresh,test)
% [on,off] = ResponseLatency(psth,binvec,thresh,test,select,minsamps)
% [on,off] = ResponseLatency(psth,binvec,thresh,test,select,minsamps,gsamps)
% [on,off] = ResponseLatency(psth,binvec,thresh,test,select,minsamps,gsamps)
% 
% Finds the onset and offset latencies of a response in an Nx1 histogram.
% 
% psth is an Nx1 array with binned samples.
%
% binvec is a monotonically increasing Nx1 vector of the timestamps
% associated with each bin in psth.
% 
% thresh is a numeric value defining the threshold to find the excursion
% above threshold (ie, the response) in psth. Multiple thrsholds can be
% tested in a single call to this function by passing in an array of
% thresholds.
% 
% test (optional) is the comparison to use to find the excursion in psth.
% Acceptable values include:    'gt'   or   '>' (default)
%                               'gte'  or   '>='
%                               'lt'   or   '<'
%                               'lte'  or   '<='
%                               'e'    or   '='
% 
% select (optional) controls which excursion is selected if multiple
% excursions are detected in psth.
% Acceptable values include:    'largest'
%                               'smallest'
%                               'first'
%                               'last'
%                               'span' - returns earlest onset and latest offset
% 
% minsamps (optional) controls the minimum duration (in samples) to accept
% as a response.  Scalar value between 1 and
% length(psth). (see findConsecutive)
% 
% gsamps (optional) controls the number of dips below threshold to forgive.
% (see findConsecutive)
% 
% Daniel.Stolzberg@gmail.com 2015

% set defaults
assert(nargin >= 3,'Requires 3 or more inputs');
if nargin < 4 || isempty(test),     test = 'gt';        end
if nargin < 5 || isempty(select),   select = 'largest'; end
if nargin < 6 || isempty(minsamps), minsamps = 1;       end
if nargin < 7 || isempty(gsamps),   gsamps = 0;         end

assert(minsamps>0 & minsamps<=length(psth),'Invalid value for minsamps');

on  = nan(size(thresh));
off = nan(size(thresh));

for i = 1:numel(thresh)
    switch lower(test)
        case {'gt', '>' }, ind = psth >  thresh(i);
        case {'gte','>='}, ind = psth >= thresh(i);
        case {'lt', '<' }, ind = psth <  thresh(i);
        case {'lte','<='}, ind = psth <= thresh(i);
        case {'e',  '=' }, ind = psth == thresh(i);
        otherwise
            error('Unrecognized test')
    end
        
    C = findConsecutive(ind,minsamps,gsamps);
    
    if isempty(C), continue; end
    
    switch lower(select)
        case 'largest',  [~,d] = max(diff(C));
        case 'smallest', [~,d] = min(diff(C));
        case 'first',    d = 1;
        case 'last',     d = size(C,2);
        case 'span',     d = [];
        otherwise
            error('Unrecognized select')
    end
    
    if isempty(d)
        on(i)  = binvec(C(1,1));
        off(i) = binvec(C(2,end));
    else
        on(i)  = binvec(C(1,d));
        off(i) = binvec(C(2,d));
    end
    
end








