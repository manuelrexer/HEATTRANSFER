function runs = getMeasurementRuns(measureData)
for ii=1:length(measureData)
    lists.ind(ii)=ii;
    lists.amps(ii)=measureData(ii).model_PARAMETERS.important_parameters_struct.excitation.amplitude.value;
    lists.freqs(ii)=measureData(ii).model_PARAMETERS.important_parameters_struct.excitation.frequency.value;
    lists.temperatures(ii)=10*round(measureData(ii).model_PARAMETERS.important_parameters_struct.ambient_temperature.value/10);
end

amps=unique(lists.amps);
temperatures=unique(lists.temperatures);
nruns=fullfact([length(amps),length(temperatures)]);

for ii=1:size(nruns,1)
    runs(ii).amplitude=amps(nruns(ii,1));
    runs(ii).temperature=temperatures(nruns(ii,2));
    runs(ii).ind=lists.ind(find(lists.amps==runs(ii).amplitude & lists.temperatures==runs(ii).temperature));
    [x,idx]=sort([lists.freqs(runs(ii).ind)]);
    runs(ii).ind=runs(ii).ind(idx);
    runs(ii).name=['Temperatur: ',num2str(runs(ii).temperature),'°C, Amplitude: ',num2str(runs(ii).amplitude),'mm'];
end


end