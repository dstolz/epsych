function AX = ReferencePhys_SanesLab(handles,AX)
%ReferencePhys_SanesLab(handles)
%
%Custom function for SanesLab epsych
%
%This function performs the calculations necessary for the common signal
%averaging for multi-channel recordings. 
%
%Inputs:
%   handles: GUI handles structure
%   AX: handles to active X controls
%
%The method we're using here to reference channels is the following:
%First, bad channels are removed.
%Second a single channel is selected and held aside.
%Third, all of the remaining (good, non-selected) channels are averaged.
%Fourth, this average is subtracted from the selected channel.
%This process is repeated for each good channel.
%
%The way this method is implemented in the RPVds circuit is as follows:
%
%From Brad Buran:
%
% This is implemented using matrix multiplication in the format D x C =
% R. C is a single time-slice of data in the shape [n x 1]. In other
% words, it is the value from all n channels sampled at a single point
% in time. D is a n x n matrix. R is the referenced output in the
% shape [n x 1]. Each row in the matrix defines the weights of the
% individual channels. So, if you were averaging together channels 2-16
% and subtracting the mean from the first channel, the first row would
% contain the weights:
%
% [1 -1/15 -1/15 ... -1/15]
%
% If you were averaging together channels 2-8 and subtracting the mean
% from the first channel:
%
% [1 -1/7 -1/7 ... -1/7 0 0 0 ... 0]
%
% If you were averaging together channels 3-8 (because channel 2 was
% bad) and subtracting the mean from the first channel:
%
% [1 0 -1/6 ... -1/6 0 0 0 ... 0]
%
% To average channels 1-4 and subtract the mean from the first channel:
%
% [3/4 -1/4 -1/4 -1/4 0 ... 0]
%
% To repeat the same process (average channels 1-4 and subtract the
% mean) for the second channel, the second row in the matrix would be:
%
% [-1/4 3/4 -1/4 -1/4 0 ... 0]
%
%
%For more information see Ludwig et al. (2009) J Neurophys 101(3):1679-89 
%
%Inputs:
%   handles: GUI handles structure
%
%
%Written by ML Caras 7.28.2016


%Find the index of the RZ5 device (running physiology)
h = findModuleIndex_SanesLab('RZ5', handles);

%Find the number of channels in the circuit via a parameter tag
n = AX.GetTargetVal([h.module,'.nChannels']);

if n == 0
    n = 16; %Default to 16 channel recording if no param tag, and
    vprintf(0,'Number of recording channels is not defined in RPVds circuit. \nSet to default (16).')
end


%Prompt user to identify bad channels
channelList = cellstr(num2str([1:n]'))';

header = 'Select bad channels. Hold Cntrl to select multiple channels.';

bad_channels = listdlg('ListString',channelList,'InitialValue',8,...
    'Name','Channels','PromptString',header,...
    'SelectionMode','multiple','ListSize',[300,300]) %#ok<NOPRT>


if ~isempty(bad_channels)
    %Calculate weight for non-identical pairs
    weight = -1/(n - numel(bad_channels) - 1);
    
    %Initialize weight matrix
    WeightMatrix = repmat(weight,n,n);
    
    %The weights of all bad channels are 0.
    WeightMatrix(:,bad_channels) = 0;
    
    %Do not perform averaging on bad channels: leave as is.
    WeightMatrix(bad_channels,:) = 0;
    
    %For each channel
    for i = 1:n
        
        %Its own weight is 1
        WeightMatrix(i,i) = 1;
        
    end
    
    
    
    %Reshape matrix into single row for RPVds compatibility
    WeightMatrix =  reshape(WeightMatrix',[],1);
    WeightMatrix = WeightMatrix';
    
    
    %Send to RPVds
    AX.WriteTargetVEX([h.module,'.WeightMatrix'],0,'F32',WeightMatrix);
    %verify = AX.ReadTargetVEX('Phys.WeightMatrix',0, 256,'F32','F64');
end
