
Data(1).startFq = 500;
Data(1).duration = 300;
Data(1).depth = 0:0.002:0.034;
Data(1).yesFM = [0 0 0 1 2 0 0 2 2 3 3 3 3 3 3 3 3 3] ./3;

Data(2).startFq = 500;
Data(2).duration = 300;
Data(2).depth = [0:0.002:0.034];
Data(2).yesFM = [0 0 0 0 0 0 0 0 3 2 3 2 1 3 3 3 3 3] ./3;

Data(3).startFq = 1500;
Data(3).duration = 300;
Data(3).depth = 0:0.002:0.034;
Data(3).yesFM = [0 0 0 1 0 2 1 2 3 3 3 3 3 3 3 3 3 3] ./3;

Data(4).startFq = 1500;
Data(4).duration = 300;
Data(4).depth = [0:0.002:0.034];
Data(4).yesFM = [0 0 0 0 1 0 0 1 3 3 3 2 3 3 3 3 3 3] ./3;

colors = [1 0 0; 0.5 0 0;...
          0 0 1; 0 0 0.5];
figure; hold on
for is = 1:numel(Data)
    
    plot(Data(is).depth,Data(is).yesFM,'Color',colors(is,:),'LineWidth',3)
    
 end


 


