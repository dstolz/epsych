function t = TrigRPTrial(RP,trig)
% TrigRPTrial(RP,trig)
% t = TrigRPTrial(RP,trig)
% 
% Use with EPsych experiments
% 
% Returns an approximate timestamp from the PC just after trigger.  Use
% timestamps from TDT hardware for higher accuracy.
% 
% See also, TrigDATrial
% 
% Daniel.Stolzberg@gmail.com

RP.SetTagVal(trig,0); 
t = hat; 
pause(0.001)
RP.SetTagVal(trig,1);