function NHP_SaveDataFcn(RUNTIME)
% ep_SaveDataFcn(RUNTIME)
% 
% Default function fo saving NHP sound localization data.  Also generates
% and plots psychometric function fit (estPsychFnc).  Results from fit are
% saved as Data.res (Data.res.Fit = [threshold,width,lambda,gamma,eta])
% 
% Daniel.Stolzberg@gmail.com 8/2016




h = msgbox(sprintf('Save Data for ''%s'' in Box ID %d',RUNTIME.TRIALS.Subject.Name,RUNTIME.TRIALS.Subject.BoxID), ...
    'Save Behavioural Data','help','modal');

uiwait(h);

[fn,pn] = uiputfile({'*.mat','MATLAB File'}, ...
    sprintf('Save ''%s (%d)'' Data',RUNTIME.TRIALS.Subject.Name,RUNTIME.TRIALS.Subject.BoxID));

if fn == 0
    fprintf(2,'NOT SAVING DATA FOR SUBJECT ''%s'' IN BOX ID %d\n', ...
        RUNTIME.TRIALS.Subject.Name,RUNTIME.TRIALS.Subject.BoxID);
end

fileloc = fullfile(pn,fn);

Data = RUNTIME.TRIALS.DATA;

try
    Data.res = estPsychFnc(Data);
    save(fileloc,'Data')
catch me
    fprintf(2,'Not saving psychometric fcn fit\n') %#ok<PRTCAL>
    save(fileloc,'Data')
    rethrow(me);
end


















