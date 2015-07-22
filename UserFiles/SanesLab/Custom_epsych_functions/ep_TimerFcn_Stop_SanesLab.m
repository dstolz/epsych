function RUNTIME = ep_TimerFcn_Stop_SanesLab(RUNTIME,AX)
% RUNTIME = ep_TimerFcn_Stop_SanesLab(RUNTIME,DA)
% RUNTIME = ep_TimerFcn_Stop_SanesLab(RUNTIME,RP)
% 
% SanesLab Stop timer function
% 
% 
% Daniel.Stolzberg@gmail.com Updated by ML Caras 2015.


% Stop and delete Box Timer
T = timerfind('Name','BoxTimer');
if ~isempty(T)
    stop(T);
    delete(T);
end

if RUNTIME.UseOpenEx
    AX.SetSysMode(0);
    AX.CloseConnection;
    delete(AX);
    h = findobj('Type','figure','-and','Name','ODevFig');
    close(h)
else
    for i = 1:length(AX)
        AX(i).Halt;
    end
    delete(AX);
    h = findobj('Type','figure','-and','Name','RPfig');
    close(h);
end








