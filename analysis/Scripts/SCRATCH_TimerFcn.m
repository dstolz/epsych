%%

tank = 'DILL_MU_Map';
channels = 1;
block = 'Block-46'; % latest block if empty

fcn = @SCRATCH_OnlineFRF;

T = timerfind('Name','ONLINETIMER');
if ~isempty(T), stop(T); delete(T); end
T = timer(                                   ...
    'BusyMode',     'drop',                 ...
    'ExecutionMode','fixedRate',             ...
    'TasksToExecute',inf,                    ...
    'Period',        10,                   ...
    'Name',         'ONLINETIMER',            ...
    'TimerFcn',     {fcn,tank,block,channels},  ...
    'StartDelay',   1,                       ...
    'UserData',     {[]});

%
start(T)

%%
stop(T)

%%
delete(T)
clear T

%%
SCRATCH_OnlineFRF('DILL_MU_Map',block,1)