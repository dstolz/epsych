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

DA.SetTargetVal(trig,0); 
t = hat; 
pause(0.001)
DA.SetTargetVal(trig,1);