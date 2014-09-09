function CONFIG = ep_TimerFcn_Error(CONFIG, AX, FLAGS)
% ep_TimerFcn_Error(CONFIG, RP, FLAGS)
% ep_TimerFcn_Error(CONFIG, DA, FLAGS)
% 
% Default Error timer function
% 
% Use ep_PsychConfig GUI to specify custom timer function.
% 
% Daniel.Stolzberg@gmail.com 2014

% not doing anything with CONFIG


CONFIG = ep_TimerFcn_Stop(CONFIG,AX,FLAGS); % same as TimerFcn_Stop function

rethrow(CONFIG(1).ERROR);