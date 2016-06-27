function StartSpikeSorting(Action,hGUI,Par)
% Run spike sorting functions. This is for after preprocessing steps.
% Created 22 April 2016 JDY
%---FLAGS---%
if nargin < 3
	pname		=	get(hGUI.edit_pathname,'string');
	subject		=	get(hGUI.SubjectID,'string');
	session		=	get(hGUI.session,'string');
	Par.Pname	=	pname;
	Par.subject	=	subject;
	Par.session	=	session;
end
switch Action
	case 'Init'
		initialize(hGUI,Par);
	case 'Start'
		loaddat(hGUI);
end

%---Locals---%
function initialize(hGUI,Par)
Pname		=	Par.Pname;
subject		=	Par.subject;
session		=	Par.session;
set(hGUI.figure1,'KeyPressFcn',{@querykey,hGUI})
set(hGUI.edit_pathname,'String',Pname)
set(hGUI.SubjectID,'String',subject)
set(hGUI.session,'String',session)

Fname	=	getfname(Pname,subject);

if( ~isempty(Fname) )
	set(hGUI.popup_filename,'String',Fname)
	
	idx		=	get(hGUI.popup_filename,'Value');
	Sname	=	[Pname subject '/' Fname{idx} '.mat'];
	load(Sname)
		
	drawnow	
end

function Name = getfname(Path,subject)
Pname	=	[Path subject '/'];
Fnames	=	dir([Pname '*.mat']);
Ndat	=	length(Fnames);

N		=	cell(Ndat,1);
for k=1:Ndat
	N{k} =	Fnames(k,1).name(1:end-4);
end

Name	=	[];
cnt		=	1;
for k=1:Ndat
	temp	=	N{k};
	idx		=	strfind(temp,'Spikes');
	if( ~isempty(idx) )
		Name{cnt,1}	=	temp;
		cnt	=	cnt + 1;
	end
end

%---Functions---%
function loaddat(hGUI)
channel		=	str2double(get(hGUI.edit_elec,'String'));
Pname		=	get(hGUI.edit_pathname,'String');
Files		=	get(hGUI.popup_filename,'String');
FileIdx		=	get(hGUI.popup_filename,'Value');
File		=	Files(FileIdx);
subject		=	get(hGUI.SubjectID,'String');
session		=	get(hGUI.session,'String');
DataFile	=	[Pname subject '/' File{1} '.mat'];
load(DataFile)

%---MANUAL SORTING---%
[subject, session, channel, Spikes]	=	pp_launch_manual_sort(Pname, subject, session, channel, Spikes );

