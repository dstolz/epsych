function testFASTRAK()

try
    if isempty(FASTRAK) || ~isa(FASTRAK,'serial') || isequal(FASTRAK.Status,'closed')
        FASTRAK = startFastrak;
        set(FASTRAK,'BaudRate',115200);
        %fprintf(FASTRAK,'u');
    end
catch me
    if isequal(me.identifier,'MATLAB:serial:get:invalidOBJ')
        FASTRAK = startFastrak;
    else
        rethrow(me);
    end
end

FZero = [0 0 0 0 0 0 0 0 0 0];

loop = 1;
while loop == 1
    pollFastrak2(FASTRAK,FZero);
    
end