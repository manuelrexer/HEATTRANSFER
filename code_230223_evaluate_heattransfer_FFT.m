% code_230223_evaluate_heattransfer_FFT
% Code that determines the complex Nusselt number in the frequency domain
% from measurement data and  plot it afterwards
%
% created: Rexer 28.02.22
% Version: Disseration v1.0.1
% New Datamodel

%% clear
clc
clearvars -except fig_NuPe
unc = @LinProp
if exist('fig_NuPe')
    if isempty(fig_NuPe.findobj)
        clear fig_NuPe
    end
end
%% Options and Preperation

% number of orders to bee evaluated (first order is neccesary)
neval=4;

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

%% Evaluate measurement data
% DFT of pressure and Volume
for ii=1:length(measureData)
    excitationFrequency(ii) = measureData(ii).model_PARAMETERS.important_parameters_struct.excitation.frequency.value;
    % volume
    volume(ii).FFT = propagateSysUncToFreqDomain...
        (volume(ii).value, time(ii).value, sampletime,...
        'excitation_frequency',excitationFrequency(ii));
    %         for jj=1:volume(ii).FFT.N_data_points_in_FFT
    %             temp1(jj)=unc(real(volume(ii).FFT.value(jj)),real(volume(ii).FFT.uncertainty.complex(jj)));
    %             temp2(jj)=unc(imag(volume(ii).FFT.value(jj)),imag(volume(ii).FFT.uncertainty.complex(jj)));
    %         end
    %         volume(ii).FFT.metas=temp1+1i*temp2;
    % pressure
    pressure(ii).FFT = propagateSysUncToFreqDomain...
        (pressure(ii).value, time(ii).value, sampletime,...
        'excitation_frequency',excitationFrequency(ii));
    %         temp1=unc(real(pressure(ii).FFT.value),diag(real(pressure(ii).FFT.uncertainty.complex)));
    %         temp2=unc(imag(pressure(ii).FFT.value),diag(imag(pressure(ii).FFT.uncertainty.complex)));
    %         pressure(ii).FFT.metas=temp1+1i*temp2;
    % temperature
    temperature(ii).FFT = propagateSysUncToFreqDomain...
        (temperature(ii).value, time(ii).value, sampletime,...
        'excitation_frequency',excitationFrequency(ii));
    temperature_ambient(ii).FFT = propagateSysUncToFreqDomain...
        (temperature_ambient(ii).value, time(ii).value, sampletime,...
        'excitation_frequency',excitationFrequency(ii))
end
clear temp1 temp2


% set Volume signal to zero phase dirfference and turn al other pointers
% equivalent
for ii=1:length(measureData)
    %     EvalData(ii).volume=shiftComplex(EvalData(ii).volume,EvalData(ii).frequency,-0.00);
    [~,closestind(ii)]=min(abs(volume(ii).FFT.frequencies-volume(ii).FFT.excitation_frequency));
    phase0=angle(volume(ii).FFT.value(closestind(ii)));
    volume(ii).FFT.value(2:end)=turnComplex(volume(ii).FFT.value(2:end),-phase0);
    %     EvalData(ii).volume.value(1)=abs(EvalData(ii).volume.value(1));
    %     phase0=angle(EvalData(ii).volume);
    pressure(ii).FFT.value(2:end)=turnComplex(pressure(ii).FFT.value(2:end),-phase0);
    %     EvalData(ii).pressure.value(1)=abs(EvalData(ii).pressure.value(1));
    %     EvalData(ii).pressure_=shiftComplex(EvalData(ii).pressure,EvalData(ii).frequency,0.01);
    temperature(ii).FFT.value(2:end)=turnComplex(temperature(ii).FFT.value(2:end),-phase0);
    %     EvalData(ii).temperature.value(1)=abs(EvalData(ii).temperature.value(1));
    clear phase0
end
clear ii

% Evaluation Method

% Determination of temperature from pressure and Volume Data
[temperature_pv,mass] = getTempFFT(volume,pressure ,temperature_ambient , testSetup);
% Determination of Heatflow from pressure and Volume Data
heatflow = getHeatFFT(volume,pressure,temperature_ambient,testSetup)
% Determination of Nuselt Number from Heatflow and Temperature Data
Nu = getNusseltFFT(heatflow,temperature,temperature_ambient,pressure,testSetup);


