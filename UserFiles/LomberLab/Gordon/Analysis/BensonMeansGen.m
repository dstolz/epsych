function meansB = BensonMeansGen(yBenson)

meansB = zeros(1,sum(yBenson(:,1)==1));
index1 = find(yBenson(:,1)==1);
for i = 1:sum(yBenson(:,1)==1)
    a = [];
    if i == sum(yBenson(:,1)==1)
        for j = index1(i):length(yBenson)
            a = [a;yBenson(j,5)];
        end
    else
        for j = index1(i):(index1(i+1)-1)
            a = [a;yBenson(j,5)];
        end
    end
    
    meansB(i) = mean2(a);
end