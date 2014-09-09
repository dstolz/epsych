function CONFIG = ep_TimerFcn_Stop(CONFIG,AX,FLAGS)
% CONFIG = ep_TimerFcn_Stop(CONFIG,DA,FLAGS)
% CONFIG = ep_TimerFcn_Stop(CONFIG,RP,FLAGS)
% 
% Default Stop timer function
% 
% Use ep_PsychConfig GUI to specify custom timer function.
% 
% Daniel.Stolzberg@gmail.com

% not doing anything with CONFIG

if FLAGS.UseOpenEx
    AX.SetSysMode(0);
    AX.CloseConnection;
    delete(AX);
    h = findobj('Type','figure','-and','Name','ODevFig');
    close(h);
else
    for i = 1:length(RP)
        RP(i).Halt;
    end
    delete(RP);
    h = findobj('Type','figure','-and','Name','RPfig');
    close(h);
end





