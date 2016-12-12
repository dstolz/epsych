function test_Visual(x)


figure
xlim([-90 90]);
ylim([-90 90]);
for i = 2:length(x)
    plot([-40 -25 -20 -15 -10 -5 5 10 15 20 25 40],[0 0 0 0 0 0 0 0 0 0 0 0],'bd')
    hold on
    plot(0,0,'gd')
    plot([-2 2],[0 0],'k+')
    
    plot(x(i,5),x(i,6),'k*')
    hold off
    xlim([-50 50]);
    ylim([-90 90]);
    pause(((x(i,4) - x((i-1),4))*0.8))
end
