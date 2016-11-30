function x = organizeData(HT, DATA)
% x = organizeData(HT, DATA)
%
%Takes in HeadTracker(HT) and Data(DATA) variables from a given day and
%parses out the useful information, putting it all into one matrix.
% 
%
%Stephen Gordon 2016

x = zeros(length(HT),8);

for i = 1:length(HT)
    a = HT(i).DATA;
    b = DATA(i).SpeakerID;
    
    switch b
        case 0
            a(2) = -70;
        case 1
            a(2) = -40;
        case 2
            a(2) = -25;
        case 3
            a(2) = -20;
        case 4
            a(2) = -15;
        case 5
            a(2) = -10;
        case 6
            a(2) = -5;
        case 7
            a(2) = 0;
        case 8
            a(2) = 5;
        case 9
            a(2) = 10;
        case 10
            a(2) = 15;
        case 11
            a(2) = 20;
        case 12
            a(2) = 25;
        case 13
            a(2) = 40;
        case 14
            a(2) = 70;
    end
    
    x(i,:) = [i a];
    
end
