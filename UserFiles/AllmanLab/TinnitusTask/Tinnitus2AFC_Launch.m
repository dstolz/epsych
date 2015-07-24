function Tinnitus2AFC_Launch

global RUNTIME

f = findobj('type','figure','-and','name','Tinnitus2AFC_Monitor');
close(f);

for i = 1:RUNTIME.NSubjects
    Tinnitus2AFC_Monitor(RUNTIME.TRIALS(i).Subject.BoxID);
end


