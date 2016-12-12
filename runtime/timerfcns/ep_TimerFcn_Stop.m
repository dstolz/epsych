function RUNTIME = ep_TimerFcn_Stop(RUNTIME,AX)
% RUNTIME = ep_TimerFcn_Stop(RUNTIME,DA)
% RUNTIME = ep_TimerFcn_Stop(RUNTIME,RP)
% 
% Default Stop timer function
% 
% Use ep_PsychConfig GUI to specify custom timer function.
% 
% Daniel.Stolzberg@gmail.com

% Copyright (C) 2016  Daniel Stolzberg, PhD

% not doing anything with CONFIG

if RUNTIME.UseOpenEx
    AX.SetSysMode(0);
    AX.CloseConnection;
    delete(AX);
    h = findobj('Type','figure','-and','Name','ODevFig');
    close(h);
else
    for i = 1:length(AX)
        AX(i).Halt;
        delete(AX(i));
    end
    h = findobj('Type','figure','-and','Name','RPfig');
    close(h);
end





