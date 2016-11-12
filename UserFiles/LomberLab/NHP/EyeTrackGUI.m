function EyeTrackGUI(varargin)
% EyeTrackGUI('Parameter',value,...)
%
%   'X_UB'              ... X axis Upper Bound tag name
%   'X_LB'              ... X axis Lower Bound tag name
%   'Y_UB'              ... Y axis Upper Bound tag name
%   'Y_LB'              ... Y axis Lower Bound tag name
%   'P_LB'              ... Pupil Diameter Lower Bound tag name
%   'TDTmodule'         ... TDT Module Name in OpenEx
%
% Simple GUI for viewing raw Eye Tracker values and updating upper and
% lower voltage bounds.
%
% Daniel.Stolzberg@gmail.com (C) 9/2016



h.E = struct('X_UB',[],'X_LB',[],'Y_UB',[],'Y_LB',[],'P_LB',[]);
h.TDTmodule = 'EyeFix';

for i = 1:2:length(varargin), h.E.(varargin{i}) = varargin{i+1}; end

f = findFigure('EyeTrackGUI','color','w','Name','EyeTrack', ...
    'Resize','off','Toolbar','none','Position',[270 530 320 150], ...
    'NumberTitle','off','MenuBar','none','CloseRequestFcn',@CloseMe);
figure(f);
clf(f);

uicontrol(f,'style','text','String','LB','FontWeight','bold','Position',[60  120 50 15]);
uicontrol(f,'style','text','String','Value','FontWeight','bold','Position',[120 120 50 15]);
uicontrol(f,'style','text','String','UB','FontWeight','bold','Position',[200 120 50 15]);
uicontrol(f,'style','text','String','X','FontWeight','bold', 'Position',[40   85 15 25]);
uicontrol(f,'style','text','String','Y','FontWeight','bold', 'Position',[40   55 15 25]);
uicontrol(f,'style','text','String','P','FontWeight','bold', 'Position',[40   25 15 25]);

C.X_LB = uicontrol(f,'tag','X_LB','style','edit','String',num2str(h.E.X_LB,3), ...
    'Position',[60 90 50 25],'Callback',{@ReadNewBounds,gco});
C.X_UB = uicontrol(f,'tag','X_UB','style','edit','String',num2str(h.E.X_UB,3), ...
    'Position',[200 90 50 25],'Callback',{@ReadNewBounds,gco});
C.Y_LB = uicontrol(f,'tag','Y_LB','style','edit','String',num2str(h.E.Y_LB,3), ...
    'Position',[60 60 50 25],'Callback',{@ReadNewBounds,gco});
C.Y_UB = uicontrol(f,'tag','Y_UB','style','edit','String',num2str(h.E.Y_UB,3), ...
    'Position',[200 60 50 25],'Callback',{@ReadNewBounds,gco});
C.P_LB = uicontrol(f,'tag','P_LB','style','edit','String',num2str(h.E.Y_UB,3), ...
    'Position',[60 30 50 25],'Callback',{@ReadNewBounds,gco});

C.Vals.X = uicontrol(f,'style','text','String','---','Position',[120 90 70 25]);
C.Vals.Y = uicontrol(f,'style','text','String','---','Position',[120 60 70 25]);
C.Vals.P = uicontrol(f,'style','text','String','---','Position',[120 30 70 25]);

ch = get(f,'children');
set(ch,'BackgroundColor',get(f,'Color'))

C.UpdateBtn = uicontrol(f,'style','pushbutton','String','Update', ...
    'Callback',{@UpdateVals,f},'Position',[200 25 100 30]);

T = timerfind('Name','EyeTrackGUITimer');
if ~isempty(T), stop(T); delete(T); end

h.T = timer('BusyMode','drop', ...
    'ExecutionMode','fixedSpacing', ...
    'Name','EyeTrackGUITimer', ...
    'Period',0.1, ...
    'StartFcn',{@EyeTrackTimerSetup,f}, ...
    'TimerFcn',{@EyeTrackTimerRunTime,f}, ...
    'StopFcn', {@EyeTrackTimerStop,f}, ...
    'TasksToExecute',inf, ...
    'StartDelay',0);

h.C = C;
guidata(f,h);

start(h.T)


function EyeTrackTimerSetup(~,~,f)
global AX RUNTIME
h = guidata(f);
set(f,'Name','RUNNING')

if isempty(AX), AX = TDT_SetupDA; end

for t = fieldnames(h.E)'
    t = char(t); %#ok<FXSET>
    h.E.(t) = TDTpartag(AX,RUNTIME.TRIALS,[h.TDTmodule '.' t])*1000;
    set(h.C.(t),'String',h.E.(t));
end

guidata(f,h);

function EyeTrackTimerRunTime(t,~,f)
global AX RUNTIME
h = guidata(f);

% AX changes class if an error occurred during runtime
if isempty(AX) || ~isa(AX,'COM.TDevAcc_X'), stop(t); return; end

v = TDTpartag(AX,RUNTIME.TRIALS,[h.TDTmodule '.*EyeX_Val'])*1000;
set(h.C.Vals.X,'String',sprintf('% 5.0f mV',v));
if v > h.E.X_LB && v < h.E.X_UB
    set(h.C.Vals.X,'BackgroundColor','g');
else
    set(h.C.Vals.X,'BackgroundColor','r');
end
v = TDTpartag(AX,RUNTIME.TRIALS,[h.TDTmodule '.*EyeY_Val'])*1000;
set(h.C.Vals.Y,'String',sprintf('% 5.0f mV',v));
if v > h.E.Y_LB && v < h.E.Y_UB
    set(h.C.Vals.Y,'BackgroundColor','g');
else
    set(h.C.Vals.Y,'BackgroundColor','r');
end
v = TDTpartag(AX,RUNTIME.TRIALS,[h.TDTmodule '.*EyeP_Val'])*1000;
set(h.C.Vals.P,'String',sprintf('% 5.0f mV',v));
if v > h.E.P_LB
    set(h.C.Vals.P,'BackgroundColor','g');
else
    set(h.C.Vals.P,'BackgroundColor','r');
end


function EyeTrackTimerStop(~,~,f)
set(f,'Name','NOT RUNNING')


function ReadNewBounds(hObj,~,~)
t = get(hObj,'tag');
v = get(hObj,'String');
h = guidata(hObj);
if checkStrIsNum(v), h.E.(t) = str2double(v); else set(hObj,'String',h.E.(t)); end
guidata(hObj,h);

function UpdateVals(f,~,~)
global AX RUNTIME
h = guidata(f);
for t = fieldnames(h.E)';
    t = char(t); %#ok<FXSET>
    vprintf(0,'Updating %s to % 5.1f mV',t,h.E.(t))
    TDTpartag(AX,RUNTIME.TRIALS,[h.TDTmodule '.' t],h.E.(t)/1000);
end



function CloseMe(hObj,~)
% stop(h.T);
T = timerfind('Name','EyeTrackGUITimer');
stop(T)
delete(hObj);


