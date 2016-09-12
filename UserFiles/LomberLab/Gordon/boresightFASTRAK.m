%Boresight the FASTRAK system when the cat fixates.

function boresightFASTRAK(FASTRAK)

%5th column is azimuth and 6th is elevation
x = pollFastrak(FASTRAK);
FASTRAKdata = x;

for i = 1:10
    x = pollFastrak(FASTRAK);
    FASTRAKdata = [FASTRAKdata;x];
end

deviation = std(FASTRAKdata);

if (deviation(5) < 2) && (deviation(6) < 2)
    runBore = False;
else
    runBore = True;
end

while runBore
    x = pollFastrak(FASTRAK);
    FASTRAKdata = [FASTRAKdata;x];
    deviation = std(FASTRAKdata);
    if (deviation(5) < 2) && (deviation(6) < 2)
        runBore = False;
    end
end

fprintf(FASTRAK,'B');

end