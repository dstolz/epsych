function RUNTIME = ep_TimerFcn_Error_SanesLab(RUNTIME, AX)
% ep_TimerFcn_Error_SanesLab(RUNTIME, RP)
% ep_TimerFcn_Error_SanesLab(RUNTIME, DA)
% 
% SanesLab Error timer function
% 
% 
% Daniel.Stolzberg@gmail.com 2014. Edited ML Caras 2015.

% not doing anything with CONFIG


RUNTIME = ep_TimerFcn_Stop_SanesLab(RUNTIME,AX); % same as TimerFcn_Stop function

rethrow(RUNTIME.ERROR);