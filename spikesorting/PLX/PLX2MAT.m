function varargout = PLX2MAT2(plxfilename,trodes)
% [units,ts] = PLX2MAT2(plxfilename)
% [units,ts] = PLX2MAT2(plxfilename,trodes)
% [...,waves] = PLX2MAT2(plxfilename,...)
% [...,waves,channels] = PLX2MAT2(plxfilename,...)
% 
% Reads Plexon PLX files
%
% If 'trodes' is not specified, all channels from the plx file are returned
% individually.  'trodes' must be a cell array of channel numbers for each
% bundle of electrodes (see example).
%
% Minimally returns 'units' and timestamps ('ts').  'units' is a 1xNumber
% of Trodes (ie., length(trodes)) cell array with each cell containing id
% the sorted unit id of each spike.  'ts' is a cell array the same size of
% 'units'.  The unit ids of each spike correspond to the timestamps in
% 'ts'.  Optionally, 'waves' can be returned which are the spike waveforms
% as raw a/d values.
%
% Unit 0 is unsorted
%
% ex: 
%   plxfilename = 'c:\sorted\somefile.plx';
%   trodes = {1:4, 5:8};
%   [ts,units] = PLX2MAT(plixfilename,trodes);
% 
% note: requires Plexon SDK
% 
% daniel.stolzberg@gmail.com 2/2015


narginchk(1,2);
nargoutchk(2,4);

retwaves = nargout >= 3;

if nargin == 1 || isempty(trodes), trodes = num2cell(1:255); end
if ~iscell(trodes), trodes = {trodes}; end

ntrodes = length(trodes);

tn   = cellfun(@length,trodes);
% n    = zeros(size(tscounts,1),nchans,'uint32');
ts   = cell(1,ntrodes);
unit = cell(1,ntrodes);
w    = cell(1,ntrodes);
for i = 1:ntrodes
    trode = trodes{i};
    
    ut = double([]); un = uint8([]); uw = int16([]);
    
    fprintf('\nTrode %d (%d channels)\n',trode(1),tn(i))
    
    for j = 1:27
%         if ~tscounts(j,trode(1)), continue; end % only works if all channels are specified

        [n(j,i), t] = mexPlex(5, plxfilename, trode(1),j-1);
        if t(1) == -1 && j == 1, continue; elseif t(1) == -1, break; end
        
        
        if retwaves
            wt = int16([]);
            for e = 1:tn(i)
                [~,~,~,wt(:,:,e)] = plx_waves(plxfilename,trode(e),j-1);
            end
            uw = [uw; wt]; %#ok<AGROW>
        end
        
        fprintf('\t\tunit %d\t# spikes:% 8d\n',j-1,n(j,i))
        
        ut = [ut; t]; %#ok<AGROW>
        un = [un; ones(n(j,i),1) * (j-1)]; %#ok<AGROW>
    end
    
    [ts{i},sidx] = sort(ut); 
    unit{i}      = un(sidx); 
    if retwaves, w{i} = uw(sidx,:,:); end
    
    
end

ind = cellfun(@isempty,unit);
unit(ind) = [];
ts(ind)   = [];
w(ind)    = [];

% sdk doesn't properly close the plx file so clear it so the file can be
% accessed and saved by OfflineSorter  DJS 5/2016
clear mexPlex 

varargout{1} = unit;
varargout{2} = ts;
varargout{3} = w;
varargout{4} = find(~ind);