% Analysing stiffness
for ii=1:length(measureData)
%     pressures(ii)=pressure(ii).FFT.value(2);
%     volumes(ii)=volume(ii).FFT.value(2);
    %     stiffness(ii) = pressure(ii).FFT.value(find(pressure(ii).FFT.frequencies==pressure(ii).FFT.excitation_frequency))/...
    %         volume(ii).FFT.value(find(volume(ii).FFT.frequencies==volume(ii).FFT.excitation_frequency));
    stiffness(ii) = pressure(ii).FFT.value(closestind(ii))/...
        volume(ii).FFT.value(closestind(ii));
end
clear ii jj


% Cutting out neval harmonics of the signal
for ii=length(Nu):-1:1
    [Nu(ii).res.value,Nu(ii).res.frequencies]=getHarmonic(...
        Nu(ii).FFT.value,Nu(ii).FFT.frequencies,...
        pressure(ii).FFT.excitation_frequency,...
        neval);
end
clear ii jj



% Detrmination of nusselt angle
for ii=length(Nu):-1:1
    % Determination of nusselt Number for each frequency // Sort for
    % plots
    for jj=2:length(Nu(ii).res.value)
        plotNu(jj).res(ii)=Nu(ii).res.value(find(...
            abs(Nu(ii).res.frequencies-pressure(ii).FFT.excitation_frequency*(jj-1))<0.03*pressure(ii).FFT.excitation_frequency));
    end
    % only necessary for validation
    Nu_angel(ii) = angle(heatflow(ii).FFT.value(2))-angle(temperature(ii).FFT.value(2));
    if Nu_angel(ii)<0
        Nu_angel(ii)=Nu_angel(ii)+2*pi;
    end
    % Add Peclet number for comparison
    %     EvalData(ii).Pe=2*pi*EvalData(ii).omega*param.cp.value*EvalData(ii).mass.value/...
    %         (measureData(ii).V1*param.lambda.value*param.s.value^2);
    % Determination of Stiffness
end


% Determine the lopfe of the first order of nusselt number
[slope,offset]=polyfit(log10([excitationFrequency]),log10(abs([plotNu(2).res])),1);
disp("Steigung: " + num2str(slope(1))+ " Offset: "+ num2str(offset.normr))

%% Plots
% Plot Options
input.type = 'loglog';
input.decades_equal = false;
% input.xlimits=[1e-3,1e1];
% input.ylimits=[1e-2,1e4];
% [fig_Nu_pv] = plotFreqResp([EvalData.frequency],[EvalData.Nu_pv],input);
fig_Nu=figure();
% publishfig
for ii=2:length(plotNu)
    fig_Nu = plotFreqResp([excitationFrequency],[plotNu(ii).res],input,fig_Nu);
end
clear ii
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

[fig_Stffness] = plotFreqResp([excitationFrequency],[stiffness]/1000,input);



% figure(1)
% errorbar(volume(1).DFT.FFT.frequencies,abs(volume(1).DFT.FFT.value),volume(1).DFT.FFT.uncertainty.absolute,'.')
% figure(2)
% errorbar(volume(1).DFT.FFT.frequencies,angle(volume(1).DFT.FFT.value),volume(1).DFT.FFT.uncertainty.phase,'.')

%% Temperaturauswertung
% for ii=1:input.nFiles
%     fig_temp{ii} = plotFreqResp([EvalData(ii).frequency_vek],[EvalData(ii).temperature_vek],input);
% end
% for ii=1:input.nFiles
%     fig_temp{ii} = plotFreqResp([EvalData(ii).frequency_vek],[EvalData(ii).pressure_vek],input);
% end
% for ii=1:input.nFiles
%     fig_temp{ii} = plotFreqResp([EvalData(ii).frequency_vek],[EvalData(ii).volume_vek],input);
% end
% fig_temp_vergleich= plotFreqResp([EvalData.frequency],[EvalData.temperature],input);
% fig_temp_vergleich= plotFreqResp([EvalData.frequency],[EvalData.temperature_pv],input,fig_temp_vergleich);
% fig_temp_vergleich= plotFreqResp([EvalData.frequency],[EvalData.t_pv],input,fig_temp_vergleich);

