
% code_230223_evaluate_heattransfer_FFT
% Code that determines the complex Nusselt number in the frequency domain
% from measurement data and  plot it afterwards
%
% created: Rexer 28.02.22
% Version: Disseration v1.0.1
% New Datamodel

%% clear
clc
clearvars -except fig_Nu fig_NuPe fig_stiffness
unc = @LinProp;

%% Options and Preperation

% number of orders to bee evaluated (first order is neccesary)
neval=1;

%% Reading the measurement data
measureData = getMeasureData();
% reading parameter
testSetup=getTestrigParameter(measureData);

%% Select data for analyzation

% defelction Data
if isfield(measureData, 'current_deflection')
    fieldname.deflection={'current_deflection'};
else
    fieldname.deflection=getSelectedFields(measureData,'Select defelction field');
end
deflection=extractMeasurements(measureData,fieldname.deflection{1});
% pressure Data
if isfield(measureData, 'pressure_gas')
    fieldname.pressure={'pressure_gas'};
else
    fieldname.pressure=getSelectedFields(measureData, 'select pressure:');
end
pressure=extractMeasurements(measureData,fieldname.pressure{1});
% temperature Data
if isfield(measureData, 'temperature_gas')
    fieldname.temperature={'temperature_gas'};
else
    fieldname.temperature=getSelectedFields(measureData, 'select temperature');
end
temperature=extractMeasurements(measureData,fieldname.temperature{1});
% ambient temperature Data
if isfield(measureData, 'temperature_ambient')
    fieldname.temperature_ambient={'temperature_ambient'};
else
    fieldname.temperature_ambient=getSelectedFields(measureData, 'select ambient temperature ');
end
temperature_ambient=extractMeasurements(measureData,fieldname.temperature_ambient{1});
% time vector
if isfield(measureData, 'measurement_TIME_VECTOR')
    fieldname.time={'measurement_TIME_VECTOR'};
else
    fieldname.time=getSelectedFields(measureData, 'select time');
end
for ii=length(measureData):-1:1
    time(ii).value=measureData(ii).(fieldname.time{1}).value;
    time(ii).name='time';
    time(ii).variable='t';
end

sampletime = measureData(1).model_PARAMETERS.all_parameters_array(1).value;
% Add volume in m³
[volume,testSetup]=addVolumeData(deflection,pressure,testSetup);

%% Evaluate measurement data
% DFT of pressure and Volume
for ii=length(measureData):-1:1
    excitationFrequency(ii) = measureData(ii).model_PARAMETERS.important_parameters_struct.excitation.frequency.value;
    % volume
    volume(ii).FFT = propagateSysUncToFreqDomain...
        (volume(ii).value, time(ii).value, sampletime,...
        'excitation_frequency',excitationFrequency(ii));
    % pressure
    pressure(ii).FFT = propagateSysUncToFreqDomain...
        (pressure(ii).value, time(ii).value, sampletime,...
        'excitation_frequency',excitationFrequency(ii));
    % temperature
    temperature(ii).FFT = propagateSysUncToFreqDomain...
        ((temperature(ii).value+273.15), time(ii).value, sampletime,...
        'excitation_frequency',excitationFrequency(ii));
    % ambient temperature
    temperature_ambient(ii).FFT = propagateSysUncToFreqDomain...
        ((temperature_ambient(ii).value+273.15), time(ii).value, sampletime,...
        'excitation_frequency',excitationFrequency(ii));
end



% set Volume signal to zero phase dirfference and turn al other pointers
% equivalent
for ii=length(measureData):-1:1
    [~,closestind(ii)]=min(abs(volume(ii).FFT.frequencies-volume(ii).FFT.excitation_frequency));

    phase0=angle(volume(ii).FFT.value(closestind(ii)));
    volume(ii).FFT.value(2:end)=turnComplex(volume(ii).FFT.value(2:end),-phase0);
    pressure(ii).FFT.value(2:end)=turnComplex(pressure(ii).FFT.value(2:end),-phase0);
    temperature(ii).FFT.value(2:end)=turnComplex(temperature(ii).FFT.value(2:end),-phase0);
    temperature_ambient(ii).FFT.value(2:end)=turnComplex(temperature_ambient(ii).FFT.value(2:end),-phase0);

    clear phase0
end
clear ii

% Evaluation Method
for ii=length(testSetup):-1:1
testSetup(ii).fluid_ID='https://w3id.org/fst/resource/018dba9b-f067-7d3e-8a4d-d60cebd70a8a'
end


