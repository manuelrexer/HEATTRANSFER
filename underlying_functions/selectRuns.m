function selectedruns = selectRuns(runs)
%selectRuns select run to evaluate form all runs using list prompt

message='Select runs';
[indx,~] = listdlg('PromptString',message,'ListString',{runs(:).name});

selectedruns.runs= indx;
selectedruns.inds=[];
for ii=1:length(indx)
    selectedruns.inds= [selectedruns.inds,runs(ii).ind];
end
end