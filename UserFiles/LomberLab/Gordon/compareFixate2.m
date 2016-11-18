function  x = compareFixate2(curHeading)
% x = compareHeading(curHeading,Headings,Tol)
%
% Compare the current heading value to a 1xN vector of target Headings +/-
% a specified tolerance.
%
% Stephen Gordon 2016


if abs(curHeading(1)) < 3 && abs(curHeading(2)) < 5
    x = 8;
    return
else
    x = 0;
    return
end

x = nan;