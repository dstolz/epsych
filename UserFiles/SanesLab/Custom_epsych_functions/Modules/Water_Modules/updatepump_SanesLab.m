function updatepump_SanesLab(handles)
%updatepump_SanesLab(handles)
%
%Custom function for SanesLab epsych
%
%This function sets the pump rate using flow rate specified in the GUI
%
%Inputs:
%   handles: GUI handles structure
%
%
%Written by ML Caras 7.25.2016. Updated 8.22.2016.


global PUMPHANDLE GUI_HANDLES AX

%Get reward rate from GUI
ratestr = get(handles.Pumprate,'String');
rateval = get(handles.Pumprate,'Value');
GUI_HANDLES.rate = str2num(ratestr{rateval}); %ml/min


%Get reward volume from GUI if applicable
if isfield(handles,'reward_vol')
    rewardstr = get(handles.reward_vol,'String');
    rewardval = get(handles.reward_vol,'Value');
    GUI_HANDLES.vol = str2num(rewardstr{rewardval})/1000; %ml
    
    
    %Calculate reward duration for RPVds circuit
    rate_in_msec = GUI_HANDLES.rate*(1/60)*(1/1000); %ml/msec
    reward_dur = GUI_HANDLES.vol/rate_in_msec;
    
    %Use Active X controls to set parameters directly in RPVds circuit.
    %Circuit will automatically calculate the duration needed to obtain the
    %desired reward volume at the given pump rate.
    v = TDTpartag(AX,[handles.module,'.~reward_dur'],reward_dur);
    
    %Backwards compatibility
    if v == 0 && reward_dur > 0
        v = TDTpartag(AX,[handles.module,'.reward_dur'],reward_dur);
    end
    
    set(handles.reward_vol,'ForegroundColor',[0 0 1]);
end


%Set pump rate directly (ml/min)
fprintf(PUMPHANDLE,'RAT%0.1f\n',GUI_HANDLES.rate)


set(handles.Pumprate,'ForegroundColor',[0 0 1]);
