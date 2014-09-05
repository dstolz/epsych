function CONFIG = ep_TimerFcn_Stop(CONFIG,AX)
% CONFIG = ep_TimerFcn_Stop(CONFIG,DA)
% CONFIG = ep_TimerFcn_Stop(CONFIG,RP)
% 
% Default Stop timer function
% 
% Use ep_PsychConfig GUI to specify custom timer function.
% 
% Daniel.Stolzberg@gmail.com

% not doing anything with CONFIG

isRP = isa(AX,'COM.RPco_x');

if isRP
    for i = 1:length(RP)
        RP(i).Halt;
    end
    delete(RP);
    h = findobj('Type','figure','-and','Name','RPfig');
    close(h);
else
    DA.SetSysMode(0);
    DA.CloseConnection;
    delete(DA);
    h = findobj('Type','figure','-and','Name','ODevFig');
    close(h);
end





