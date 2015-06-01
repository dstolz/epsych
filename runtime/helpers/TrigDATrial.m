function t = TrigDATrial(DA,trig)
% TrigDATrial(DA,trig)
% t = TrigDATrial(DA,trig)
% 
% Use with EPsych experiments
% 
% Returns an approximate timestamp from the PC just after trigger.  Use
% timestamps from TDT hardware for higher accuracy.
% 
% See also, TrigRPTrial
% 
% Daniel.Stolzberg@gmail.com


e = DA.SetTargetVal(trig,1);
% t = hat;
t = clock; %DJS 6/2015
if ~e, throwerrormsg(trig); end
pause(0.001)
e = DA.SetTargetVal(trig,0); 
if ~e, throwerrormsg(trig); end

function throwerrormsg(trig)
beep
errordlg(sprintf('UNABLE TO TRIGGER "%s"',trig),'RP TRIGGER ERROR','modal')
error('UNABLE TO TRIGGER "%s"',trig)