% Determination of temperature from pressure and Volume Data
[temperature_pv,mass] = getTempFFT(volume,pressure ,temperature_ambient , testSetup);
% Determination of Heatflow from pressure and Volume Data
heatflow = getHeatFFT(volume,pressure,temperature_ambient,testSetup);
% Determination of Nuselt Number from Heatflow and Temperature Data

for ii=1:length(temperature_pv)
    temperature_pv(ii).FFT.value(1)=temperature(ii).FFT.value(1);
end


Nu = getNusseltFFT(heatflow,temperature,temperature_ambient,pressure,testSetup);
Nu_pv = getNusseltFFT(heatflow,temperature_pv,temperature_ambient,pressure,testSetup);

% Analysing stiffness
for ii=length(pressure):-1:1
    stiffness(ii) = pressure(ii).FFT.value(closestind(ii))/...
        volume(ii).FFT.value(closestind(ii));
end
clear ii


% Cutting out neval harmonics of the signal
for ii=length(Nu):-1:1
    [Nu(ii).res.value,Nu(ii).res.frequencies]=getHarmonic(...
        Nu(ii).FFT.value,Nu(ii).FFT.frequencies,...
        Nu(ii).FFT.frequencies(closestind(ii)),...
        neval);
    [Nu_pv(ii).res.value,Nu_pv(ii).res.frequencies]=getHarmonic(...
        Nu_pv(ii).FFT.value,Nu_pv(ii).FFT.frequencies,...
        Nu_pv(ii).FFT.frequencies(closestind(ii)),...
        neval);
end
clear ii



% Detrmination of nusselt angle
for ii=length(Nu):-1:1
    % Determination of nusselt Number for each frequency // Sort for
    % plots
    for jj=1:length(Nu(ii).res.value)
        plotNu(jj).res(ii)=Nu(ii).res.value(find(...
            abs(Nu(ii).res.frequencies-pressure(ii).FFT.excitation_frequency*(jj-1))<0.03*pressure(ii).FFT.excitation_frequency));
        plotNu_pv(jj).res(ii)=Nu_pv(ii).res.value(find(...
            abs(Nu_pv(ii).res.frequencies-pressure(ii).FFT.excitation_frequency*(jj-1))<0.03*pressure(ii).FFT.excitation_frequency));
    end
    % only necessary for validation
    Nu_angel(ii) = angle(heatflow(ii).FFT.value(2))-angle(temperature(ii).FFT.value(2));
    if Nu_angel(ii)<0
        Nu_angel(ii)=Nu_angel(ii)+2*pi;
    end
    % Add Peclet number for comparison
        Pe(ii)=2*pi*excitationFrequency(ii)*mass(ii).value*...
            getFluidProperty(testSetup(ii).fluid_ID,...
        mean(pressure(ii).value)*1e5,mean(temperature_ambient(ii).value)+273.15,'c_p')/...
            (testSetup(ii).V1.value* ...
            getFluidProperty(testSetup(ii).fluid_ID,...
        mean(pressure(ii).value)*1e5,mean(temperature_ambient(ii).value)+273.15,'thermal_conductivity')* ...
            (testSetup(ii).Aw.value/testSetup(ii).V1.value)^2);
end


% Determine the lopfe of the first order of nusselt number
[slope,offset]=polyfit(log10(excitationFrequency),log10(abs([plotNu(2).res])),1);
disp("Steigung: " + num2str(slope(1))+ " Offset: "+ num2str(offset.normr))

%% Plots
% Plot Options
% input.type = 'loglog';
% input.decades_equal = false;
% input.xlimits=[1e-3,1e1];
% input.ylimits=[1e-2,1e4];
% [fig_Nu_pv] = plotFreqResp([EvalData.frequency],[EvalData.Nu_pv],input);

if exist ('fig_Nu', 'var')
    if isempty(fig_Nu.findobj)
        fig_Nu=figure();
    end
else
fig_Nu=figure();
end
% publishfig
for ii=2:length(plotNu)
    fig_Nu = plotFreqResp(excitationFrequency,plotNu(ii).res,fig_Nu,'plottype','loglog','ylabel','Nusselt','phase',true);
     fig_Nu = plotFreqResp(excitationFrequency,plotNu_pv(ii).res,fig_Nu,'plottype','loglog','ylabel','Nusselt','phase',true);
