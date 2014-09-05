function CONFIG = ep_TimerFcn_Error(CONFIG, AX)
% ep_TimerFcn_Error(CONFIG, RP)
% ep_TimerFcn_Error(CONFIG, DA)
% 
% Default Error timer function
% 
% Use ep_PsychConfig GUI to specify custom timer function.
% 
% Daniel.Stolzberg@gmail.com 2014

% not doing anything with CONFIG

isRP = isa(AX,'COM.RPco_x');

CONFIG = ep_TimerFcn_Stop(CONFIG,AX); % same as TimerFcn_Stop function

rethrow(CONFIG(1).ERROR);