function [x, y] = organizeData(HT, DATA)
% [x, y] = organizeData(HT, DATA)
%
%Takes in HeadTracker(HT) and Data(DATA) variables from a given day and
%parses out the useful information, putting it all into one raw data matrix
%and one simplified matrix.
% 
%x = [nTrial RespWin Target Minutes Seconds Azi Ele Roll]
%y = [nTrial Target finalAvgAzi trialTime Hit]
%length(y) = nTrials
%
%Stephen Gordon 2016

x = [];
y = zeros(length(HT),5);
for i = 1:length(HT)
    a = HT(i).DATA;
    
    b = DATA(i).SpeakerID;
    
    switch b
        case 0
            a(:,2) = -70;
        case 1
            a(:,2) = -40;
        case 2
            a(:,2) = -25;
        case 3
            a(:,2) = -20;
        case 4
            a(:,2) = -15;
        case 5
            a(:,2) = -10;
        case 6
            a(:,2) = -5;
        case 7
            a(:,2) = 0;
        case 8
            a(:,2) = 5;
        case 9
            a(:,2) = 10;
        case 10
            a(:,2) = 15;
        case 11
            a(:,2) = 20;
        case 12
            a(:,2) = 25;
        case 13
            a(:,2) = 40;
        case 14
            a(:,2) = 70;
    end
    
    c = i*ones(length(a),1);
    
    if a(end,3) < a(1,3)
        a(end,3) = a(end,3) + 60;
    end
    
    if DATA(i).ResponseCode == 1317
        hit = 1;
    else
        hit = 0;
    end
    
    trialTime = (a(end,3)*60 + a(end,4)) - (a(1,3)*60 + a(1,4));
    if i == 1
        trialTime = 10;
    end
    
    avgAngle = mean2(a((end-11):(end-1),5));
    y(i,:) = [i a(5,2) avgAngle trialTime hit];
    
    a = [c a];
    
    x = [x;a];
    
end
