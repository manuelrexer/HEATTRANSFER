function selectedruns = selectRuns(runs)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
message='Select runs';
[indx,~] = listdlg('PromptString',message,'ListString',{runs(:).name});

selectedruns.runs= indx;
selectedruns.inds=[];
for ii=1:length(indx)
    selectedruns.inds= [selectedruns.inds,runs(ii).ind];
end
end