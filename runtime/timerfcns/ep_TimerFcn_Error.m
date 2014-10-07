function RUNTIME = ep_TimerFcn_Error(RUNTIME, AX)
% ep_TimerFcn_Error(RUNTIME, RP)
% ep_TimerFcn_Error(RUNTIME, DA)
% 
% Default Error timer function
% 
% Use ep_PsychConfig GUI to specify custom timer function.
% 
% Daniel.Stolzberg@gmail.com 2014

% not doing anything with CONFIG


RUNTIME = ep_TimerFcn_Stop(RUNTIME,AX); % same as TimerFcn_Stop function

rethrow(RUNTIME.ERROR);