function hoops = SetThresholds(DA,fn)
% hoops = SetThresholds(DA)
%
% Set TDT SpikeSort2 voltage thresholds in OpenEx from the file
% saved using the GetThresholds function.
%
% The default file:
%   'C:\Electrophys\RunTime Files\Thresh.mat'
%
% DJS (c) 2012
%
% See also GetThresholds

if ~exist('fn','var') || isempty(fn)
    fn = 'C:\Electrophys\RunTime Files\Thresh.mat';
end

if exist(fn,'file')
    load(fn);
    
    
    for i = 1:length(spike.threshold)
        tmpName = strcat('Acq.aSnip~',num2str(i));
        % removed error because it is thrown if too few channels are being run
        if DA.SetTargetVal(tmpName, spike.threshold(i)) == 0    % set spike detection thresholds
            %                     error('Unable to set threshold');
        end
    end
    
    % *************************************************************************
    % NOTE: UNABLE TO GET/SET FILTERS FROM THE SpikePac NeuroFilter COMPONENT.
    % CONTACT TDT
    % *************************************************************************
    % set spike filters
    % if ~DA.SetTargetVal('Acq.Spike_HP',spike.HP) || ~DA.SetTargetVal('Acq.Spike_LP',spike.LP)
    %     disp('Unable to set Spike filters!');
    %     beep
    % end
    
    % set wave (lfp) filters
    % if ~DA.SetTargetVal('Acq.Wave_HP',wave.HP) || ~DA.SetTargetVal('Acq.Wave_LP',wave.LP)
    %     disp('Unable to set Wave filters!');
    %     %         beep
    % end
    
    hoops.spike = spike;
    hoops.wave  = wave;
    
    s = dir(fn);
    
    disp(['Hoops set from file created ' datestr(s.date,'mmm.dd,yyyy HH:MM:SS PM')]);
else
%     warning('Threshold file not found')
end
