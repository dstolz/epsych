function  x = compareFixate(curHeading,Headings,Tol)
% x = compareHeading(curHeading,Headings,Tol)
%
% Compare the current heading value to a 1xN vector of target Headings +/-
% a specified tolerance.
%
% Stephen Gordon 2016


Hvec = repmat(Headings,2,1)+[-Tol; Tol];

for x = 1:length(Headings)
    if (curHeading(1) > Hvec(1,x)) && (curHeading(1) < Hvec(2,x)) && (abs(curHeading(2)) < 7)
        return
    end
end

x = nan;