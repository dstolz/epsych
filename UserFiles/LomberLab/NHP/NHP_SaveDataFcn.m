function NHP_SaveDataFcn(RUNTIME)
% ep_SaveDataFcn(RUNTIME)
% 
% Default function fo saving NHP sound localization data.  Also generates
% and plots psychometric function fit (estPsychFnc).  Results from fit are
% saved as Data.res (Data.res.Fit = [threshold,width,lambda,gamma,eta])
% 
% Daniel.Stolzberg@gmail.com 8/2016


global S_LED
if isa(S_LED,'serial') && isequal(S_LED.Status,'open')
    vprintf(2,'Closing LED Arduino connection')
    fclose(S_LED); 
    S_LED = []; 
end

h = msgbox(sprintf('Save Data for ''%s'' in Box ID %d',RUNTIME.TRIALS.Subject.Name,RUNTIME.TRIALS.Subject.BoxID), ...
    'Save Behavioural Data','help','modal');

uiwait(h);

[fn,pn] = uiputfile({'*.mat','MATLAB File'}, ...
    sprintf('Save ''%s (%d)'' Data',RUNTIME.TRIALS.Subject.Name,RUNTIME.TRIALS.Subject.BoxID), ...
    fullfile('C:\Users\LomberMonkey\ownCloud\DATA\GRUBER\Behavioural\Training', ...
        sprintf('%s_%s.mat',RUNTIME.TRIALS.Subject.Name,datestr(clock,'yyyymmdd'))));

if fn == 0
    vprintf(0,1,'NOT SAVING DATA FOR SUBJECT ''%s'' IN BOX ID %d\n', ...
        RUNTIME.TRIALS.Subject.Name,RUNTIME.TRIALS.Subject.BoxID);
    return
end

fileloc = fullfile(pn,fn);

Data = RUNTIME.TRIALS.DATA;

try
    a = inputdlg('Enter first trial for psychfcn estimate:','PsychFit',1,{'1'});
    a = str2double(a);
    if isempty(a), a = 1; end
    Res = estPsychFnc(Data(a:end)); %#ok<NASGU>
%     save(fileloc,'Data','Res')
catch me
%     fprintf(2,'Not saving psychometric fcn fit\n') %#ok<PRTCAL>
    vprintf(-1,me);
end


save(fileloc,'Data')
















