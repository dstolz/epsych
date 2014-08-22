function CONFIG = ep_TimerFcn_Error(CONFIG, RP, DA)
% ep_TimerFcn_Error(CONFIG, RP, DA)
% 
% Defualt Error timer function
% 
% Use ep_PsychConfig GUI to specify custom function.
% 
% Daniel.Stolzberg@gmail.com 2014

% not doing anything with CONFIG

CONFIG = ep_TimerFcn_Stop(CONFIG,RP,DA); % same as TimerFcn_Stop function

rethrow(CONFIG(1).ERROR);