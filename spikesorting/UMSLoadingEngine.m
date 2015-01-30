function varargout = UMSLoadingEngine(fn,varargin )
% [t,wv] = UMSLoadingEngine(fn)
% [t,wv] = UMSLoadingEngine(fn,records_to_get,record_units)
% 
% Modified version of the OpenEphysLoadingEngine
% 
%MClust Loading engine for reading in tetrode data collected with 
%Open Ephys GUI software (http://open-ephys.org/#/gui/). Requires
%pre-processing with Simpleclust (Jacob Voigts,
%http://jvoigts.scripts.mit.edu/blog/simpleclust-manual-spike-sorting-in-matlab/)
%
% input:
%     fn = file name string. This should be 'chN_simpleclust.mat'
%     records_to_get = an array that is either a range of values
%     record_units =
%         1: timestamp list.(a vector of timestamps to load (uses binsearch to find them in file))
%         2: record number list (a vector of records to load)
%         3: range of timestamps (a vector with 2 elements: a start and an end timestamp)
%         4: range of records (a vector with 2 elements: a start and an end record number)
%         5: return the count of spikes (records_to_get should be [] in this case)
% if only fn is passed in then the entire file is opened.
% if only fn is passed AND only t is provided as the output, then all
%    of the timestamps for the entire file are returned.
%   
% output:
%    [t, wv]
%    t = n x 1: timestamps of each spike in file
%    wv = n x 4 x 32 waveforms
%
%
%mike wehr 06.06.2014
%wehr@uoregon.edu

persistent spikes


if strcmp(fn,'get')
    switch varargin{1}
        case 'ChannelValidity'
            s = inputdlg('Enter trodalness (ex 4 for a tetrode):','ChannelValidity', ...
                1,{'4'});
            s = char(s);
            t = str2double(s);
            cv = false(1,4);
            for i = 1:t, cv(i) = i <= t; end
            varargout{1} = cv;
            return
            
        case 'ExpectedExtension'
            varargout{1} = '.mat';
            return
        
        case 'UseFileDialog'
            varargout{1} = true;
            return
    end
end

if isempty(spikes) || ~isfield(spikes,'filename') || ~strcmp(spikes.filename,fn)
    load(fn);
    spikes.filename = fn;
end

if isempty(varargin)
    record_units = -1; % All records
else
    switch length(varargin)
        
        case 0      % No additional arguments
            record_units=-1;      % All records
            
        case 1      % Supplied range, but no units
            error('UMSLoadingEngine:For range of records you must specify record_units');
            
        case 2      % User specified range of values to get
            records_to_get=varargin{1};
            record_units=varargin{2};
            
        otherwise
            error('UMSLoadingEngine:Too many input arguments');
    end
end

timestamps=spikes.unwrapped_times;

numsamples=size(spikes.waveforms, 2);
waveforms = zeros(size(spikes.waveforms,1),size(spikes.waveforms,3),numsamples);
for i = 1:size(spikes.waveforms,3)
    waveforms(:,i,:) = spikes.waveforms(:,:,i);
end

% rescale for MClust
waveforms = waveforms*1e8;

switch record_units
    
    case -1         % All records
        index=1:length(timestamps);
        t=timestamps(index);
        
    case 1          % Timestamp list
        index=find(intersect(timestamps,records_to_get));
        t=timestamps(index);
        
    case 2          % Record number list
        index=records_to_get;
        t=timestamps(records_to_get);
        
    case 3          % Timestamp range
        index=find(timestamps >= records_to_get(1) & timestamps <= records_to_get(2));
        t=timestamps(index);
        
    case 4          % Record number range
        index=records_to_get(1):1:records_to_get(2);
        t=timestamps(index)';
        
    case 5         % return spike count
        t=length(timestamps);      % value returned is not timestamp, but rather spike count
        
    otherwise
        error('UMSLoadingEngine:Invalid argument for record_units');
        
end
varargout{1}=t;
if nargout == 2
    varargout{2}=waveforms(index,:,:); 
end