function [on,off] = ResponseOnOffLatency(psth,binvec,thresh,test,minsamps,gsamps)
% [on,off] = ResponseOnOffLatency(psth,binvec,thresh)
% [on,off] = ResponseOnOffLatency(psth,binvec,thresh,test)
% [on,off] = ResponseOnOffLatency(psth,binvec,thresh,test,minsamps)
% [on,off] = ResponseOnOffLatency(psth,binvec,thresh,test,minsamps,gsamps)
% 
% Daniel.Stolzberg@gmail.com 2015

if nargin < 4
    test = 'gt';
    minsamps = 1;
    gsamps = 0;
    
elseif nargin < 5
    minsamps = 1;
    gsamps = 0;
    
elseif nargin < 6
    gsamps = 0;
end


on  = nan(size(thresh));
off = nan(size(thresh));

for i = 1:numel(thresh)
    switch test
        case {'gt','>'},    ind = psth >  thresh(i);
        case {'gte','>='},  ind = psth >= thresh(i);
        case {'lt','<'},    ind = psth <  thresh(i);
        case {'lte','<='},  ind = psth <= thresh(i);
        case {'e','='},     ind = psth == thresh(i);
        otherwise
            error('Unrecognized test')
    end
    
    C = findConsecutive(ind,minsamps,gsamps);
    
    if isempty(C), continue; end
    
    [~,d] = max(diff(C));
    on(i)  = binvec(C(1,d));
    off(i) = binvec(C(2,d));
    
end








