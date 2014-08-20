function CONFIG = ep_TimerFcn_Stop(CONFIG,RP,DA)
% CONFIG = ep_TimerFcn_Stop(CONFIG,RP,DA)
% 
% Default Stop timer function
% 
% Use ep_PsychConfig GUI to specify custom function.
% 
% Daniel.Stolzberg@gmail.com

% not doing anything with CONFIG

if isempty(RP)
    DA.SetSysMode(0);
else
    for i = 1:length(RP)
        RP(i).Halt;
    end
end





