function [handles,AX] = initializePhysiology_SanesLab(handles,AX)
%handles = initializePhysiology_SanesLab(handles,AX)
%
%Custom function for SanesLab epsych
%
%This function creates an initial weight matrix for common average
%referencing of multi-channel recordings. This initial matrix is unweighted
%(i.e. no common averaging is applied). The matrix is sent directly 
%to the RPVds circuit. This function also enables or disables the reference
%physiology button in the GUI, as appropriate. The number of recording
%channels is identified via a parameter tag ('nChannels') in the RZ5 
%circuit. If no tag exists, the number of channels defaults to 16.
%
%Inputs:
%   handles: GUI handles structure
%   AX: handle to Active X controls
%
%Written by ML Caras 7.24.2016. Updated 8.25.2016.

global RUNTIME

%If we're using OpenEx,
if RUNTIME.UseOpenEx
    
    %Find the index of the RZ5 device (running physiology)
    h = findModuleIndex_SanesLab('RZ5', handles);
    
    %Find the number of channels in the circuit via a parameter tag
    n = AX.GetTargetVal([h.module,'.nChannels']);
    
    if n == 0
        n = 16; %Default to 16 channel recording if no param tag, and 
        vprintf(0,'Number of recording channels is not defined in RPVds circuit. \nSet to default (16).')
    end
    
    %Create initial, non-biased weights
    v = ones(1,n);
    WeightMatrix = diag(v);
    
    %Reshape matrix into single row for RPVds compatibility
    WeightMatrix =  reshape(WeightMatrix',[],1);
    WeightMatrix = WeightMatrix';
    
    AX.WriteTargetVEX([h.module,'.WeightMatrix'],0,'F32',WeightMatrix);
    
    %Enable reference physiology button in gui
    set(handles.ReferencePhys,'enable','on')
    
else
    %Disable reference physiology button in gui
    set(handles.ReferencePhys,'enable','off')
    set(handles.ReferencePhys,'BackgroundColor',[0.9 0.9 0.9])
end
