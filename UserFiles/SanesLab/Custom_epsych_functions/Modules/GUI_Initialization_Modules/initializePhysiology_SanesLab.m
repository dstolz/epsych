function handles = initializePhysiology_SanesLab(handles,n)
%Custom function for SanesLab epsych
%
%This function creates an initial weight matrix for common average
%referencing of multi-channel recordings.This initial matrix is unweighted
%(i.e. no common averaging is applied). The matrix is sent directly 
%to the RPVds circuit. This function also enables or disables the reference
%physiology button in the GUI, as appropriate.
%
%Inputs are handles for the GUI, and the number of recording channels.
%
%Example usage:handles = initializePhysiology_SanesLab(handles,16)
%
%Written by ML Caras 7.24.2016

global RUNTIME AX



%If we're using OpenEx, 
if RUNTIME.UseOpenEx
   
    %Create initial, non-biased weights
    v = ones(1,n);
    WeightMatrix = diag(v);
    
    %Reshape matrix into single row for RPVds compatibility
    WeightMatrix =  reshape(WeightMatrix',[],1);
    WeightMatrix = WeightMatrix';
    
    AX.WriteTargetVEX('Phys.WeightMatrix',0,'F32',WeightMatrix);
    
    %Enable reference physiology button in gui
    set(handles.ReferencePhys,'enable','on')
    
else
    %Disable reference physiology button in gui
    set(handles.ReferencePhys,'enable','off')
    set(handles.ReferencePhys,'BackgroundColor',[0.9 0.9 0.9])
end
