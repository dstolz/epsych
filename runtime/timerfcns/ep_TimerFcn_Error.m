function CONFIG = ep_TimerFcn_Error(CONFIG, RP, DA)
% ep_TimerFcn_Error(CONFIG, RP, DA)
% 
% Defualt Error timer function
% 
% Use ep_PsychConfig GUI to specify custom function.
% 
% Daniel.Stolzberg@gmail.com 2014

% not doing anything with CONFIG

if isempty(RP)
    DA.SetSysMode(0);
else
    for i = 1:length(RP)
        RP(i).Halt;
    end
end
