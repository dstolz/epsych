
seconds = 1:1200;

MLperMin_Steady = 0.3;
consumed_Steady = MLperMin_Steady/60*seconds;

flowRate_Pulse = 0.29;
timeOn  = 400;  timeOff = 0;
propSecON = timeOn / (timeOn+timeOff);
MLperMin_Pulse = propSecON*flowRate_Pulse;
consumed_Pulse = MLperMin_Pulse/60*seconds;

figure;
plot(seconds,consumed_Steady,'k', 'LineWidth',2)
hold on
plot(seconds,consumed_Pulse, 'r', 'LineWidth',2)
xlabel('Time in passive experiment')
ylabel('ML water consumed')

[~,icS] = min(abs(consumed_Steady-3));
[~,icP] = min(abs(consumed_Pulse-3));


text(150,5,  sprintf('Steady: %i secs to 3 ml',icS))
text(150,4.5,sprintf('Pulsed: %i secs to 3 ml',icP))