end
if exist('fig_NuPe', 'var')
    if isempty(fig_NuPe.findobj)
        fig_NuPe=figure();
    end
else
fig_NuPe=figure();
end
% publishfig
for ii=2:length(plotNu)
%     fig_NuPe = plotFreqResp(Pe,plotNu(ii).res,fig_NuPe,'plottype','loglog','ylabel','Nusselt','xlabel','Pe','phase',true);
     fig_NuPe = plotFreqResp(Pe,plotNu_pv(ii).res,fig_NuPe,'plottype','loglog','ylabel','Nusselt','xlabel','Pe','phase',true);
end


%
% if ~exist("fig_NuPe")
%     fig_NuPe=figure();
%     publishfig
% end
% for ii=2 %:length(Nu)
%     fig_NuPe = plotFreqResp([EvalData.Pe],[Nu(ii).res],input,fig_NuPe);
% end
% clear ii
%
%
% load MeanOscillatingPecletNumber4mm120bar40bar0_7L.mat
% Pe120bar4mm = k;
% load NusseltFit4mm120bar40bar0_7L.mat
% Nu120bar4mm = resultsFitKornhauser;
% % [fig_Nu] = plotFreqResp([EvalData.frequency],[Nu],input);
% % [fig_Nu] = plotFreqResp([EvalData.frequency],[Nu2],input,fig_Nu);
% [fig_Nu] = plotFreqResp([Nu120bar4mm.freq],[Nu120bar4mm.complexNu],input,fig_Nu);
% %  [fig_NuPe] = plotFreqResp([Pe120bar4mm],[Nu120bar4mm.complexNu],input,fig_NuPe);
% % [fig_Nu] = plotFreqResp([EvalData.frequency],[Nu2+Nu],input,fig_Nu);


% figure(1)
% errorbar(volume(1).DFT.FFT.frequencies,abs(volume(1).DFT.FFT.value),volume(1).DFT.FFT.uncertainty.absolute,'.')
% figure(2)
% errorbar(volume(1).DFT.FFT.frequencies,angle(volume(1).DFT.FFT.value),volume(1).DFT.FFT.uncertainty.phase,'.')

%% Temperaturauswertung
% for ii=1:input.nFiles
%     fig_temp{ii} = plotFreqResp([temperature(ii).FFT.frequencies(1:10)],[temperature(ii).FFT.value(1:10)],input);
% fig_temp{ii} = plotFreqResp([temperature_pv(ii).FFT.frequencies(1:10)],[temperature_pv(ii).FFT.value(1:10)],input,fig_temp{ii});
% figure()
% stem([temperature(ii).FFT.frequencies(1:10)],[abs(temperature(ii).FFT.value(1:10))]);
% hold on
% stem([temperature_pv(ii).FFT.frequencies(1:10)],[abs(temperature_pv(ii).FFT.value(1:10))]);
    % end
% for ii=1:input.nFiles
%     fig_temp{ii} = plotFreqResp([EvalData(ii).frequency_vek],[EvalData(ii).pressure_vek],input);
% end
% for ii=1:input.nFiles
%     fig_temp{ii} = plotFreqResp([EvalData(ii).frequency_vek],[EvalData(ii).volume_vek],input);
% end

try
    fig_stiffness = plotFreqResp(excitationFrequency,stiffness,fig_stiffness,'plottype','absolute','ylabel','STEIFIGKEIT in bar/l');
catch
    fig_stiffness=figure();
    fig_stiffness = plotFreqResp(excitationFrequency,stiffness,fig_stiffness,'plottype','absolute');
end



% getFluidProperty('https://w3id.org/fst/resource/018dba9b-f067-7d3e-8a4d-d60cebd70a8a',1e5,293,'c_v')
% getFluidProperty('https://w3id.org/fst/resource/018dba9b-f067-7d3e-8a4d-d60cebd70a8a',1e5,293,'c_p')
% getFluidProperty('https://w3id.org/fst/resource/018dba9b-f067-7d3e-8a4d-d60cebd70a8a',1e5,293,'thermal_conductivity')
% getFluidProperty('https://w3id.org/fst/resource/018dba9b-f067-7d3e-8a4d-d60cebd70a8a',1e5,293,'specific_gas_constant')
% getFluidProperty('https://w3id.org/fst/resource/018dba9b-f067-7d3e-8a4d-d60cebd70a8a',1e5,293,'isentropic_exponent')
