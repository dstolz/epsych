function updatetag_SanesLab(gui_handle,module,dev,paramtag)
%updatetag_SanesLab(gui_handle,module,dev,paramtag)
%
%Custom function for SanesLab epsych
%
%This function updates a parameter tag in the RPVds circuit, and resets the
%color of the GUI dropdown menu.
%
%Inputs:
%   gui_handle: handle to the GUI dropdown menu for the parameter
%   module: handle to the TDT module running the circuit to update
%   dev: index to TDT module running the circuit to update
%   paramtag: parameter tag (string)
%
%Written by ML Caras 7.25.2016

global AX RUNTIME 

%Abort if specified parameter tag is not in the RPVds circuit
if sum(~cellfun('isempty',strfind(RUNTIME.TDT.devinfo(dev).tags,paramtag)))== 0
    return
end

%If the user has control over the gui handle
switch get(gui_handle,'enable')
    
    case 'on'
        %Get response window duration from GUI
        str = get(gui_handle,'String');
        val = get(gui_handle,'Value');
        
        %Convert to a number
        val = str2num(str{val});
        
        %But convert back to a string if options are not numbers
        if isempty(val)
            val = get(gui_handle,'Value');
            val = str{val};
        end
        
        switch paramtag
            case {'Silent_delay','RespWinDur','RespWinDelay',...
                    'MinPokeDur','Lowpass','ITI_dur',...
                    'ShockDur','to_duration','Stim_Duration'}
                val = val*1000; %msec or Hz
         
            case 'AMrate'
                %RPVds can't handle floating point values of zero, apparently, at
                %least for the Freq component.  If the value is set to zero, the
                %sound will spuriously and randomly drop out during a session.  To
                %solve this problem, set the value to the minimum value required by
                %the component (0.001).
                if val == 0
                    val = 0.001;
                end
                
            case {'AMdepth','FMdepth'}
                
                if val > 1
                    val = val/100; %proportion for RPVds
                end
                
            case 'Optostim'
                switch val
                    case 'On'
                        val = 1;
                    case 'Off'
                        val = 0;
                end
                
            case 'ShockFlag'
                switch val
                    case 'On'
                        val = 1;
                    case 'Off'
                        val = 0;
                end
                
        end
        
        %Use Active X controls to set duration directly in RPVds circuit
        v = TDTpartag(AX,[module,'.',paramtag],val);      
       
        set(gui_handle,'ForegroundColor',[0 0 1]);
end
