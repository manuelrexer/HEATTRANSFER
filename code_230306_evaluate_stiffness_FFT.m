%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% code_230223_evaluate_heattransfer_FFT
% Code that determines the complex Nusselt number in the frequency domain
% from measurement data and  plot it afterwards
%
% created: Rexer 28.02.22
% Version: Disseration v1.0.1
% New Datamodel

%% clear
clc
clearvars -except fig_stiffness fig_stiffness_dimless

if exist('fig_stiffness')
    if isempty(fig_stiffness.findobj)
        clear fig_stiffness
    end
end
if exist('fig_stiffness_dimless')
    if isempty(fig_stiffness_dimless.findobj)
        clear fig_stiffness_dimless
    end
end
%% Options and Preperation
unc = @LinProp;


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
for ii=1:length(measureData)
    time(ii).value=measureData(ii).(fieldname.time{1}).value;
    time(ii).name='time';
    time(ii).variable='t';
end

sampletime = measureData(1).model_PARAMETERS.all_parameters_array(1).value;
% Add volume in m³
[volume,testSetup]=addVolumeData(deflection,pressure,testSetup);


%% Analysing load carrying area

figure();plot((measureData(ii).force.value)*1e3./((measureData(ii).gas_pressure_sensor_D130.value-1)*1e5));

%% Evaluate measurement data
% DFT of pressure and Volume
for ii=1:length(measureData)
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
for ii=1:length(measureData)
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
for ii=1:length(testSetup)
testSetup(ii).fluid_ID='https://w3id.org/fst/resource/018dba9b-f067-7d3e-8a4d-d60cebd70a8a';
end

% Analysing stiffness
for ii=1:length(measureData)
    stiffness(ii) = pressure(ii).FFT.value(closestind(ii))/ volume(ii).FFT.value(closestind(ii))/1000;
    stiffness_dimless(ii)=stiffness(ii)./mean(pressure(ii).value)*testSetup(ii).V1.value;
end
clear ii


%% Plots
% Plot Options


try
    fig_stiffness = plotFreqResp(excitationFrequency,stiffness,fig_stiffness,'plottype','absolute','ylabel','STEIFIGKEIT in bar/l');
catch
    fig_stiffness=figure()
    fig_stiffness = plotFreqResp(excitationFrequency,stiffness,fig_stiffness,'plottype','absolute');
end
publishfig
try
    fig_stiffness_dimless = plotFreqResp(excitationFrequency,stiffness_dimless,fig_stiffness_dimless,'plottype','absolute','ylabel','STEIFIGKEIT');
catch
    fig_stiffness_dimless=figure();
    fig_stiffness_dimless = plotFreqResp(excitationFrequency,stiffness_dimless,fig_stiffness_dimless,'plottype','absolute');
end
publishfig
% figure(1)
% errorbar(volume(1).DFT.FFT.frequencies,abs(volume(1).DFT.FFT.value),volume(1).DFT.FFT.uncertainty.absolute,'.')
% figure(2)
% errorbar(volume(1).DFT.FFT.frequencies,angle(volume(1).DFT.FFT.value),volume(1).DFT.FFT.uncertainty.phase,'.')


% getFluidProperty('https://w3id.org/fst/resource/018dba9b-f067-7d3e-8a4d-d60cebd70a8a',1e5,293,'c_v')
% getFluidProperty('https://w3id.org/fst/resource/018dba9b-f067-7d3e-8a4d-d60cebd70a8a',1e5,293,'c_p')
% getFluidProperty('https://w3id.org/fst/resource/018dba9b-f067-7d3e-8a4d-d60cebd70a8a',1e5,293,'thermal_conductivity')
% getFluidProperty('https://w3id.org/fst/resource/018dba9b-f067-7d3e-8a4d-d60cebd70a8a',1e5,293,'specific_gas_constant')
% getFluidProperty('https://w3id.org/fst/resource/018dba9b-f067-7d3e-8a4d-d60cebd70a8a',40e5,293,'isentropic_exponent')