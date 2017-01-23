function [x, y] = organizeData(HT, DATA)
% [x, y] = organizeData(HT, DATA)
%
%Takes in HeadTracker(HT) and Data(DATA) variables from a given day and
%parses out the useful information, putting it all into one raw data matrix
%and one simplified matrix.
% 
%x = [nTrial RespWin Target SecondsFromZero Azi Ele Roll]
%    All FASTRAK values
%y = [nTrial Target finalAvgAzi trialTime Hit]
%    One entry per trial
%
%Stephen Gordon 2016

persistent zeroTime

x = [];
y = zeros(length(HT),5);
for i = 1:length(HT)
    
    if i == 1
        a = HT(i).DATA((end-50):(end-2),:);
        zeroTime = a(1,2)*3600 + a(1,3)*60 + a(1,4);
    else
        a = HT(i).DATA(1:(end-2),:);
    end
    
    realTime = zeros(length(a),1);
    for j = 1:length(a)
        realTime(j) = (a(j,2)*3600 + a(j,3)*60 + a(j,4)) - zeroTime;
        a(j,6) = round((a(j,6)*100))/100;
    end
    
    b = DATA(i).SpeakerID;
    
    switch b
        case 0
            a(:,2) = -35;
        case 1
            a(:,2) = -30;
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
            a(:,2) = 30;
        case 14
            a(:,2) = 35;
    end
    
    c = i*ones(length(a),1);
    a(:,3) = realTime;
    trialTime = a(end,3) - a(1,3);
    if i == 1
        trialTime = 10;
    end
    
    
    
    
    if DATA(i).ResponseCode == 1317
        hit = 1;
    else
        hit = 0;
    end
    
    
    avgAngle = mean2(a((end-20):(end),5));
    y(i,:) = [i a((end-5),2) avgAngle trialTime hit];
    
    a = [c a(:,1:3) a(:,5:10)];
    
    x = [x;a];
    
end
